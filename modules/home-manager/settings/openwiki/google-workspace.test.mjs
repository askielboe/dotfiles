import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { GoogleReadClient, toolsFor, callTool, paginate, collectSource, publishCollection, atomicJson, SCOPES } from './google-workspace.mjs';
import { mergeSources } from './register-sources.mjs';

const jsonResponse = (data, status = 200) => new Response(JSON.stringify(data), { status, headers: { 'Content-Type': 'application/json' } });
const temporary = async run => {
  const directory = await mkdtemp(join(tmpdir(), 'openwiki-google-test-'));
  try { return await run(directory); } finally { await rm(directory, { recursive: true, force: true }); }
};

test('oversized exclusion is opt-in and does not suppress permission failures', async () => {
  let requests = 0;
  const options = { accessToken: async () => 'test', refreshToken: async () => {}, fetchImpl: async () => {
    requests++;
    return jsonResponse({ error: { message: 'This file is too large to be exported.' } }, 403);
  } };
  const client = new GoogleReadClient({ ...options, ignoreTooLarge: true });
  const large = await client.fileContent({ id: 'large', mimeType: 'text/plain', size: '368504441' });
  assert.equal(large.ignoredTooLarge, true);
  assert.equal(requests, 0);
  const sheet = { id: 'sheet', mimeType: 'application/vnd.google-apps.spreadsheet' };
  assert.equal((await client.fileContent(sheet)).ignoredTooLarge, true);
  await assert.rejects(new GoogleReadClient(options).fileContent(sheet), /too large/);
  const denied = new GoogleReadClient({ ...options, ignoreTooLarge: true, fetchImpl: async () => jsonResponse({ error: { message: 'Permission denied' } }, 403) });
  await assert.rejects(denied.fileContent(sheet), /Permission denied/);
});

test('bounded download rejects a declared oversized response and preserves normal text', async () => {
  const options = { accessToken: async () => 'test', refreshToken: async () => {}, ignoreTooLarge: true };
  const large = new GoogleReadClient({ ...options, fetchImpl: async () => new Response('small', { headers: { 'content-length': '70000000' } }) });
  assert.equal((await large.fileContent({ id: 'large', mimeType: 'text/plain' })).ignoredTooLarge, true);
  const normal = new GoogleReadClient({ ...options, fetchImpl: async () => new Response('hello') });
  assert.equal((await normal.fileContent({ id: 'normal', mimeType: 'text/plain' })).text, 'hello');
});

test('collection logs oversized names and links and reports missing shortcut targets', async () => temporary(async directory => {
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {}, ignoreTooLarge: true });
  client.listFiles = async () => ({ files: [
    { id: 'large', name: 'Large SQL', mimeType: 'text/x-sql', size: '368504441', webViewLink: 'https://drive.google.com/file/d/large/view' },
    { id: 'shortcut', name: 'Shortcut', mimeType: 'application/vnd.google-apps.shortcut', shortcutDetails: { targetId: 'missing' } },
  ] });
  client.listDrives = async () => ({ drives: [] });
  client.fileMetadata = async () => { const error = new Error('File not found'); error.status = 404; throw error; };
  const result = await collectSource(client, 'drive', 'test@example.com', directory);
  assert.equal(result.complete, true);
  assert.equal(result.ignoredTooLarge, 1);
  assert.equal(result.unavailableTargets.length, 1);
  const report = JSON.parse(await readFile(result.ignoredTooLargeLog, 'utf8'));
  assert.equal(report.files[0].name, 'Large SQL');
  assert.equal(report.files[0].id, 'large');
  assert.match(report.files[0].url, /large/);
  assert.match(report.files[0].reason, /exceeds/);
  assert.equal((await collectSource(client, 'drive', 'test@example.com', directory)).ignoredTooLarge, 1);
}));

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
    listMessages: async (_space, args) => args.pageToken ? { messages: [unnamed, reply] } : { messages: [unnamed], nextPageToken: 'next' } };
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
    listMessages: async () => ({ messages: [
      { name: 'spaces/a/messages/x', sender: { name: 'users/unknown' } },
      { name: 'spaces/a/messages/y', sender: { name: 'users/deleted', displayName: 'Deleted User', isAnonymous: true } },
    ] }) };
  const result = await collectSource(client, 'chat', 'test@example.com', directory, () => {});
  assert.equal(result.authors.unresolvedMessages, 1);
  assert.deepEqual(result.authors.unresolvedIds, ['users/unknown']);
  assert.equal(result.authors.placeholderMessages, 1);
  assert.deepEqual(result.authors.placeholderIds, ['users/deleted']);
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

test('publication places every document in the native raw sandbox and splits full content without truncation', async () => temporary(async directory => {
  const source = join(directory, 'collector');
  const raw = join(directory, 'raw');
  const text = 'Full Unicode content 😀 '.repeat(6000);
  const client = { listFiles: async () => ({ files: [{ id: 'large', mimeType: 'text/plain' }, { id: 'small', mimeType: 'text/plain' }] }),
    listDrives: async () => ({ drives: [] }), fileContent: async file => ({ status: 'collected', text: file.id === 'large' ? text : 'Small content' }) };
  await collectSource(client, 'drive', 'test@example.com', source, () => {});
  const index = await publishCollection(source, raw, 'google-test/drive');
  assert.equal(index.discovered, 2);
  assert.equal(index.rawConnectorId, 'custom-mcp');
  const large = [];
  const ids = new Set();
  for (const batch of index.batches) {
    const bytes = await readFile(join(raw, batch.path));
    assert.ok(bytes.length < 100000);
    const value = JSON.parse(bytes);
    for (const record of value.records) {
      ids.add(record.sourceId);
      if (record.sourceId === 'large') large.push(record);
    }
  }
  assert.deepEqual([...ids].sort(), ['large', 'small']);
  assert.equal(JSON.parse(large.sort((a,b) => a.part-b.part).map(record => record.documentFragment).join('')).text, text);
  assert.equal((await stat(join(source, 'documents/large.json'))).ino, (await stat(join(raw, 'google-test/drive/documents/large.json'))).ino);
  assert.deepEqual(await publishCollection(source, raw, 'google-test/drive'), index);
  await assert.rejects(publishCollection(source, raw, '../credentials'), /namespace/);
}));

test('publication rejects incomplete collections and escaped document paths', async () => temporary(async directory => {
  const client = { listSpaces: async () => ({ spaces: [] }) };
  await collectSource(client, 'chat', 'test@example.com', directory, () => {});
  const path = join(directory, 'manifest.json');
  const state = JSON.parse(await readFile(path, 'utf8'));
  state.complete = false;
  await writeFile(path, JSON.stringify(state));
  await assert.rejects(publishCollection(directory, join(directory, 'raw'), 'google-test/chat'), /must finish/);
  state.complete = true;
  state.items.secret = { status: 'collected', path: '/outside/credentials.json' };
  await writeFile(path, JSON.stringify(state));
  await assert.rejects(publishCollection(directory, join(directory, 'raw'), 'google-test/chat'), /escapes/);
}));

test('registered sources have the connectedAt marker required by OpenWiki ingestion', () => {
  const first = mergeSources({ sourceInstances: [{ id: 'drive-test' }] }, [{ id: 'drive-test' }, { id: 'chat-test' }]);
  assert.ok(first.sourceInstances.every(source => Number.isFinite(Date.parse(source.connectedAt))));
  assert.deepEqual(mergeSources(first, [{ id: 'drive-test' }, { id: 'chat-test' }]), first);
});

test('plaintext MIME and mislabeled source files decode without execution', async () => {
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {},
    fetchImpl: async url => new Response(url.pathname.endsWith('utf16') ? Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from('Æ source 😀', 'utf16le')]) : 'source text') });
  for (const file of [{ id: 'dart', mimeType: 'application/vnd.dart' }, { id: 'js', mimeType: 'application/x-javascript' }, { id: 'vue', name: 'component.vue', mimeType: 'binary/octet-stream' }]) {
    assert.equal((await client.fileContent(file)).text, 'source text');
  }
  const utf16 = await client.fileContent({ id: 'utf16', mimeType: 'text/plain' });
  assert.equal(utf16.text, 'Æ source 😀');
  assert.equal(utf16.encoding, 'utf-16le');
});

test('approved large-file policy also bounds extracted text and records empty PDF gaps', async () => {
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {}, ignoreTooLarge: true,
    fetchImpl: async () => new Response('small input') });
  const file = { id: 'pdf', mimeType: 'application/pdf' };
  const oversized = await client.fileContent(file, async () => 'x'.repeat(64 * 1024 * 1024 + 1));
  assert.equal(oversized.ignoredTooLarge, true);
  assert.match(oversized.reason, /Extracted text/);
  const empty = await client.fileContent(file, async () => ' ');
  assert.equal(empty.status, 'metadata');
  assert.match(empty.reason, /OCR is outside scope/);
});

test('bounded document serialization preserves Unicode, controls, and metadata', async () => temporary(async directory => {
  const value = { source: 'test', metadata: { id: 'text' }, text: ('a'.repeat(65535) + '😀\n"\\').repeat(20) };
  const path = join(directory, 'large.json');
  await atomicJson(path, value);
  assert.deepEqual(JSON.parse(await readFile(path, 'utf8')), value);
}));

test('inherited argument names are rejected before API access', async () => {
  await assert.rejects(callTool('drive', 'drive_get_file_metadata', { fileId: 'test', constructor: 'bad' }, {}), /Invalid argument/);
});

test('refreshed tokens are revalidated before any protected Drive read', async () => {
  for (const mode of ['extra-scope', 'wrong-account', 'valid']) {
    let token = 'old';
    let refreshedReads = 0;
    let scopeChecks = 0;
    const client = new GoogleReadClient({ accountEmail: 'test@example.com', accessToken: async () => token,
      refreshToken: async () => { token = 'new'; }, fetchImpl: async (url, options) => {
        const address = String(url);
        assert.equal(options.method, 'GET');
        if (address.includes('/tokeninfo?')) {
          scopeChecks++;
          return jsonResponse({ scope: [...SCOPES, ...(token === 'new' && mode === 'extra-scope' ? ['https://www.googleapis.com/auth/drive'] : [])].join(' ') });
        }
        if (address.includes('/about?')) return jsonResponse({ user: { emailAddress: token === 'new' && mode === 'wrong-account' ? 'other@example.com' : 'test@example.com' } });
        if (token === 'old') return jsonResponse({}, 401);
        refreshedReads++;
        return jsonResponse({ files: [] });
      } });
    if (mode === 'valid') assert.deepEqual(await client.listFiles(), { files: [] });
    else await assert.rejects(client.listFiles(), mode === 'extra-scope' ? /required read-only scopes/ : /configured account/);
    assert.equal(scopeChecks, 2);
    assert.equal(refreshedReads, mode === 'valid' ? 1 : 0);
  }
});

test('ARQO binary backups are explicit unsupported records and BOM-less UTF16 remains readable', async () => {
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {},
    fetchImpl: async url => new Response(url.pathname.endsWith('arq') ? Buffer.from([65, 82, 81, 79, 0xff, 0x00]) : Buffer.from('{"name":"Æ"}', 'utf16le')) });
  const binary = await client.fileContent({ id: 'arq', mimeType: 'application/json' });
  assert.equal(binary.status, 'unsupported');
  assert.match(binary.reason, /ARQO binary/);
  const text = await client.fileContent({ id: 'utf16', mimeType: 'application/json' });
  assert.equal(text.encoding, 'utf-16le');
  assert.equal(text.text, '{"name":"Æ"}');
});

test('completed manifests retry newly supported plaintext formats exactly once', async () => temporary(async directory => {
  const file = { id: 'diagram', name: 'data.drawio', mimeType: 'application/vnd.jgraph.mxfile' };
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {},
    fetchImpl: async () => new Response('<mxfile><diagram>source</diagram></mxfile>') });
  let reads = 0;
  const original = client.fileContent.bind(client);
  client.fileContent = async (...args) => { reads++; return original(...args); };
  client.listFiles = async () => ({ files: [file] });
  client.listDrives = async () => ({ drives: [] });
  await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  const path = join(directory, 'manifest.json');
  const state = JSON.parse(await readFile(path, 'utf8'));
  state.items.diagram.status = 'unsupported';
  state.items.diagram.reason = 'No text extractor for application/vnd.jgraph.mxfile';
  await writeFile(path, JSON.stringify(state));
  await writeFile(state.items.diagram.path, JSON.stringify({ metadata: file, status: 'unsupported', reason: state.items.diagram.reason }));
  await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  assert.equal(reads, 2);
  assert.equal(JSON.parse(await readFile(path, 'utf8')).items.diagram.status, 'collected');
  await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  assert.equal(reads, 2);
}));

test('approved size policy migrates legacy captured workbooks without deleting their raw capture', async () => temporary(async directory => {
  const file = { id: 'legacy', name: 'legacy.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' };
  const client = { listFiles: async () => ({ files: [file] }), listDrives: async () => ({ drives: [] }),
    fileContent: async () => ({ status: 'collected', text: 'x'.repeat(64 * 1024 * 1024 + 1), bytes: 1 }) };
  await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  const path = join(directory, 'manifest.json');
  const state = JSON.parse(await readFile(path, 'utf8'));
  state.version = 2;
  await writeFile(path, JSON.stringify(state));
  client.ignoreTooLarge = true;
  client.fileContent = async () => { throw new Error('Legacy capture must not be downloaded again'); };
  await collectSource(client, 'drive', 'test@example.com', directory, () => {});
  const migrated = JSON.parse(await readFile(path, 'utf8'));
  assert.equal(migrated.version, 3);
  assert.equal(migrated.items.legacy.status, 'unsupported');
  assert.equal(migrated.items.legacy.ignoredTooLarge, true);
  const document = JSON.parse(await readFile(migrated.items.legacy.path, 'utf8'));
  assert.ok((await stat(document.retainedCapturePath)).size > 64 * 1024 * 1024);
  assert.match(document.reason, /Previously captured text/);
}));

test('legacy Windows1252 plaintext is decoded explicitly without accepting binary control bytes', async () => {
  const client = new GoogleReadClient({ accessToken: async () => 'test', refreshToken: async () => {},
    fetchImpl: async url => new Response(url.pathname.endsWith('text') ? Buffer.from([0xc5, 0x72, 0x73, 0x74, 0x61, 0x6c]) : Buffer.from([0xff, 0x00, 0x01])) });
  const text = await client.fileContent({ id: 'text', mimeType: 'text/plain' });
  assert.equal(text.text, 'Årstal');
  assert.equal(text.encoding, 'windows-1252');
  await assert.rejects(client.fileContent({ id: 'binary', mimeType: 'text/plain' }), /Unsupported text encoding/);
});
