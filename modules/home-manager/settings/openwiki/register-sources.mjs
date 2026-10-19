import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { atomicJson } from './google-workspace.mjs';

export function mergeSources(onboarding, sources) {
  if (!Array.isArray(onboarding.sourceInstances) || !Array.isArray(sources)) throw new Error('Invalid OpenWiki source configuration');
  const configured = new Map(sources.map(source => [source.id, source]));
  const connectedAt = new Date().toISOString();
  const instances = onboarding.sourceInstances.map(existing => {
    const source = configured.get(existing.id);
    if (!source) return existing;
    configured.delete(existing.id);
    return { ...existing, ...source, connectedAt: existing.connectedAt ?? source.connectedAt ?? connectedAt };
  });
  const added = [...configured.values()].map(source => ({ ...source, connectedAt: source.connectedAt ?? connectedAt }));
  return { ...onboarding, sourceInstances: [...instances, ...added] };
}

if (process.argv[1]?.endsWith('/register-sources.mjs')) {
  try {
    const root = process.env.OPENWIKI_PERSONAL_ROOT ?? join(homedir(), '.openwiki');
    const path = join(root, 'onboarding.json');
    const onboarding = JSON.parse(await readFile(path, 'utf8'));
    const sources = JSON.parse(await readFile(process.argv[2], 'utf8'));
    await atomicJson(path, mergeSources(onboarding, sources));
  } catch (error) { console.error(`OpenWiki Google source registration failed: ${error.message}`); process.exitCode = 1; }
}
