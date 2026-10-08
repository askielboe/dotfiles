import { mkdir, readFile, writeFile, rename, rm } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createInterface } from 'node:readline';
import { spawnSync } from 'node:child_process';

export const SCOPES = [
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/chat.spaces.readonly',
  'https://www.googleapis.com/auth/chat.messages.readonly',
];
const FILE_FIELDS = 'id,name,mimeType,modifiedTime,size,webViewLink,driveId,shortcutDetails,description';
const EXPORTS = {
  'application/vnd.google-apps.document': 'text/plain',
  'application/vnd.google-apps.spreadsheet': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.google-apps.presentation': 'text/plain',
};
const ARCHIVES = new Set([
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.oasis.opendocument.text',
  'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.oasis.opendocument.presentation',
]);

export async function atomicJson(path, value) {
  const temporary = `${path}.${process.pid}.tmp`;
  await writeFile(temporary, `${JSON.stringify(value)}\n`, { mode: 0o600 });
  await rename(temporary, path);
}

export async function paginate(state, key, fetchPage, acceptPage, save) {
  const progress = state.pagination[key] ??= { pages: 0, done: false };
  const seen = new Set();
  while (!progress.done) {
    const cursor = progress.nextPageToken ?? '';
    if (seen.has(cursor)) throw new Error(`Repeated page token for ${key}`);
    seen.add(cursor);
    let page;
    try {
      page = await fetchPage(cursor);
      if (page.incompleteSearch) throw new Error(`Google returned incompleteSearch for ${key}`);
      await acceptPage(page);
      delete progress.error;
    } catch (error) { progress.error = error.message; await save(); throw error; }
    progress.pages++;
    progress.nextPageToken = page.nextPageToken || undefined;
    progress.done = !progress.nextPageToken;
    await save();
  }
}

export class GoogleReadClient {
  constructor({ accessToken, refreshToken, fetchImpl = fetch, sleep = ms => new Promise(resolve => setTimeout(resolve, ms)) }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.fetch = fetchImpl;
    this.sleep = sleep;
  }

  async get(service, resource, parameters = {}, binary = false) {
    const bases = { drive: 'https://www.googleapis.com/drive/v3/', chat: 'https://chat.googleapis.com/v1/' };
    if (!bases[service] || resource.startsWith('/') || resource.includes('..') || resource.includes('?') || resource.includes(':')) {
      throw new Error('Invalid read-only Google resource');
    }
    const url = new URL(resource, bases[service]);
    for (const [key, value] of Object.entries(parameters)) if (value !== undefined) url.searchParams.set(key, String(value));
    for (let attempt = 0; attempt < 6; attempt++) {
      const token = await this.accessToken();
      const response = await this.fetch(url, {
        method: 'GET', headers: { Authorization: `Bearer ${token}` }, redirect: 'error', signal: AbortSignal.timeout(120000),
      });
      if (response.ok) return binary ? Buffer.from(await response.arrayBuffer()) : response.json();
      if (response.status === 401 && attempt === 0) { await this.refreshToken(); continue; }
      if ((response.status === 429 || response.status >= 500) && attempt < 5) {
        const retryAfter = Number(response.headers.get('retry-after'));
        await this.sleep(Math.min(120000, (retryAfter > 0 ? retryAfter * 1000 : 1000 * 2 ** attempt)));
        continue;
      }
      const detail = await response.json().catch(() => ({}));
      const error = new Error(`Google ${service} GET ${resource}: HTTP ${response.status} ${detail.error?.message ?? ''}`);
      error.status = response.status;
      throw error;
    }
    throw new Error('Google read retries exhausted');
  }

  listFiles(args = {}) {
    const parameters = { q: 'trashed=false', pageSize: 1000, supportsAllDrives: true, includeItemsFromAllDrives: true,
      fields: `nextPageToken,incompleteSearch,files(${FILE_FIELDS})`, ...args };
    return this.get('drive', 'files', parameters);
  }

  listDrives(args = {}) { return this.get('drive', 'drives', { pageSize: 100, fields: 'nextPageToken,drives(id,name)', ...args }); }
  listSpaces(args = {}) { return this.get('chat', 'spaces', { pageSize: 1000, ...args }); }
  listMessages(space, args = {}) {
    validateSpace(space);
    return this.get('chat', `${space}/messages`, { pageSize: 1000, showDeleted: false, orderBy: 'createTime ASC', ...args });
  }
  fileMetadata(id) { validateFileId(id); return this.get('drive', `files/${id}`, { supportsAllDrives: true, fields: FILE_FIELDS }); }

  async fileContent(file, extractor) {
    const mime = file.mimeType;
    if (mime === 'application/vnd.google-apps.folder') return { status: 'metadata', reason: 'Folder' };
    if (mime === 'application/vnd.google-apps.shortcut') return { status: 'metadata', reason: 'Shortcut; target retained in metadata' };
    const exported = EXPORTS[mime];
    const textual = mime?.startsWith('text/') || /^(application\/(json|xml|javascript|x-ndjson)|image\/svg\+xml)$/.test(mime ?? '');
    if (!exported && !textual && !ARCHIVES.has(mime) && mime !== 'application/pdf') {
      return { status: 'unsupported', reason: `No text extractor for ${mime}` };
    }
    validateFileId(file.id);
    const bytes = exported
      ? await this.get('drive', `files/${file.id}/export`, { mimeType: exported }, true)
      : await this.get('drive', `files/${file.id}`, { alt: 'media', supportsAllDrives: true }, true);
    const effectiveMime = exported ?? mime;
    const text = ARCHIVES.has(effectiveMime) || effectiveMime === 'application/pdf'
      ? await extractor(bytes, effectiveMime) : bytes.toString('utf8');
    return { status: 'collected', text, bytes: bytes.length, representation: effectiveMime };
  }
}

function validateFileId(id) { if (typeof id !== 'string' || !/^[A-Za-z0-9_-]+$/.test(id)) throw new Error('Invalid Drive file ID'); }
function validateSpace(space) { if (typeof space !== 'string' || !/^spaces\/[A-Za-z0-9_-]+$/.test(space)) throw new Error('Invalid Chat space'); }

export const TOOL_NAMES = {
  drive: ['drive_list_files', 'drive_list_shared_drives', 'drive_get_file_metadata', 'drive_read_file', 'collection_status'],
  chat: ['chat_list_spaces', 'chat_list_messages', 'collection_status'],
};
const schema = properties => ({ type: 'object', properties, additionalProperties: false });
const string = { type: 'string' };
export function toolsFor(service) {
  const definitions = {
    drive_list_files: ['List one page of non-trashed Drive file metadata.', schema({ pageToken: string, driveId: string })],
    drive_list_shared_drives: ['List one page of accessible shared drives.', schema({ pageToken: string })],
    drive_get_file_metadata: ['Read file metadata.', { ...schema({ fileId: string }), required: ['fileId'] }],
    drive_read_file: ['Read supported file content without modifying Google files.', { ...schema({ fileId: string }), required: ['fileId'] }],
    chat_list_spaces: ['List one page of accessible Chat conversations, including DMs and spaces.', schema({ pageToken: string })],
    chat_list_messages: ['Read one page of available messages and thread replies without a date cutoff.', { ...schema({ space: string, pageToken: string }), required: ['space'] }],
    collection_status: ['Read the completed local collection manifest, including every document path and source coverage.', schema({})],
  };
  if (!TOOL_NAMES[service]) throw new Error('Invalid Google service');
  return TOOL_NAMES[service].map(name => ({ name, description: definitions[name][0], inputSchema: definitions[name][1],
    annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: true } }));
}

export async function callTool(service, name, args, context) {
  const definition = toolsFor(service).find(tool => tool.name === name);
  if (!definition) throw new Error('Tool is not explicitly allowed by the read-only bridge');
  if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('Invalid tool arguments');
  for (const key of Object.keys(args)) {
    if (!(key in definition.inputSchema.properties) || typeof args[key] !== 'string') throw new Error(`Invalid argument ${key}`);
  }
  for (const key of definition.inputSchema.required ?? []) if (!args[key]) throw new Error(`Missing argument ${key}`);
  const { client, extractor, status } = context;
  switch (name) {
    case 'drive_list_files': return client.listFiles({ pageToken: args.pageToken, ...(args.driveId ? { corpora: 'drive', driveId: args.driveId } : { corpora: 'user' }) });
    case 'drive_list_shared_drives': return client.listDrives(args);
    case 'drive_get_file_metadata': return client.fileMetadata(args.fileId);
    case 'drive_read_file': return client.fileContent(await client.fileMetadata(args.fileId), extractor);
    case 'chat_list_spaces': return client.listSpaces(args);
    case 'chat_list_messages': return client.listMessages(args.space, { pageToken: args.pageToken });
    case 'collection_status': {
      const manifest = await status();
      if (!manifest.complete) throw new Error('Collection is incomplete; openwiki-google collect must finish before synthesis');
      return manifest;
    }
    default: throw new Error('Disallowed operation');
  }
}

export function coverage(state) {
  const counts = {};
  for (const item of Object.values(state.items)) counts[item.status] = (counts[item.status] ?? 0) + 1;
  return { service: state.service, account: state.account, complete: state.complete,
    discovered: Object.keys(state.items).length, counts, pagination: state.pagination,
    corpusDirectory: state.corpusDirectory, limitations: state.limitations, failures: state.failures,
    documents: Object.values(state.items).filter(item => item.path).map(item => item.path),
    authors: state.service === 'chat' ? {
      people: state.people ?? {},
      unresolvedMessages: Object.values(state.items).filter(item => !item.authorResolved).length,
      unresolvedIds: [...new Set(Object.values(state.items).filter(item => !item.authorResolved).map(item => item.userId ?? 'unknown'))],
    } : undefined };
}

export async function collectSource(client, service, account, directory, extractor) {
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const lock = join(directory, 'collection.lock');
  try { await mkdir(lock); } catch (error) {
    if (error.code !== 'EEXIST') throw error;
    const owner = Number(await readFile(join(lock, 'pid'), 'utf8').catch(() => '0'));
    if (!owner) throw new Error('Collection lock has no owner; manual inspection required');
    try { process.kill(owner, 0); throw new Error('A collection for this source is already running'); }
    catch (locked) { if (locked.code !== 'ESRCH') throw locked; }
    await rm(lock, { recursive: true });
    await mkdir(lock);
  }
  await writeFile(join(lock, 'pid'), String(process.pid), { mode: 0o600 });
  try {
    const path = join(directory, 'manifest.json');
    let state;
    try { state = JSON.parse(await readFile(path, 'utf8')); } catch (error) { if (error.code !== 'ENOENT') throw error; }
    state ??= { version: 1, service, account, corpusDirectory: directory, items: {}, pagination: {}, sharedDrives: {}, spaces: {}, failures: [],
      limitations: ['Only content exposed to this account by Google is accessible.', 'Deleted and retention-expired content is excluded.'], startedAt: new Date().toISOString() };
    if (state.service !== service || state.account !== account) throw new Error('Collection manifest account mismatch');
    if (state.complete) return coverage(state);
    state.failures = [];
    const save = () => atomicJson(path, state);
    const documents = join(directory, 'documents');
    await mkdir(documents, { recursive: true, mode: 0o700 });
    if (service === 'drive') {
      const acceptFiles = async page => {
        for (const file of page.files ?? []) state.items[file.id] ??= { metadata: file, status: 'pending' };
      };
      await paginate(state, 'userFiles', token => client.listFiles({ corpora: 'user', pageToken: token }), acceptFiles, save);
      await paginate(state, 'sharedDrives', token => client.listDrives({ pageToken: token }), async page => {
        for (const drive of page.drives ?? []) state.sharedDrives[drive.id] = drive;
      }, save);
      for (const id of Object.keys(state.sharedDrives)) {
        await paginate(state, `drive:${id}`, token => client.listFiles({ corpora: 'drive', driveId: id, pageToken: token }), acceptFiles, save);
      }
      // Shared folders and shortcut targets can expose files absent from the user's corpus.
      const visited = new Set();
      while (true) {
        const entry = Object.entries(state.items).find(([id]) => !visited.has(id));
        if (!entry) break;
        const [sourceId, item] = entry;
        visited.add(sourceId);
        const targetId = item.metadata.shortcutDetails?.targetId;
        if (targetId && !state.items[targetId]) {
          try { state.items[targetId] = { metadata: await client.fileMetadata(targetId), status: 'pending' }; }
          catch (error) { state.failures.push({ source: sourceId, shortcutTarget: targetId, error: error.message }); }
        }
        if (item.metadata.mimeType === 'application/vnd.google-apps.folder') {
          validateFileId(sourceId);
          const corpus = item.metadata.driveId ? { corpora: 'drive', driveId: item.metadata.driveId } : { corpora: 'user' };
          await paginate(state, `folder:${sourceId}`, token => client.listFiles({ ...corpus, q: `'${sourceId}' in parents and trashed=false`, pageToken: token }), acceptFiles, save);
        }
      }
      for (const [id, item] of Object.entries(state.items)) {
        if (['collected', 'metadata', 'unsupported'].includes(item.status)) continue;
        try {
          const content = await client.fileContent(item.metadata, extractor);
          const doc = { source: item.metadata.webViewLink ?? `https://drive.google.com/file/d/${id}/view`, metadata: item.metadata, ...content };
          item.path = join(documents, `${id}.json`);
          await atomicJson(item.path, doc);
          item.status = content.status;
          item.reason = content.reason;
          delete item.error;
        } catch (error) { item.status = 'failed'; item.error = error.message; }
        await save();
      }
    } else {
      state.people ??= {};
      state.limitations.push(...(state.limitations.includes('Google Chat omits system messages.') ? [] : ['Google Chat omits system messages.', 'History-disabled conversations may no longer expose prior messages.']));
      await paginate(state, 'spaces', token => client.listSpaces({ pageToken: token }), async page => {
        for (const space of page.spaces ?? []) state.spaces[space.name] = space;
      }, save);
      for (const [name, space] of Object.entries(state.spaces)) {
        await paginate(state, `messages:${name}`, token => client.listMessages(name, { pageToken: token }), async page => {
          for (const message of page.messages ?? []) {
            if (!message.name) throw new Error(`Message without source ID in ${name}`);
            if (message.deleteTime) continue;
            if (state.items[message.name]?.status === 'collected') continue;
            for (const person of [message.sender, ...(message.annotations ?? []).map(annotation => annotation.userMention?.user)]) {
              if (person?.name && person.displayName) state.people[person.name] = { id: person.name, displayName: person.displayName, email: person.email, type: person.type };
            }
            const author = state.people[message.sender?.name];
            const id = message.name.replaceAll('/', '_');
            const docPath = join(documents, `${id}.json`);
            await atomicJson(docPath, { source: space.spaceUri ?? `https://chat.google.com/room/${name.split('/')[1]}`,
              sourceId: message.name, space, message, author: author ?? { id: message.sender?.name, unresolved: true }, status: 'collected' });
            state.items[message.name] = { status: 'collected', path: docPath, space: name, thread: message.thread?.name,
              createTime: message.createTime, userId: message.sender?.name, authorResolved: Boolean(author) }; 
          }
        }, save);
      }
      for (const item of Object.values(state.items)) {
        const author = state.people[item.userId];
        if (item.authorResolved || !author) continue;
        try {
          const doc = JSON.parse(await readFile(item.path, 'utf8'));
          await atomicJson(item.path, { ...doc, author });
          item.authorResolved = true;
        } catch (error) { state.failures.push({ path: item.path, error: error.message }); }
      }
      await atomicJson(join(directory, 'people.json'), state.people);
    }
    state.complete = Object.values(state.pagination).every(page => page.done)
      && !Object.values(state.items).some(item => ['pending', 'failed'].includes(item.status)) && !state.failures.length;
    state.finishedAt = new Date().toISOString();
    await save();
    const result = coverage(state);
    if (!state.complete) throw new Error(`Collection has unresolved failures; inspect ${path}`);
    return result;
  } finally { await rm(lock, { recursive: true, force: true }); }
}

async function makeContext(account, email, service, root, extractorPath) {
  if (!/^[a-z][a-z0-9-]*$/.test(account) || !email || !TOOL_NAMES[service]) throw new Error('Account, email, and service are required');
  const profile = join(root, 'accounts', account);
  process.env.OPENWIKI_CONFIG_DIR = profile;
  // Parent OpenWiki sessions can carry credentials for a different account.
  for (const key of Object.keys(process.env)) if (/^OPENWIKI_(WORKSPACE_|GOOGLE_CLIENT_)/.test(key)) delete process.env[key];
  const base = join(homedir(), '.pi/agent/npm/node_modules/openwiki/dist');
  const { AUTH_PROVIDERS } = await import(pathToFileURL(join(base, 'auth/providers.js')));
  const { getOAuthAccessToken, refreshOAuthAccessToken } = await import(pathToFileURL(join(base, 'auth/tokens.js')));
  AUTH_PROVIDERS.workspace = { ...AUTH_PROVIDERS.gmail, id: 'workspace', displayName: 'Read-only Google Workspace', scopes: SCOPES,
    tokenMapping: { accessTokenEnvKey: 'OPENWIKI_WORKSPACE_ACCESS_TOKEN', refreshTokenEnvKey: 'OPENWIKI_WORKSPACE_REFRESH_TOKEN',
      expiresAtEnvKey: 'OPENWIKI_WORKSPACE_TOKEN_EXPIRES_AT', tokenTypeEnvKey: 'OPENWIKI_WORKSPACE_TOKEN_TYPE' } };
  const accessToken = () => getOAuthAccessToken('workspace');
  const refreshToken = () => refreshOAuthAccessToken('workspace');
  const client = new GoogleReadClient({ accessToken, refreshToken });
  const token = await accessToken();
  const info = await fetch(`https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(token)}`, { redirect: 'error' });
  if (!info.ok) throw new Error(`Token scope verification failed: HTTP ${info.status}`);
  const granted = (await info.json()).scope?.split(' ') ?? [];
  if (granted.length !== SCOPES.length || !SCOPES.every(scope => granted.includes(scope))) throw new Error('Token does not have exactly the required read-only scopes');
  const identity = await client.get('drive', 'about', { fields: 'user(emailAddress)' });
  if (identity.user?.emailAddress?.toLowerCase() !== email.toLowerCase()) throw new Error('Authenticated Google account does not match the configured account');
  const extractor = async (bytes, mime) => {
    const result = spawnSync(process.env.OPENWIKI_PYTHON ?? 'python3', [extractorPath, mime], { input: bytes, maxBuffer: 256 * 1024 * 1024, timeout: 120000 });
    if (result.error || result.status !== 0) throw new Error(`Text extraction failed: ${result.error?.message ?? result.stderr.toString().slice(0,500)}`);
    return result.stdout.toString('utf8');
  };
  const directory = join(root, 'connectors', `google-${account}`, service);
  return { client, extractor, collect: () => collectSource(client, service, email, directory, extractor),
    status: async () => {
      try { return coverage(JSON.parse(await readFile(join(directory, 'manifest.json'), 'utf8'))); }
      catch (error) { throw new Error(`Collection manifest is unavailable: ${error.message}`); }
    } };
}

async function main() {
  const [mode, account, email, service, extractorPath] = process.argv.slice(2);
  const root = process.env.OPENWIKI_PERSONAL_ROOT ?? join(homedir(), '.openwiki');
  const context = await makeContext(account, email, service, root, extractorPath);
  if (mode === 'verify') {
    await context.client.refreshToken();
    console.log(JSON.stringify({ account: email, scopes: SCOPES, tools: TOOL_NAMES[service], refreshed: true }));
    return;
  }
  if (mode === 'collect') { console.log(JSON.stringify(await context.collect())); return; }
  if (mode !== 'serve') throw new Error('Expected serve, verify, or collect');
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  for await (const line of lines) {
    let request;
    try { request = JSON.parse(line); } catch { process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }) + '\n'); continue; }
    if (request.id === undefined) continue;
    try {
      let result;
      if (request.method === 'initialize') result = { protocolVersion: request.params?.protocolVersion ?? '2024-11-05', capabilities: { tools: {} }, serverInfo: { name: 'openwiki-google-readonly', version: '1.0.0' } };
      else if (request.method === 'ping') result = {};
      else if (request.method === 'tools/list') result = { tools: toolsFor(service) };
      else if (request.method === 'tools/call') result = { content: [{ type: 'text', text: JSON.stringify(await callTool(service, request.params?.name, request.params?.arguments ?? {}, context)) }] };
      else throw new Error('Unsupported MCP method');
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, result }) + '\n');
    } catch (error) { process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: request.id, error: { code: -32602, message: error.message } }) + '\n'); }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; });
}
