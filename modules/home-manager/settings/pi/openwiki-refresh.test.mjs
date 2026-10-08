import assert from 'node:assert/strict';
import test from 'node:test';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import extension from './openwiki-refresh.ts';
import { acquireLock, repoLock } from './openwiki-sync.mjs';

function setup(t, mode = 'tui') {
  const home = mkdtempSync(join(tmpdir(), 'openwiki-hook-'));
  t.after(() => rmSync(home, { recursive: true, force: true }));
  const root = join(home, 'repo');
  mkdirSync(join(root, 'openwiki'), { recursive: true });
  execFileSync('git', ['init', '-q'], { cwd: root });
  writeFileSync(join(root, 'source.ts'), 'source\n');
  writeFileSync(join(root, 'openwiki', 'quickstart.md'), 'wiki\n');
  const config = { home, git: 'git', stateDirectory: join(home, 'state'), openwikiDirectory: join(home, '.openwiki') };
  const handlers = new Map();
  const commands = new Map();
  const messages = [];
  const notices = [];
  const ctx = { cwd: root, mode, hasUI: mode === 'tui', ui: { notify: (message) => notices.push(message) }, waitForIdle: async () => {} };
  extension({
    on: (name, handler) => handlers.set(name, handler),
    registerCommand: (name, command) => commands.set(name, command),
    sendUserMessage: (message) => messages.push(message),
  }, config);
  const emit = (name, event = {}) => handlers.get(name)(event, ctx);
  emit('session_start');
  const edit = () => {
    writeFileSync(join(root, 'source.ts'), 'changed source\n');
    emit('tool_result', { toolName: 'write', isError: false });
  };
  const settle = (override = {}) => emit('agent_before_settle', {
    outcome: 'completed', continue: false, context: { canContinue: true }, ...override,
  });
  t.after(() => emit('session_shutdown'));
  return { config, root, handlers, commands, messages, notices, emit, edit, settle };
}

test('one source change requests one lifecycle continuation, not an update loop', (t) => {
  const { root, emit, edit, settle, notices } = setup(t);
  assert.equal(settle(), undefined);
  edit();
  const result = settle();
  assert.equal(result.continue, true);
  assert.equal(result.entries[0].type, 'custom_message');
  assert.match(result.entries[0].content, /openwiki skill/);
  assert.match(result.entries[0].content, /Do not.*modify source code/);
  writeFileSync(join(root, 'openwiki', 'quickstart.md'), 'new wiki\n');
  emit('tool_result', { toolName: 'write', isError: false });
  assert.equal(settle(), undefined);
  emit('tool_result', { toolName: 'openwiki_finish', isError: false, details: { status: 'complete' } });
  emit('agent_settled');
  assert.equal(settle(), undefined);
  assert.equal(notices.length, 0);
});

test('aborted, erroneous and already continuing runs do not start refreshes', (t) => {
  const { edit, settle } = setup(t);
  edit();
  assert.equal(settle({ outcome: 'aborted' }), undefined);
  assert.equal(settle({ outcome: 'error' }), undefined);
  assert.equal(settle({ continue: true }), undefined);
  assert.equal(settle({ context: { canContinue: false } }), undefined);
});

for (const mode of ['print', 'json', 'rpc']) {
  test(`automatic refreshes stay out of ${mode} workers`, (t) => {
    const { edit, settle } = setup(t, mode);
    edit();
    assert.equal(settle(), undefined);
  });
}

test('source snapshots cover edits from other tool backends without a hardcoded tool list', (t) => {
  const { root, emit, settle } = setup(t);
  writeFileSync(join(root, 'source.ts'), 'another backend changed source\n');
  emit('tool_result', { toolName: 'ast_grep_replace', isError: false });
  assert.equal(settle().continue, true);
});

test('failed edits and wiki-only edits do not trigger generation', (t) => {
  const { root, emit, settle } = setup(t);
  emit('tool_result', { toolName: 'write', isError: true });
  assert.equal(settle(), undefined);
  writeFileSync(join(root, 'openwiki', 'quickstart.md'), 'new wiki\n');
  emit('tool_result', { toolName: 'write', isError: false });
  assert.equal(settle(), undefined);
});

test('another session defers automatic updates and blocks manual lifecycle entry', (t) => {
  const { config, root, edit, settle, emit, notices } = setup(t);
  const release = acquireLock(repoLock(config, root));
  edit();
  assert.equal(settle(), undefined);
  assert.equal(emit('tool_call', { toolName: 'openwiki_begin', input: { root } }).block, true);
  assert.match(notices[0], /another session/);
  emit('agent_settled');
  release();
  assert.equal(settle().continue, true);
});

test('manual command holds its lock through completion and releases at settlement', async (t) => {
  const { config, root, commands, messages, emit } = setup(t);
  await commands.get('wiki-update').handler('', { cwd: root, hasUI: false, waitForIdle: async () => {} });
  assert.equal(messages.length, 1);
  assert.ok(existsSync(repoLock(config, root)));
  assert.equal(emit('tool_call', { toolName: 'openwiki_begin', input: { root } }), undefined);
  assert.equal(emit('tool_call', { toolName: 'openwiki_begin', input: { root: '/other' } }).block, true);
  emit('tool_result', { toolName: 'openwiki_begin', isError: false, details: { status: 'noop' } });
  assert.ok(existsSync(repoLock(config, root)));
  emit('agent_settled');
  assert.equal(existsSync(repoLock(config, root)), false);
});

test('incomplete refreshes report a retry and release their lock', (t) => {
  const { config, root, edit, settle, emit, notices } = setup(t);
  edit();
  settle();
  emit('tool_result', { toolName: 'openwiki_finish', isError: true });
  emit('agent_settled');
  assert.match(notices[0], /did not finish/);
  assert.equal(existsSync(repoLock(config, root)), false);
  assert.equal(settle(), undefined);
});

test('startup reports resumable state without loading wiki pages', (t) => {
  const { root, emit, notices } = setup(t);
  writeFileSync(join(root, 'openwiki', '.run.json'), '{}');
  emit('session_start');
  assert.match(notices[0], /unfinished repository update/);
});
