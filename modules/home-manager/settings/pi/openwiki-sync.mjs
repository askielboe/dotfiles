import { createHash, randomUUID } from 'node:crypto';
import { execFileSync, spawn } from 'node:child_process';
import { existsSync, lstatSync, mkdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export function loadConfig() {
  try { return JSON.parse(readFileSync(new URL('./config.json', import.meta.url), 'utf8')); }
  catch (error) { throw new Error('OpenWiki refresh configuration is unavailable or invalid', { cause: error }); }
}

function alive(pid) {
  try { process.kill(pid, 0); return true; }
  catch (error) { return error.code !== 'ESRCH'; }
}

export function acquireLock(directory) {
  mkdirSync(dirname(directory), { recursive: true, mode: 0o700 });
  const owner = { pid: process.pid, token: randomUUID() };
  const take = () => {
    try { mkdirSync(directory, { mode: 0o700 }); }
    catch (error) { if (error.code === 'EEXIST') return false; throw error; }
    try { writeFileSync(join(directory, 'owner.json'), JSON.stringify(owner), { mode: 0o600 }); }
    catch (error) { rmSync(directory, { recursive: true }); throw error; }
    return true;
  };
  if (!take()) {
    // Recovery has a separate gate so two stale-lock observers cannot remove a new owner.
    const recovery = `${directory}.recovery`;
    try { mkdirSync(recovery, { mode: 0o700 }); }
    catch (error) { if (error.code === 'EEXIST') return null; throw error; }
    try {
      let previous;
      try { previous = JSON.parse(readFileSync(join(directory, 'owner.json'), 'utf8')); }
      catch { return null; }
      if (!Number.isInteger(previous.pid) || previous.pid <= 0 || alive(previous.pid)) return null;
      rmSync(directory, { recursive: true });
      if (!take()) return null;
    } finally { rmSync(recovery, { recursive: true, force: true }); }
  }
  return () => {
    try {
      if (JSON.parse(readFileSync(join(directory, 'owner.json'), 'utf8')).token === owner.token) {
        rmSync(directory, { recursive: true });
      }
    } catch (error) { if (error.code !== 'ENOENT') throw error; }
  };
}

export function repoState(cwd, git = 'git') {
  const run = (args, root = cwd) => execFileSync(git, args, {
    cwd: root, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'],
  });
  let root;
  try { root = run(['rev-parse', '--show-toplevel']).trim(); }
  catch { return null; }
  if (!existsSync(join(root, 'openwiki', 'quickstart.md'))) return null;
  const paths = ['.', ':(exclude)openwiki', ':(exclude).pi/messenger'];
  const hash = createHash('sha256');
  // File metadata detects working-tree edits without reading private source bytes into the hook.
  hash.update(run(['ls-files', '--stage', '-z', '--', ...paths], root));
  for (const path of run(['ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', ...paths], root).split('\0').filter(Boolean)) {
    hash.update(path).update('\0');
    try {
      const stat = lstatSync(join(root, path), { bigint: true });
      hash.update(`${stat.mode}:${stat.size}:${stat.mtimeNs}:${stat.ctimeNs}`);
    } catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  return { root, fingerprint: hash.digest('hex') };
}

export function repoLock(config, root) {
  return join(config.stateDirectory, `repo-${createHash('sha256').update(realpathSync(root)).digest('hex')}.lock`);
}

export function personalDue(config, now = Date.now()) {
  let state = {};
  try { state = JSON.parse(readFileSync(join(config.stateDirectory, 'personal.json'), 'utf8')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  return now - (state.successAt ?? 0) >= config.refreshIntervalMs
    && now - (state.attemptAt ?? 0) >= config.retryIntervalMs;
}

export async function syncPersonal(config, { dueOnly = false, run = runIngest, now = Date.now } = {}) {
  if (!existsSync(join(config.openwikiDirectory, 'onboarding.json'))) return 'unconfigured';
  const release = acquireLock(join(config.stateDirectory, 'personal.lock'));
  if (!release) return 'busy';
  try {
    if (dueOnly && !personalDue(config, now())) return 'fresh';
    const statePath = join(config.stateDirectory, 'personal.json');
    let state = {};
    try { state = JSON.parse(readFileSync(statePath, 'utf8')); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    state.attemptAt = now();
    writeFileSync(statePath, JSON.stringify(state), { mode: 0o600 });
    await run(config);
    state.successAt = now();
    writeFileSync(statePath, JSON.stringify(state), { mode: 0o600 });
    return 'complete';
  } finally { release(); }
}

function runIngest(config) {
  return new Promise((resolveRun, reject) => {
    const child = spawn(config.node, [config.cli, 'ingest', 'all'], {
      cwd: config.home, stdio: ['ignore', 'inherit', 'inherit'],
      env: {
        ...process.env,
        OPENWIKI_CONFIG_DIR: config.openwikiDirectory,
        PATH: `${config.path}:${process.env.PATH ?? ''}`,
      },
    });
    const stop = () => child.kill('SIGTERM');
    process.once('SIGTERM', stop);
    process.once('SIGINT', stop);
    child.once('error', reject);
    child.once('close', (code, signal) => {
      process.removeListener('SIGTERM', stop);
      process.removeListener('SIGINT', stop);
      if (code === 0) resolveRun();
      else reject(new Error(`Personal OpenWiki ingestion failed (${signal ?? code})`));
    });
  });
}

if (process.argv[1] && realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const config = loadConfig();
    const result = await syncPersonal(config, { dueOnly: process.argv.includes('--due') });
    process.stdout.write(`${new Date().toISOString()} OpenWiki personal: ${result}\n`);
  } catch (error) {
    console.error(`${new Date().toISOString()} ${error.message}`);
    process.exitCode = 1;
  }
}
