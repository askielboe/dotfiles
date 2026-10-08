import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, openSync, closeSync, realpathSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { acquireLock, loadConfig, personalDue, repoLock, repoState } from './openwiki-sync.mjs';

type Snapshot = { root: string; fingerprint: string };
type Pending = Snapshot & { release: () => void; finished: boolean };

export default function openwikiRefresh(pi: ExtensionAPI, suppliedConfig?: ReturnType<typeof loadConfig>) {
  let config: ReturnType<typeof loadConfig>;
  let baseline: Snapshot | null = null;
  let pending: Pending | null = null;
  let syncChild: ReturnType<typeof spawn> | null = null;

  const notify = (ctx: ExtensionContext, message: string, level: 'info' | 'warning' = 'info') => {
    if (ctx.hasUI) ctx.ui.notify(message, level);
  };
  const snapshot = (ctx: ExtensionContext) => repoState(ctx.cwd, config.git);
  const release = () => {
    pending?.release();
    pending = null;
  };
  const startSync = (ctx: ExtensionContext, dueOnly: boolean) => {
    if (syncChild || (dueOnly && !personalDue(config))) return;
    mkdirSync(config.stateDirectory, { recursive: true, mode: 0o700 });
    const log = join(config.stateDirectory, 'personal.log');
    const fd = openSync(log, 'a', 0o600);
    try {
      syncChild = spawn(config.node, [fileURLToPath(new URL('./openwiki-sync.mjs', import.meta.url)), ...(dueOnly ? ['--due'] : [])], {
        cwd: config.home, stdio: ['ignore', fd, fd],
      });
    } finally { closeSync(fd); }
    syncChild.once('error', () => {
      syncChild = null;
      notify(ctx, `OpenWiki personal sync could not start; see ${log}`, 'warning');
    });
    syncChild.once('close', (code) => {
      syncChild = null;
      notify(ctx, code === 0 ? `OpenWiki personal sync checked; log: ${log}` : `OpenWiki personal sync failed; see ${log}`, code === 0 ? 'info' : 'warning');
    });
    notify(ctx, `OpenWiki personal sync requested in background; log: ${log}`);
  };
  const prepare = (ctx: ExtensionContext, state: Snapshot) => {
    const unlock = acquireLock(repoLock(config, state.root));
    if (!unlock) {
      notify(ctx, 'OpenWiki repository refresh deferred: another session holds its lock.', 'warning');
      return null;
    }
    pending = { ...state, release: unlock, finished: false };
    return pending;
  };
  const prompt = (root: string) => `Update the existing repository OpenWiki at ${JSON.stringify(root)} for changes since its last successful run. This is the single guarded refresh requested by the OpenWiki completion hook. Use the openwiki skill and repository lifecycle tools; preserve unaffected pages and reconcile Claims against current source. Do not initialize a new wiki, modify source code, commit, push, or run another refresh. Finish only after openwiki_finish reports complete, or report the blocker and leave the durable run resumable. Do not ingest personal sources or capture this conversation.`;

  pi.on('session_start', (_event, ctx) => {
    config = suppliedConfig ?? loadConfig();
    baseline = snapshot(ctx);
    if (ctx.mode !== 'tui') return;
    if (baseline && existsSync(join(baseline.root, 'openwiki', '.run.json'))) {
      notify(ctx, 'OpenWiki has an unfinished repository update; /wiki-update resumes it.', 'warning');
    }
    if (existsSync(join(config.openwikiDirectory, 'onboarding.json'))) startSync(ctx, true);
  });

  pi.on('tool_result', (event) => {
    if (event.isError) return;
    if (pending) {
      const result = event.details as { status?: string } | undefined;
      if ((event.toolName === 'openwiki_finish' && result?.status === 'complete')
        || (event.toolName === 'openwiki_begin' && result?.status === 'noop')) pending.finished = true;
      return;
    }
  });

  pi.on('tool_call', (event, ctx) => {
    if (event.toolName !== 'openwiki_begin') return;
    const root = event.input.root;
    if (typeof root !== 'string') return;
    if (pending) {
      let canonicalRoot: string;
      try { canonicalRoot = realpathSync(root); }
      catch { return { block: true, reason: 'The OpenWiki repository path does not exist.' }; }
      if (pending.root !== canonicalRoot) return { block: true, reason: 'The current OpenWiki refresh owns a different repository lock.' };
      return;
    }
    const state = repoState(root, config.git);
    // Initializations remain explicit and outside the automatic refresh workflow.
    if (!state) return;
    if (!prepare(ctx, state)) return { block: true, reason: 'Another Pi session is updating this repository OpenWiki.' };
  });

  pi.on('agent_before_settle', (event, ctx) => {
    if (pending || ctx.mode !== 'tui' || event.outcome !== 'completed' || !event.context.canContinue || event.continue) return;
    const state = snapshot(ctx);
    if (!state) return;
    const changed = baseline?.root === state.root && baseline.fingerprint !== state.fingerprint;
    if (!changed) return;
    if (!prepare(ctx, state)) return;
    return {
      entries: [{ type: 'custom_message' as const, customType: 'openwiki-refresh', content: prompt(state.root), display: true }],
      continue: true,
    };
  });

  pi.on('agent_settled', (_event, ctx) => {
    if (pending && !pending.finished) notify(ctx, 'OpenWiki refresh did not finish; /wiki-update retries the resumable run.', 'warning');
    const attempted = pending !== null;
    release();
    // Deferred and aborted source changes remain eligible on the next successful task.
    if (attempted || !baseline) baseline = snapshot(ctx);
  });

  pi.on('session_shutdown', () => {
    release();
    // The child runner forwards termination to ingestion before releasing its personal lock.
    syncChild?.kill('SIGTERM');
  });

  pi.registerCommand('wiki-update', {
    description: 'Update or resume the current repository OpenWiki',
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();
      const state = snapshot(ctx);
      if (!state) {
        notify(ctx, 'No existing repository OpenWiki was found. Initialization remains explicit.', 'warning');
        return;
      }
      if (pending || !prepare(ctx, state)) return;
      try { pi.sendUserMessage(prompt(state.root)); }
      catch (error) { release(); throw error; }
    },
  });

  pi.registerCommand('wiki-sync', {
    description: 'Ingest configured personal OpenWiki sources in the background',
    handler: async (_args, ctx) => startSync(ctx, false),
  });
}
