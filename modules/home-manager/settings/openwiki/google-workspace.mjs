import { mkdir, readFile, writeFile, rename, rm, link, stat, open } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, basename, extname } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createInterface } from 'node:readline';
import { spawnSync } from 'node:child_process';

export const SCOPES = [
  'https://www.googleapis.com/auth/drive.readonly',
  'https://www.googleapis.com/auth/chat.spaces.readonly',
  'https://www.googleapis.com/auth/chat.messages.readonly',
];
const FILE_FIELDS = 'id,name,mimeType,modifiedTime,size,webViewLink,driveId,shortcutDetails,description,trashed';
const TEXT_MIME = /^(text\/|application\/(json|xml|(?:x-)?javascript|x-ndjson|vnd\.dart)$|image\/svg\+xml$)/;
const TEXT_EXTENSIONS = new Set(['.vue', '.csproj', '.swift', '.arb', '.xcconfig', '.podspec', '.lock', '.sln', '.config', '.pbxproj', '.json', '.yaml', '.yml', '.txt', '.md', '.js', '.ts', '.dart', '.cs', '.py', '.xml', '.csv', '.sql', '.drawio']);
function isTextFile(file) { return TEXT_MIME.test(file.mimeType ?? '') || TEXT_EXTENSIONS.has(extname(file.name ?? '').toLowerCase()); }
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
  if (typeof value.text === 'string' && value.text.length > 1024 * 1024) {
    const { text, ...metadata } = value;
    const handle = await open(temporary, 'w', 0o600);
    try {
      await handle.writeFile(`${JSON.stringify(metadata).slice(0, -1)},"text":"`);
      for (let offset = 0; offset < text.length;) {
        let end = Math.min(offset + 65536, text.length);
        if (end < text.length && /[\uD800-\uDBFF]/.test(text[end - 1])) end--;
        await handle.writeFile(JSON.stringify(text.slice(offset, end)).slice(1, -1));
        offset = end;
      }
      await handle.writeFile('"}\n');
    } finally { await handle.close(); }
  } else await writeFile(temporary, `${JSON.stringify(value)}\n`, { mode: 0o600 });
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
    } catch (error) { progress.error = error.message; await save(true); throw error; }
    progress.pages++;
    progress.nextPageToken = page.nextPageToken || undefined;
    progress.done = !progress.nextPageToken;
    await save();
  }
}

const MAX_DOWNLOAD_BYTES = 64 * 1024 * 1024;
class TooLargeError extends Error {
  constructor(reason) { super(reason); this.code = 'TOO_LARGE'; }
}

export class GoogleReadClient {
  constructor({ accessToken, refreshToken, accountEmail, ignoreTooLarge = false, fetchImpl = fetch, sleep = ms => new Promise(resolve => setTimeout(resolve, ms)) }) {
    this.accountEmail = accountEmail;
    this.ignoreTooLarge = ignoreTooLarge;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.fetch = fetchImpl;
    this.sleep = sleep;
  }

  async validateToken(token) {
    if (!this.accountEmail || this.validatedToken === token) return;
    const info = await this.fetch(`https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(token)}`, {
      method: 'GET', redirect: 'error', signal: AbortSignal.timeout(120000),
    });
    if (!info.ok) { const error = new Error(`Token scope verification failed: HTTP ${info.status}`); error.status = info.status; throw error; }
    const granted = (await info.json()).scope?.split(' ') ?? [];
    if (granted.length !== SCOPES.length || !SCOPES.every(scope => granted.includes(scope))) throw new Error('Token does not have exactly the required read-only scopes');
    const identity = await this.fetch('https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)', {
      method: 'GET', headers: { Authorization: `Bearer ${token}` }, redirect: 'error', signal: AbortSignal.timeout(120000),
    });
    if (!identity.ok) { const error = new Error(`Account identity verification failed: HTTP ${identity.status}`); error.status = identity.status; throw error; }
    if ((await identity.json()).user?.emailAddress?.toLowerCase() !== this.accountEmail.toLowerCase()) throw new Error('Authenticated Google account does not match the configured account');
    this.validatedToken = token;
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
      try { await this.validateToken(token); }
      catch (error) {
        if (error.status === 401 && attempt === 0) { await this.refreshToken(); continue; }
        throw error;
      }
      const response = await this.fetch(url, {
        method: 'GET', headers: { Authorization: `Bearer ${token}` }, redirect: 'error', signal: AbortSignal.timeout(120000),
      });
      if (response.ok) {
        if (!binary) return response.json();
        if (!this.ignoreTooLarge) return Buffer.from(await response.arrayBuffer());
        if (Number(response.headers.get('content-length')) > MAX_DOWNLOAD_BYTES) {
          await response.body?.cancel();
          throw new TooLargeError(`Download exceeds ${MAX_DOWNLOAD_BYTES} bytes`);
        }
        if (!response.body) return Buffer.alloc(0);
        const reader = response.body.getReader();
        const chunks = [];
        let size = 0;
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            size += value.byteLength;
            if (size > MAX_DOWNLOAD_BYTES) {
              await reader.cancel();
              throw new TooLargeError(`Decoded download exceeds ${MAX_DOWNLOAD_BYTES} bytes`);
            }
            chunks.push(value);
          }
          return Buffer.concat(chunks, size);
        } finally { reader.releaseLock(); }
      }
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
    if (file.trashed) return { status: 'metadata', reason: 'Excluded trashed file' };
    if (mime === 'application/vnd.google-apps.folder') return { status: 'metadata', reason: 'Folder' };
    if (mime === 'application/vnd.google-apps.shortcut') return { status: 'metadata', reason: 'Shortcut; target retained in metadata' };
    const exported = EXPORTS[mime];
    const textual = isTextFile(file);
    if (!exported && !textual && !ARCHIVES.has(mime) && mime !== 'application/pdf') {
      return { status: 'unsupported', reason: `No text extractor for ${mime}` };
    }
    validateFileId(file.id);
    let bytes;
    try {
      if (this.ignoreTooLarge && Number(file.size) > MAX_DOWNLOAD_BYTES) throw new TooLargeError(`File size ${file.size} exceeds ${MAX_DOWNLOAD_BYTES} bytes`);
      bytes = exported
        ? await this.get('drive', `files/${file.id}/export`, { mimeType: exported }, true)
        : await this.get('drive', `files/${file.id}`, { alt: 'media', supportsAllDrives: true }, true);
    } catch (error) {
      const tooLarge = error.code === 'TOO_LARGE' || (error.status === 403 && /too large|exportSizeLimitExceeded|export size limit/i.test(error.message));
      if (!this.ignoreTooLarge || !tooLarge) throw error;
      return { status: 'unsupported', ignoredTooLarge: true, reason: error.message, limitBytes: MAX_DOWNLOAD_BYTES };
    }
    const effectiveMime = exported ?? mime;
    if (bytes.subarray(0, 4).toString('ascii') === 'ARQO') return { status: 'unsupported', reason: 'ARQO binary backup container; not JSON plaintext', bytes: bytes.length };
    let text;
    let encoding;
    try {
      if (ARCHIVES.has(effectiveMime) || effectiveMime === 'application/pdf') text = await extractor(bytes, effectiveMime);
      else {
        encoding = bytes[0] === 0xff && bytes[1] === 0xfe ? 'utf-16le' : bytes[0] === 0xfe && bytes[1] === 0xff ? 'utf-16be' : 'utf-8';
        if (encoding === 'utf-8' && bytes.length % 2 === 0) {
          const sample = bytes.subarray(0, 64);
          let evenZeros = 0;
          let oddZeros = 0;
          for (let index = 0; index < sample.length; index++) if (sample[index] === 0) {
            if (index % 2) oddZeros++;
            else evenZeros++;
          }
          if (oddZeros > sample.length / 8 && !evenZeros) encoding = 'utf-16le';
          else if (evenZeros > sample.length / 8 && !oddZeros) encoding = 'utf-16be';
        }
        try {
          text = new TextDecoder(encoding, { fatal: true }).decode(bytes);
          if (text.includes('\u0000')) throw new Error('NUL characters in text');
        } catch (error) {
          if (encoding === 'utf-8' && mime?.startsWith('text/')) {
            const candidate = new TextDecoder('windows-1252', { fatal: true }).decode(bytes);
            if (!/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f-\u009f]/.test(candidate)) {
              text = candidate;
              encoding = 'windows-1252';
            }
          }
          if (encoding !== 'windows-1252') {
            if (!TEXT_MIME.test(mime ?? '')) return { status: 'unsupported', reason: 'Non-text payload despite text-like filename', bytes: bytes.length };
            throw new Error(`Unsupported text encoding: ${error.message}`);
          }
        }
      }
      if (this.ignoreTooLarge && Buffer.byteLength(text, 'utf8') > MAX_DOWNLOAD_BYTES) throw new TooLargeError(`Extracted text exceeds ${MAX_DOWNLOAD_BYTES} bytes`);
    } catch (error) {
      if (!this.ignoreTooLarge || error.code !== 'TOO_LARGE') throw error;
      return { status: 'unsupported', ignoredTooLarge: true, reason: error.message, limitBytes: MAX_DOWNLOAD_BYTES };
    }
    if (effectiveMime === 'application/pdf' && !text.trim()) return { status: 'metadata', reason: 'No extractable PDF text; OCR is outside scope', bytes: bytes.length };
    return { status: 'collected', text, bytes: bytes.length, representation: effectiveMime, encoding };
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
    if (!Object.hasOwn(definition.inputSchema.properties, key) || typeof args[key] !== 'string') throw new Error(`Invalid argument ${key}`);
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
    unavailableTargets: state.unavailableTargets ?? [],
    ignoredTooLarge: Object.values(state.items).filter(item => item.ignoredTooLarge).length,
    ...(state.ignoredTooLargeLog ? { ignoredTooLargeLog: state.ignoredTooLargeLog } : {}),
    documents: Object.values(state.items).filter(item => item.path).map(item => item.path),
    authors: state.service === 'chat' ? {
      people: state.people ?? {},
      unresolvedMessages: Object.values(state.items).filter(item => !item.authorResolved).length,
      placeholderMessages: Object.values(state.items).filter(item => state.people?.[item.userId]?.isAnonymous || state.people?.[item.userId]?.displayName === 'Deleted User').length,
      placeholderIds: Object.values(state.people ?? {}).filter(person => person.isAnonymous || person.displayName === 'Deleted User').map(person => person.id),
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
    state ??= { version: 3, service, account, corpusDirectory: directory, items: {}, pagination: {}, sharedDrives: {}, spaces: {}, failures: [],
      limitations: ['Only content exposed to this account by Google is accessible.', 'Deleted and retention-expired content is excluded.'], startedAt: new Date().toISOString() };
    if (state.service !== service || state.account !== account) throw new Error('Collection manifest account mismatch');
    if (service === 'drive') {
      for (const item of Object.values(state.items)) {
        const legacyText = state.version < 2 && ['collected', 'unsupported'].includes(item.status);
        const newlySupported = item.status === 'unsupported' && item.reason?.startsWith('No text extractor');
        if (!item.ignoredTooLarge && isTextFile(item.metadata) && (legacyText || newlySupported)) {
          item.status = 'pending';
          state.complete = false;
        }
      }
      if (state.version < 3 && client.ignoreTooLarge) {
        for (const [id, item] of Object.entries(state.items)) {
          if (item.status !== 'collected') continue;
          const documentPath = join(directory, 'documents', `${id}.json`);
          if (item.path !== documentPath) throw new Error('Document path escapes corpus');
          if ((await stat(documentPath)).size > MAX_DOWNLOAD_BYTES) { item.status = 'pending'; state.complete = false; }
        }
        state.version = 3;
        await atomicJson(path, state);
      } else state.version = Math.max(state.version, 2);
    }
    if (state.complete) return coverage(state);
    state.failures = [];
    const save = async () => {
      if (service === 'drive' && client.ignoreTooLarge) {
        state.ignoredTooLargeLog = join(directory, 'ignored-too-large.json');
        const files = Object.entries(state.items).filter(([, item]) => item.ignoredTooLarge).map(([id, item]) => ({
          id, name: item.metadata.name, url: item.metadata.webViewLink ?? `https://drive.google.com/file/d/${id}/view`,
          mimeType: item.metadata.mimeType, sizeBytes: item.metadata.size ?? null, reason: item.reason,
        }));
        await atomicJson(state.ignoredTooLargeLog, { account, limitBytes: MAX_DOWNLOAD_BYTES, files });
      }
      await atomicJson(path, state);
    };
    let lastSaved = 0;
    const checkpoint = async (force = false) => {
      if (force || Date.now() - lastSaved >= 5000) { await save(); lastSaved = Date.now(); }
    };
    const documents = join(directory, 'documents');
    await mkdir(documents, { recursive: true, mode: 0o700 });
    if (service === 'drive') {
      const inventory = Object.entries(state.items);
      const acceptFiles = async page => {
        for (const file of page.files ?? []) {
          if (state.items[file.id]) continue;
          const item = state.items[file.id] = { metadata: file, status: 'pending' };
          inventory.push([file.id, item]);
        }
      };
      await paginate(state, 'userFiles', token => client.listFiles({ corpora: 'user', pageToken: token }), acceptFiles, checkpoint);
      await paginate(state, 'sharedDrives', token => client.listDrives({ pageToken: token }), async page => {
        for (const drive of page.drives ?? []) state.sharedDrives[drive.id] = drive;
      }, checkpoint);
      for (const id of Object.keys(state.sharedDrives)) {
        await paginate(state, `drive:${id}`, token => client.listFiles({ corpora: 'drive', driveId: id, pageToken: token }), acceptFiles, checkpoint);
      }
      // Shared folders and shortcut targets can expose files absent from the user's corpus.
      for (let index = 0; index < inventory.length; index++) {
        const [sourceId, item] = inventory[index];
        const targetId = item.metadata.shortcutDetails?.targetId;
        if (targetId && !state.items[targetId]) {
          try {
            const metadata = await client.fileMetadata(targetId);
            if (metadata.trashed) {
              state.unavailableTargets ??= [];
              if (!state.unavailableTargets.some(entry => entry.source === sourceId && entry.shortcutTarget === targetId)) state.unavailableTargets.push({ source: sourceId, shortcutTarget: targetId, reason: 'Excluded trashed target' });
            } else {
              const target = state.items[targetId] = { metadata, status: 'pending' };
              inventory.push([targetId, target]);
            }
          }
          catch (error) {
            const gap = { source: sourceId, shortcutTarget: targetId, error: error.message };
            if (error.status === 404) {
              state.unavailableTargets ??= [];
              if (!state.unavailableTargets.some(entry => entry.source === sourceId && entry.shortcutTarget === targetId)) state.unavailableTargets.push(gap);
            } else state.failures.push(gap);
          }
        }
        if (item.metadata.mimeType === 'application/vnd.google-apps.folder') {
          validateFileId(sourceId);
          const corpus = item.metadata.driveId ? { corpora: 'drive', driveId: item.metadata.driveId } : { corpora: 'user' };
          await paginate(state, `folder:${sourceId}`, token => client.listFiles({ ...corpus, q: `'${sourceId}' in parents and trashed=false`, pageToken: token }), acceptFiles, checkpoint);
        }
      }
      for (const [id, item] of Object.entries(state.items)) {
        if (['collected', 'metadata', 'unsupported'].includes(item.status)) continue;
        try {
          let content;
          const existingPath = join(documents, `${id}.json`);
          try {
            const existing = JSON.parse(await readFile(existingPath, 'utf8'));
            const staleText = isTextFile(item.metadata) && !existing.encoding && !existing.ignoredTooLarge;
            if (!staleText) content = existing;
            if (client.ignoreTooLarge && typeof content?.text === 'string' && Buffer.byteLength(content.text, 'utf8') > MAX_DOWNLOAD_BYTES) {
              const retained = join(directory, 'oversized-captured-documents');
              await mkdir(retained, { recursive: true, mode: 0o700 });
              await link(existingPath, join(retained, `${id}.json`)).catch(error => { if (error.code !== 'EEXIST') throw error; });
              content = { status: 'unsupported', ignoredTooLarge: true, reason: `Previously captured text exceeds ${MAX_DOWNLOAD_BYTES} bytes`, limitBytes: MAX_DOWNLOAD_BYTES,
                bytes: existing.bytes, retainedCapturePath: join(retained, `${id}.json`) };
            }
          } catch (error) { if (error.code !== 'ENOENT') throw error; }
          content ??= await client.fileContent(item.metadata, extractor);
          const doc = { source: item.metadata.webViewLink ?? `https://drive.google.com/file/d/${id}/view`, metadata: item.metadata, ...content };
          item.path = join(documents, `${id}.json`);
          await atomicJson(item.path, doc);
          item.status = content.status;
          item.reason = content.reason;
          item.ignoredTooLarge = content.ignoredTooLarge === true;
          delete item.error;
        } catch (error) { item.status = 'failed'; item.error = error.message; }
        await checkpoint();
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
              if (person?.name && person.displayName) state.people[person.name] = { id: person.name, displayName: person.displayName, email: person.email, type: person.type, isAnonymous: person.isAnonymous };
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

export async function publishCollection(directory, rawRoot, namespace) {
  if (!/^google-[a-z][a-z0-9-]*\/(drive|chat)$/.test(namespace)) throw new Error('Invalid corpus namespace');
  let state;
  try { state = JSON.parse(await readFile(join(directory, 'manifest.json'), 'utf8')); }
  catch (error) { throw new Error(`Collection manifest is unavailable: ${error.message}`); }
  if (!state.complete) throw new Error('Collection must finish before publication');
  const destination = join(rawRoot, namespace);
  const indexPath = join(destination, 'synthesis-index.json');
  try {
    const published = JSON.parse(await readFile(indexPath, 'utf8'));
    if (published.version === 2 && published.sourceFinishedAt === state.finishedAt && published.discovered === Object.keys(state.items).length) return published;
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  await mkdir(join(destination, 'documents'), { recursive: true, mode: 0o700 });
  const batches = [];
  let records = [];
  let batchBytes = 0;
  const flush = async () => {
    if (!records.length) return;
    const path = `${namespace}/batch-${String(batches.length + 1).padStart(6, '0')}.json`;
    await atomicJson(join(rawRoot, path), { account: state.account, service: state.service, records });
    batches.push({ path, records: records.length, sourceIds: [...new Set(records.map(record => record.sourceId))].length });
    records = [];
    batchBytes = 0;
  };
  const addRecord = async record => {
    const bytes = Buffer.byteLength(JSON.stringify(record), 'utf8');
    if (bytes > 74000) throw new Error('Synthesis record exceeds raw reader budget');
    if (batchBytes + bytes > 74000) await flush();
    records.push(record);
    batchBytes += bytes;
  };
  for (const [id, item] of Object.entries(state.items)) {
    if (!item.path || !['collected', 'metadata', 'unsupported'].includes(item.status)) throw new Error(`Unresolved item ${id}`);
    if (item.path !== join(directory, 'documents', basename(item.path))) throw new Error('Document path escapes corpus');
    const destinationPath = join(destination, 'documents', basename(item.path));
    const [sourceStat, targetStat] = await Promise.all([stat(item.path), stat(destinationPath).catch(error => { if (error.code !== 'ENOENT') throw error; return null; })]);
    if (!targetStat || sourceStat.ino !== targetStat.ino || sourceStat.dev !== targetStat.dev) {
      if (targetStat) await rm(destinationPath);
      await link(item.path, destinationPath);
    }
    const raw = await readFile(item.path, 'utf8');
    let document;
    try { document = JSON.parse(raw); } catch (error) { throw new Error(`Invalid collected document ${id}: ${error.message}`); }
    const provenance = { sourceId: id, source: document.source, path: `${namespace}/documents/${basename(item.path)}` };
    if (raw.length <= 10000) await addRecord({ ...provenance, document });
    else {
      let offset = 0;
      let part = 0;
      while (offset < raw.length) {
        let end = Math.min(offset + 10000, raw.length);
        if (end < raw.length && /[\uD800-\uDBFF]/.test(raw[end - 1])) end--;
        await addRecord({ ...provenance, part: ++part, offset, documentFragment: raw.slice(offset, end), finalPart: end === raw.length });
        offset = end;
      }
    }
  }
  await flush();
  const original = coverage(state);
  const { documents: ignoredDocuments, pagination, authors, ...summary } = original;
  void ignoredDocuments;
  const result = { ...summary, version: 2, ...(authors ? { authors } : {}), sourceFinishedAt: state.finishedAt, rawConnectorId: 'custom-mcp', indexPath: `${namespace}/synthesis-index.json`, batches,
    paginationSummary: { total: Object.keys(pagination).length, exhausted: Object.values(pagination).filter(page => page.done && !page.error).length } };
  await atomicJson(indexPath, result);
  return result;
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
  let policy = {};
  try { policy = JSON.parse(await readFile(join(profile, 'collection-policy.json'), 'utf8')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (!policy || typeof policy !== 'object' || Array.isArray(policy) || (policy.ignoreTooLarge !== undefined && typeof policy.ignoreTooLarge !== 'boolean')) throw new Error('Invalid collection policy');
  const client = new GoogleReadClient({ accessToken, refreshToken, accountEmail: email, ignoreTooLarge: policy.ignoreTooLarge === true });
  await client.get('drive', 'about', { fields: 'user(emailAddress)' });
  const extractor = async (bytes, mime) => {
    const result = spawnSync(process.env.OPENWIKI_PYTHON ?? 'python3', [extractorPath, mime], { input: bytes, maxBuffer: client.ignoreTooLarge ? MAX_DOWNLOAD_BYTES : 256 * 1024 * 1024, timeout: 600000 });
    if (client.ignoreTooLarge && result.error?.code === 'ENOBUFS') throw new TooLargeError(`Extracted text exceeds ${MAX_DOWNLOAD_BYTES} bytes`);
    if (client.ignoreTooLarge && result.status !== 0 && /Expanded office archive exceeds extraction memory budget/.test(result.stderr?.toString() ?? '')) throw new TooLargeError(result.stderr.toString().trim());
    if (result.error || result.status !== 0) throw new Error(`Text extraction failed: ${result.error?.message ?? result.stderr.toString().slice(0,500)}`);
    return result.stdout.toString('utf8');
  };
  const directory = join(root, 'connectors', `google-${account}`, service);
  return { client, extractor, collect: () => collectSource(client, service, email, directory, extractor),
    status: () => publishCollection(directory, join(root, 'connectors', 'custom-mcp', 'raw'), `google-${account}/${service}`) };
}

async function main() {
  const [mode, account, email, service, extractorPath] = process.argv.slice(2);
  const root = process.env.OPENWIKI_PERSONAL_ROOT ?? join(homedir(), '.openwiki');
  const context = await makeContext(account, email, service, root, extractorPath);
  if (mode === 'verify') {
    await context.client.refreshToken();
    await context.client.validateToken(await context.client.accessToken());
    console.log(JSON.stringify({ account: email, scopes: SCOPES, tools: TOOL_NAMES[service], refreshed: true }));
    return;
  }
  if (mode === 'collect') { console.log(JSON.stringify(await context.collect())); return; }
  if (mode === 'publish') { console.log(JSON.stringify(await context.status())); return; }
  if (mode !== 'serve') throw new Error('Expected serve, verify, collect, or publish');
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
