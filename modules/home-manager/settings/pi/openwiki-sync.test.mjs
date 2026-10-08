import assert from 'node:assert/strict';
import test from 'node:test';
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { acquireLock, personalDue, repoState, syncPersonal } from './openwiki-sync.mjs';

function fixture(t) {
  const home = mkdtempSync(join(tmpdir(), 'openwiki-refresh-'));
  t.after(() => rmSync(home, { recursive: true, force: true }));
  return {
    home, stateDirectory: join(home, 'state'), openwikiDirectory: join(home, '.openwiki'),
    git: 'git', node: process.execPath, refreshIntervalMs: 6000, retryIntervalMs: 1000,
  };
}

function repository(t) {
  const config = fixture(t);
  const root = join(config.home, 'repo');
  mkdirSync(join(root, 'openwiki'), { recursive: true });
  const git = (...args) => execFileSync('git', args, {
    cwd: root, stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1' },
  });
  git('init', '-q');
  writeFileSync(join(root, 'source.ts'), 'export const a = 1;\n');
  writeFileSync(join(root, 'openwiki', 'quickstart.md'), 'wiki\n');
  git('add', '.');
  const commit = () => git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', '-c', 'core.hooksPath=/dev/null', 'commit', '-qm', 'fixture', '--no-gpg-sign');
  commit();
  return { config, root, git, commit };
}

test('repository snapshots detect dirty, untracked, deleted and committed source changes', (t) => {
  const { root, git, commit } = repository(t);
  let prior = repoState(root).fingerprint;
  for (const modify of [
    () => writeFileSync(join(root, 'source.ts'), 'export const a = 22;\n'),
    () => writeFileSync(join(root, 'new.ts'), 'new source\n'),
    () => writeFileSync(join(root, 'new.ts'), 'changed untracked source\n'),
    () => rmSync(join(root, 'new.ts')),
    () => { git('add', '.'); commit(); },
    () => rmSync(join(root, 'source.ts')),
  ]) {
    modify();
    const next = repoState(root).fingerprint;
    assert.notEqual(next, prior);
    prior = next;
  }
});

test('generated wiki and crew state do not trigger another refresh', (t) => {
  const { root } = repository(t);
  const prior = repoState(root).fingerprint;
  writeFileSync(join(root, 'openwiki', 'quickstart.md'), 'updated wiki\n');
  writeFileSync(join(root, 'openwiki', '.run.json'), '{}');
  mkdirSync(join(root, '.pi', 'messenger'), { recursive: true });
  writeFileSync(join(root, '.pi', 'messenger', 'crew.json'), '{}');
  assert.equal(repoState(root).fingerprint, prior);
});

test('no wiki or no Git repository is a no-op', (t) => {
  const config = fixture(t);
  assert.equal(repoState(config.home), null);
  const { root } = repository(t);
  rmSync(join(root, 'openwiki'), { recursive: true });
  assert.equal(repoState(root), null);
});

test('locks serialize callers and recover a dead owner', (t) => {
  const config = fixture(t);
  const path = join(config.stateDirectory, 'test.lock');
  const release = acquireLock(path);
  assert.equal(acquireLock(path), null);
  const probe = spawnSync(process.execPath, ['--input-type=module', '-e', `
    import { acquireLock } from ${JSON.stringify(new URL('./openwiki-sync.mjs', import.meta.url).href)};
    console.log(acquireLock(${JSON.stringify(path)}) === null);
  `], { encoding: 'utf8' });
  assert.equal(probe.status, 0, probe.stderr);
  assert.equal(probe.stdout.trim(), 'true');
  release();
  release();
  mkdirSync(path);
  const dead = spawnSync(process.execPath, ['-e', '']);
  writeFileSync(join(path, 'owner.json'), JSON.stringify({ pid: dead.pid, token: 'old' }));
  const recovered = acquireLock(path);
  assert.equal(typeof recovered, 'function');
  recovered();
});

test('a lock without an owner is not stolen during initialization', (t) => {
  const config = fixture(t);
  const path = join(config.stateDirectory, 'test.lock');
  mkdirSync(path, { recursive: true });
  assert.equal(acquireLock(path), null);
  assert.ok(existsSync(path));
});

test('personal ingestion records success and throttles checks across callers', async (t) => {
  const config = fixture(t);
  mkdirSync(config.openwikiDirectory);
  writeFileSync(join(config.openwikiDirectory, 'onboarding.json'), '{}');
  let calls = 0;
  const options = { dueOnly: true, run: async () => { calls++; }, now: () => 10000 };
  assert.equal(await syncPersonal(config, options), 'complete');
  assert.equal(await syncPersonal(config, options), 'fresh');
  assert.equal(calls, 1);
  assert.equal(personalDue(config, 16000), true);
  assert.equal(await syncPersonal(config, { ...options, dueOnly: false }), 'complete');
  assert.equal(calls, 2);
});

test('personal failures preserve success time and apply retry cooldown', async (t) => {
  const config = fixture(t);
  mkdirSync(config.openwikiDirectory);
  writeFileSync(join(config.openwikiDirectory, 'onboarding.json'), '{}');
  await syncPersonal(config, { run: async () => {}, now: () => 10000 });
  await assert.rejects(syncPersonal(config, {
    run: async () => { throw new Error('provider failed'); }, now: () => 20000,
  }), /provider failed/);
  assert.deepEqual(JSON.parse(readFileSync(join(config.stateDirectory, 'personal.json'), 'utf8')), {
    attemptAt: 20000, successAt: 10000,
  });
  assert.equal(personalDue(config, 20500), false);
  assert.equal(personalDue(config, 21000), true);
  assert.equal(existsSync(join(config.stateDirectory, 'personal.lock')), false);
});

test('the deployed CLI works through symlinks and reports provider failures', (t) => {
  const config = fixture(t);
  config.cli = join(config.home, 'fake-cli.mjs');
  config.path = '/usr/bin:/bin';
  mkdirSync(config.openwikiDirectory);
  writeFileSync(join(config.openwikiDirectory, 'onboarding.json'), '{}');
  const directory = join(config.home, 'package');
  mkdirSync(directory);
  copyFileSync(new URL('./openwiki-sync.mjs', import.meta.url), join(directory, 'openwiki-sync.mjs'));
  writeFileSync(join(directory, 'config.json'), JSON.stringify(config));
  const entry = join(config.home, 'runner.mjs');
  symlinkSync(join(directory, 'openwiki-sync.mjs'), entry);
  writeFileSync(config.cli, `
    import assert from 'node:assert/strict';
    assert.deepEqual(process.argv.slice(2), ['ingest', 'all']);
    assert.equal(process.env.OPENWIKI_CONFIG_DIR, ${JSON.stringify(config.openwikiDirectory)});
  `);
  const run = () => spawnSync(process.execPath, [entry], { encoding: 'utf8' });
  const success = run();
  assert.equal(success.status, 0, success.stderr);
  assert.match(success.stdout, /OpenWiki personal: complete/);
  writeFileSync(config.cli, 'process.exitCode = 7;');
  const failure = run();
  assert.equal(failure.status, 1);
  assert.match(failure.stderr, /ingestion failed \(7\)/);
  assert.equal(existsSync(join(config.stateDirectory, 'personal.lock')), false);
});

test('personal sync skips missing setup and never bypasses a live lock', async (t) => {
  const config = fixture(t);
  assert.equal(await syncPersonal(config), 'unconfigured');
  mkdirSync(config.openwikiDirectory);
  writeFileSync(join(config.openwikiDirectory, 'onboarding.json'), '{}');
  const release = acquireLock(join(config.stateDirectory, 'personal.lock'));
  assert.equal(await syncPersonal(config, { run: async () => assert.fail('must not run') }), 'busy');
  release();
});
