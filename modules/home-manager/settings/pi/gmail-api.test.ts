import { test, expect } from 'bun:test';
import { GmailClient, tools, existingClient } from './gmail-api.ts';

const email = 'askielboe@hccreators.com';
function client(fetchImpl, refresh = async () => {}) {
  return new GmailClient({ email, token: async () => 'test-token', refresh, fetchImpl });
}
test('only read operations are exposed', async () => {
  expect(tools.every(tool => tool.annotations.readOnlyHint)).toBe(true);
  const api = client(() => { throw new Error('Unexpected request'); });
  await expect(api.call('send_message', {})).rejects.toThrow('not exposed');
});
test('unconfigured account pairs are rejected before credential access', async () => {
  await expect(existingClient('gmail-mo2tion', 'askielboe@hccreators.com')).rejects.toThrow('Unconfigured');
  await expect(existingClient('gmail-other', 'andreas@mo2tion.com')).rejects.toThrow('Unconfigured');
  await expect(existingClient('toString', 'andreas@mo2tion.com')).rejects.toThrow('Unconfigured');
});
test('mo2tion identity is verified before standard API reads', async () => {
  const requests = [];
  const api = new GmailClient({
    email: 'andreas@mo2tion.com', token: async () => 'test-token', refresh: async () => {},
    fetchImpl: async (url, options) => {
      requests.push({ url: String(url), method: options.method });
      return Response.json(requests.length === 1 ? { emailAddress: 'andreas@mo2tion.com' } : { threads: [{ id: 'abc' }] });
    },
  });
  expect(await api.call('search_threads', { query: 'billing' })).toEqual({ threads: [{ id: 'abc' }] });
  expect(requests.every(request => request.method === 'GET')).toBe(true);
  expect(requests[1].url).toContain('gmail.googleapis.com/gmail/v1/users/me/threads?');
});
test('account identity is checked before reading threads', async () => {
  const api = client(async () => Response.json({ emailAddress: 'other@example.com' }));
  await expect(api.call('search_threads', {})).rejects.toThrow('differs');
});
test('thread searches use standard Gmail API GET', async () => {
  const requests = [];
  const api = client(async (url, options) => {
    requests.push({ url: String(url), method: options.method });
    return Response.json(requests.length === 1 ? { emailAddress: email } : { threads: [{ id: 'abc' }] });
  });
  expect(await api.call('search_threads', { query: 'subject:ClubPlanner', pageSize: 5 })).toEqual({ threads: [{ id: 'abc' }] });
  expect(requests[1].url).toContain('gmail.googleapis.com/gmail/v1/users/me/threads?');
  expect(requests[1].method).toBe('GET');
});
test('401 refreshes once', async () => {
  let requests = 0, refreshes = 0;
  const api = client(async () => ++requests === 1 ? new Response('', { status: 401 }) : Response.json({ emailAddress: email }), async () => { refreshes++; });
  await api.verify();
  expect(refreshes).toBe(1);
  expect(requests).toBe(2);
});
test('invalid arguments and identifiers are rejected', async () => {
  const api = client(() => { throw new Error('Unexpected request'); });
  await expect(api.call('get_message', { messageId: '../send' })).rejects.toThrow('Invalid identifier');
  await expect(api.call('search_threads', { pageSize: 51 })).rejects.toThrow('pageSize');
  await expect(api.call('get_thread', { threadId: 'abc', extra: true })).rejects.toThrow('Invalid argument');
});
test('attachment filenames cannot escape the private directory', async () => {
  const api = client(async () => Response.json({ emailAddress: email }));
  await expect(api.call('download_attachment', { messageId: 'abc', attachmentId: 'def', filename: '../private.txt' })).rejects.toThrow('Invalid attachment filename');
});
