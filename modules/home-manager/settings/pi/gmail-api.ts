import { readFile, mkdtemp, writeFile } from 'node:fs/promises';
import { homedir, tmpdir } from 'node:os';
import { join, basename } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const accounts = {
  'gmail-hccreators': 'askielboe@hccreators.com',
  'gmail-mo2tion': 'andreas@mo2tion.com',
};
const id = { type: 'string', pattern: '^[A-Za-z0-9_-]+$' };
const schema = (properties, required = []) => ({ type: 'object', properties, required, additionalProperties: false });
export const tools = [
  { name: 'get_profile', description: 'Verify the authenticated Gmail account.', inputSchema: schema({}) },
  { name: 'search_threads', description: 'Search Gmail threads using Gmail query syntax.', inputSchema: schema({ query: { type: 'string' }, pageToken: { type: 'string' }, pageSize: { type: 'integer', minimum: 1, maximum: 50 } }) },
  { name: 'get_thread', description: 'Read the complete messages and attachment metadata in a thread.', inputSchema: schema({ threadId: id }, ['threadId']) },
  { name: 'get_message', description: 'Read a message and its attachment metadata.', inputSchema: schema({ messageId: id }, ['messageId']) },
  { name: 'download_attachment', description: 'Save an attachment to a private temporary file for local review.', inputSchema: schema({ messageId: id, attachmentId: id, filename: { type: 'string' } }, ['messageId', 'attachmentId', 'filename']) },
].map(tool => ({ ...tool, annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: true } }));

export class GmailClient {
  constructor({ email, token, refresh, fetchImpl = fetch }) {
    this.email = email;
    this.token = token;
    this.refresh = refresh;
    this.fetch = fetchImpl;
  }
  async get(path, query = {}) {
    const url = new URL(path, 'https://gmail.googleapis.com/gmail/v1/users/me/');
    if (!url.href.startsWith('https://gmail.googleapis.com/gmail/v1/users/me/')) throw new Error('Invalid Gmail resource');
    for (const [key, value] of Object.entries(query)) if (value !== undefined) url.searchParams.set(key, String(value));
    for (let attempt = 0; attempt < 2; attempt++) {
      const response = await this.fetch(url, { method: 'GET', headers: { Authorization: `Bearer ${await this.token()}` }, redirect: 'error', signal: AbortSignal.timeout(60000) });
      if (response.status === 401 && attempt === 0) { await this.refresh(); continue; }
      if (!response.ok) throw new Error(`Gmail API HTTP ${response.status}`);
      return response.json();
    }
    throw new Error('Gmail authentication failed');
  }
  async verify() {
    const profile = await this.get('profile');
    if (profile.emailAddress?.toLowerCase() !== this.email.toLowerCase()) throw new Error('Authenticated Gmail account differs from configured account');
    return profile;
  }
  async call(name, args) {
    const tool = tools.find(tool => tool.name === name);
    if (!tool) throw new Error('Unsupported Gmail operation; sending is not exposed');
    if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('Invalid arguments');
    for (const [key, value] of Object.entries(args)) {
      const definition = tool.inputSchema.properties[key];
      if (!definition || (definition.type === 'integer' ? !Number.isInteger(value) : typeof value !== definition.type)) throw new Error(`Invalid argument ${key}`);
      if (definition.pattern && !new RegExp(definition.pattern).test(value)) throw new Error(`Invalid identifier ${key}`);
    }
    for (const key of tool.inputSchema.required) if (!args[key]) throw new Error(`Missing ${key}`);
    if (args.pageSize !== undefined && (args.pageSize < 1 || args.pageSize > 50)) throw new Error('pageSize must be between 1 and 50');
    const profile = await this.verify();
    switch (name) {
      case 'get_profile': return profile;
      case 'search_threads': return this.get('threads', { q: args.query, pageToken: args.pageToken, maxResults: args.pageSize ?? 20 });
      case 'get_thread': return this.get(`threads/${args.threadId}`, { format: 'full' });
      case 'get_message': return this.get(`messages/${args.messageId}`, { format: 'full' });
      case 'download_attachment': {
        if (basename(args.filename) !== args.filename || /[\\/\x00-\x1f]/.test(args.filename) || ['.', '..'].includes(args.filename)) throw new Error('Invalid attachment filename');
        const attachment = await this.get(`messages/${args.messageId}/attachments/${args.attachmentId}`);
        if (typeof attachment.data !== 'string') throw new Error('Attachment data missing');
        const directory = await mkdtemp(join(tmpdir(), 'gmail-review-'));
        const path = join(directory, args.filename);
        const bytes = Buffer.from(attachment.data, 'base64url');
        if (bytes.length !== attachment.size) throw new Error('Attachment size mismatch');
        await writeFile(path, bytes, { mode: 0o600 });
        return { path, bytes: bytes.length };
      }
      default: throw new Error('Unsupported Gmail operation');
    }
  }
}

export async function existingClient(serverName, email) {
  if (!Object.hasOwn(accounts, serverName) || accounts[serverName] !== email) throw new Error('Unconfigured Gmail account');
  const agentDir = join(homedir(), '.pi/agent');
  const auth = await import(pathToFileURL(join(agentDir, 'npm/node_modules/pi-mcp-adapter/mcp-auth.ts')).href);
  const entry = () => {
    const value = auth.getAuthEntry(serverName);
    if (!value?.tokens?.accessToken) throw new Error('Gmail OAuth credentials are missing; standard Google OAuth sign-in is required');
    return value;
  };
  const refresh = async () => {
    const old = entry();
    if (!old.tokens.refreshToken) throw new Error('Gmail refresh token is missing; Google OAuth sign-in is required');
    let credentials;
    try { credentials = JSON.parse(await readFile(join(agentDir, 'credentials/google-workspace-oauth.json'), 'utf8')).installed; }
    catch { throw new Error('Google OAuth client credentials could not be read'); }
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST', redirect: 'error', signal: AbortSignal.timeout(30000),
      body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: old.tokens.refreshToken, client_id: credentials.client_id, client_secret: credentials.client_secret }),
    });
    if (!response.ok) throw new Error(`Google OAuth refresh HTTP ${response.status}`);
    const result = await response.json();
    if (!result.access_token || !Number.isFinite(result.expires_in)) throw new Error('Invalid Google OAuth token response');
    auth.updateTokens(serverName, { ...old.tokens, accessToken: result.access_token, refreshToken: result.refresh_token ?? old.tokens.refreshToken, expiresAt: Math.floor(Date.now() / 1000) + result.expires_in, scope: result.scope ?? old.tokens.scope }, old.serverUrl);
  };
  const token = async () => {
    if (entry().tokens.expiresAt <= Date.now() / 1000 + 60) await refresh();
    return entry().tokens.accessToken;
  };
  return new GmailClient({ email, token, refresh });
}

if (import.meta.main) {
  const [serverName, email] = process.argv.slice(2);
  const require = createRequire(join(homedir(), '.pi/agent/npm/package.json'));
  const { Server } = await import(require.resolve('@modelcontextprotocol/sdk/server/index.js'));
  const { StdioServerTransport } = await import(require.resolve('@modelcontextprotocol/sdk/server/stdio.js'));
  const { ListToolsRequestSchema, CallToolRequestSchema } = await import(require.resolve('@modelcontextprotocol/sdk/types.js'));
  const client = await existingClient(serverName, email);
  const server = new Server({ name: 'gmail-api', version: '1.0.0' }, { capabilities: { tools: {} } });
  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));
  server.setRequestHandler(CallToolRequestSchema, async request => {
    try { return { content: [{ type: 'text', text: JSON.stringify(await client.call(request.params.name, request.params.arguments ?? {})) }] }; }
    catch (error) { return { isError: true, content: [{ type: 'text', text: error.message }] }; }
  });
  await server.connect(new StdioServerTransport());
}
