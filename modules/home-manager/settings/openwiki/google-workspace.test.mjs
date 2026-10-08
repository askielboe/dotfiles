import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { GoogleReadClient, toolsFor, callTool, paginate, collectSource } from './google-workspace.mjs';
import { mergeSources } from './register-sources.mjs';

const jsonResponse = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { 'Content-Type': 'application/json' } });
const temporary = async run => {
  const directory = await mkdtemp(join(tmpdir(), 'openwiki-google-test-'));
  try { return await run(directory); } finally { await rm(directory, { recursive: true, force: true }); }
};

test('the bridge rejects write, cross-service, and arbitrary arguments before contacting Google', async () => {
  for (const service of ['drive', 'chat']) {
    assert.ok(toolsFor(service).every(tool => tool.annotations.readOnlyHint && !tool.annotations.destructiveHint));
    for (const name of ['send_message', 'create_file', 'delete_file', 'label_message', 'chat_list_messages', 'drive_read_file'].filter(name => !toolsFor(service).some(tool => tool.name === name))) {
      await assert.rejects(callTool(service, name, {}, {}), /explicitly allowed/);
    }
  }
  await assert.rejects(callTool('drive', 'drive_list_files', { url: 'https://attacker.example' }, {}), /Invalid argument/);
  await assert.rejects(callTool('chat', 'chat_list_messages', {}, {}), /Missing argument/);
});

test('API access uses GET only, rejects path traversal, and refreshes a 401 once', async () => {
  const requests = [];
  let refreshed = 0;
  const client = new GoogleReadClient({ accessToken: async () => 'test-token', refreshToken: async () => { refreshed++; },
    fetchImpl: async (url, options) => { requests.push({ url: String(url), options }); return jsonResponse(requests.length === 1 ? {} : { files: [] }, requests.length === 1 ? 401 : 200); } });
  await client.listFiles();
  assert.equal(refreshed, 1);
  assert.ok(requests.every(request => request.options.method === 'GET' && request.options.redirect === 'error'));
  assert.ok(requests[0].url.includes('trashed%3Dfalse'));
  await assert.rejects(client.get('drive', '../files'), /Invalid/);
  assert.throws(() => client.listMessages('spaces/a/messages/b'), /Invalid/);
  assert.throws(() => client.fileMetadata('x?alt=media'), /Invalid/);
});

test('pagination continues through empty pages and records exhaustion', async () => {
  const state = { pagination: {} };
  const cursors = [];
  const items = [];
  await paginate(state, 'messages', async cursor => { cursors.push(cursor); return cursor ? { messages: [{ id: 1 }] } : { messages: [], nextPageToken: 'second' }; },
    async page => items.push(...page.messages), async () => {});
  assert.deepEqual(cursors, ['', 'second']);
  assert.equal(items.length, 1);
  assert.equal(state.pagination.messages.done, true);
  assert.equal(state.pagination.messages.pages, 2);
});

test('incomplete search and repeated cursors cannot be reported as exhaustive', async () => {
  const state = { pagination: {} };
  await assert.rejects(paginate(state, 'files', async () => ({ incompleteSearch: true }), async () => {}, async () => {}), /incompleteSearch/);
  assert.equal(state.pagination.files.done, false);
  assert.match(state.pagination.files.error, /incompleteSearch/);
  await assert.rejects(paginate({ pagination: {} }, 'files', async () => ({ nextPageToken: 'repeat' }), async () => {}, async () => {}), /Repeated/);
});

test('Drive collection deduplicates shared-drive files, follows shortcuts, and records unsupported formats', async () => temporary(async directory => {
  const a = { id: 'a', name: 'text', mimeType: 'text/plain' };
  const shortcut = { id: 'shortcut', mimeType: 'application/vnd.google-apps.shortcut', shortcutDetails: { targetId: 'target' } };
  const client = {
    listFiles: async args => ({ files: args.driveId ? [a, { id: 'binary', mimeType: 'video/mp4' }] : [a, shortcut] }),
    listDrives: async () => ({ drives: [{ id: 'shared' }] }),
    fileMetadata: async id => ({ id, mimeType: 'text/plain' }),
    fileContent: async file => file.id === 'binary' ? { status: 'unsupported', reason: 'video/mp4' }
      : file.id === 'shortcut' ? { status: 'metadata', reason: 'Shortcut' } : { status: 'collected', text: file.id },
  };
  const result = await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  assert.equal(result.complete, true);
  assert.equal(result.discovered, 4);
  assert.deepEqual(result.counts, { collected: 2, metadata: 1, unsupported: 1 });
  assert.ok(result.pagination['drive:shared'].done);
  assert.equal(JSON.parse(await readFile(join(directory, 'documents/a.json'), 'utf8')).text, 'a');
}));

test('failed file content resumes without repeating exhausted enumeration', async () => temporary(async directory => {
  let enumerations = 0;
  let failing = true;
  const client = { listFiles: async () => { enumerations++; return { files: [{ id: 'a' }] }; }, listDrives: async () => ({ drives: [] }),
    fileContent: async () => { if (failing) throw new Error('temporary failure'); return { status: 'collected', text: 'recovered' }; } };
  await assert.rejects(collectSource(client, 'drive', 'test@example.com', directory, () => {}), /unresolved failures/);
  const initial = JSON.parse(await readFile(join(directory, 'manifest.json'), 'utf8'));
  assert.equal(initial.items.a.status, 'failed');
  assert.equal(initial.complete, false);
  failing = false;
  assert.equal((await collectSource(client, 'drive', 'test@example.com', directory, () => {})).complete, true);
  assert.equal(enumerations, 1);
}));

test('Chat includes thread replies, deduplicates, and resolves sender names across messages', async () => temporary(async directory => {
  const unnamed = { name: 'spaces/a/messages/root', sender: { name: 'users/alice' }, thread: { name: 'spaces/a/threads/t' } };
  const reply = { name: 'spaces/a/messages/reply', sender: { name: 'users/alice', displayName: 'Alice', email: 'alice@example.com' }, thread: unnamed.thread, threadReply: true };
  const client = { listSpaces: async () => ({ spaces: [{ name: 'spaces/a', spaceUri: 'https://chat.google.com/room/a' }] }),
    listMessages: async (space, args) => args.pageToken ? { messages: [unnamed, reply] } : { messages: [unnamed], nextPageToken: 'next' } };
  const result = await collectSource(client, 'chat', 'test@example.com', directory, () => {});
  assert.equal(result.discovered, 2);
  assert.equal(result.authors.unresolvedMessages, 0);
  assert.equal(result.authors.people['users/alice'].displayName, 'Alice');
  const root = JSON.parse(await readFile(join(directory, 'documents/spaces_a_messages_root.json'), 'utf8'));
  const response = JSON.parse(await readFile(join(directory, 'documents/spaces_a_messages_reply.json'), 'utf8'));
  assert.equal(root.author.displayName, 'Alice');
  assert.equal(response.message.threadReply, true);
  assert.equal(result.pagination['messages:spaces/a'].pages, 2);
}));

test('Chat preserves unknown sender IDs without invented names', async () => temporary(async directory => {
  const client = { listSpaces: async () => ({ spaces: [{ name: 'spaces/a' }] }),
    listMessages: async () => ({ messages: [{ name: 'spaces/a/messages/x', sender: { name: 'users/unknown' } }] }) };
  const result = await collectSource(client, 'chat', 'test@example.com', directory, () => {});
  assert.equal(result.authors.unresolvedMessages, 1);
  assert.deepEqual(result.authors.unresolvedIds, ['users/unknown']);
}));

test('source registration preserves other accounts, goals, and schedules', () => {
  const before = { version: 1, ingestionSchedule: { pausedAt: 'date' }, sourceInstances: [
    { id: 'bear-business', connectorConfig: { untouched: true } },
    { id: 'drive-other', schedule: { pausedAt: 'other-date' } },
    { id: 'drive-mo2tion', schedule: { pausedAt: 'keep' }, connectedAt: 'old' },
  ] };
  const after = mergeSources(before, [{ id: 'drive-mo2tion', connectorConfig: { replaced: true } }, { id: 'chat-mo2tion' }]);
  assert.deepEqual(after.sourceInstances.slice(0, 2), before.sourceInstances.slice(0, 2));
  assert.deepEqual(after.ingestionSchedule, before.ingestionSchedule);
  assert.equal(after.sourceInstances[2].schedule.pausedAt, 'keep');
  assert.equal(after.sourceInstances.length, 4);
  assert.equal(mergeSources(after, [{ id: 'chat-mo2tion' }]).sourceInstances.length, 4);
});

test('shared folder descendants are traversed even when absent from the user corpus', async () => temporary(async directory => {
  const folder = id => ({ id, mimeType: 'application/vnd.google-apps.folder' });
  const client = {
    listFiles: async args => ({ files: !args.q ? [folder('parent')] : args.q.includes("'parent'") ? [folder('child')] : [{ id: 'hidden', mimeType: 'text/plain' }] }),
    listDrives: async () => ({ drives: [] }),
    fileContent: async file => file.mimeType.endsWith('folder') ? { status: 'metadata', reason: 'Folder' } : { status: 'collected', text: 'Full content' },
  };
  const result = await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  assert.equal(result.complete, true);
  assert.equal(result.discovered, 3);
  assert.ok(result.pagination['folder:parent'].done);
  assert.ok(result.pagination['folder:child'].done);
}));

test('MCP synthesis refuses an incomplete collection manifest', async () => {
  await assert.rejects(callTool('chat', 'collection_status', {}, { status: async () => ({ complete: false }) }), /must finish/);
});
