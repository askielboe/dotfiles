import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import test from "node:test";

const proxy = new URL("./codex-mcp-proxy.mjs", import.meta.url).pathname;
const backend = `
import { createInterface } from "node:readline";
let id = 1000;
const pending = new Map();
const send = (message) => process.stdout.write(JSON.stringify(message) + "\\n");
function prompt(call) {
  const args = call.params.arguments;
  const app = args.app ?? "com.haystacksoftware.Arq";
  const name = args.displayName ?? "Arq";
  const metadata = call.params._meta?.["x-codex-turn-metadata"];
  const request = {
    jsonrpc: "2.0", id: id++, method: "elicitation/create",
    params: {
      mode: "form", message: 'Allow Computer Use to use "' + name + '"?',
      requestedSchema: { type: "object", properties: {} },
      _meta: {
        codex_approval_kind: "mcp_tool_call", connector_id: "computer-use",
        connector_name: "Computer Use", persist: ["session", "always"], riskLevel: "low",
        tool_call_id: metadata?.call_id, tool_name: "get_app_state",
        tool_params: { app }, tool_params_display: [{ name: "app", display_name: "App", value: name }],
        "x-codex-turn-metadata": metadata, ...args.meta,
      },
      ...args.params,
    },
  };
  pending.set(request.id, call);
  send(request);
}
for await (const line of createInterface({ input: process.stdin })) {
  const message = JSON.parse(line);
  if (message.method === "tools/call") {
    message.decisions = [];
    prompt(message);
  } else if (pending.has(message.id)) {
    const call = pending.get(message.id);
    pending.delete(message.id);
    call.decisions.push(message.result ?? message.error);
    if (call.decisions.length < (call.params.arguments.requests ?? 1)) prompt(call);
    else send({ jsonrpc: "2.0", id: call.id, result: { decisions: call.decisions, params: call.params } });
  }
}
`;

function client(t) {
  const child = spawn(process.execPath, [proxy, process.execPath, "--input-type=module", "-e", backend]);
  const lines = createInterface({ input: child.stdout })[Symbol.asyncIterator]();
  let stderr = "";
  child.stderr.on("data", (data) => { stderr += data; });
  t.after(() => { child.kill(); assert.equal(stderr, ""); });
  let id = 1;
  const send = (message) => child.stdin.write(`${JSON.stringify(message)}\n`);
  async function next() {
    let timer;
    try {
      const line = await Promise.race([
        lines.next(),
        new Promise((_, reject) => { timer = setTimeout(() => reject(new Error(`Proxy timed out: ${stderr}`)), 3000); }),
      ]);
      assert.equal(line.done, false);
      return JSON.parse(line.value);
    } finally { clearTimeout(timer); }
  }
  return {
    send, next,
    call(args = {}, session = "session-a", turn = "turn-a") {
      const callId = id++;
      send({
        jsonrpc: "2.0", id: callId, method: "tools/call",
        params: {
          name: "js", arguments: {
            ...args,
            code: (session === null ? "" : `/*__piCodexMetadata:${Buffer.from(JSON.stringify({
              session_id: session, turn_id: turn, call_id: `call-${callId}`,
            })).toString("base64")}*/\n`) + (args.code ?? "example"),
          },
        },
      });
      return next();
    },
    async answer(request, result = { action: "accept", content: {} }) {
      assert.equal(request.method, "elicitation/create");
      send({ jsonrpc: "2.0", id: request.id, result });
      return next();
    },
  };
}

test("one app approval covers repeated operations and turns, preserving transport metadata", async (t) => {
  const c = client(t);
  const first = await c.call({ requests: 3 });
  const result = await c.answer(first);
  assert.equal(result.result.decisions.length, 3);
  assert.deepEqual(result.result.decisions[0], { action: "accept", content: {} });
  for (const decision of result.result.decisions.slice(1)) {
    assert.equal(decision.action, "accept");
    assert.equal(decision.content.scope, "session");
    assert.equal(decision._meta.persist, "session");
  }
  assert.equal(result.result.params.arguments.code, "example");
  assert.deepEqual(Object.keys(result.result.params.arguments).sort(), ["code", "requests"]);
  assert.equal(result.result.params._meta["x-codex-turn-metadata"].session_id, "session-a");
  const second = await c.call({}, "session-a", "turn-b");
  assert.equal(second.method, undefined);
  assert.equal(second.result.decisions[0].content.source, "computer-use-persisted-state");
});

test("different apps, changed warnings, and new sessions prompt again", async (t) => {
  const c = client(t);
  await c.answer(await c.call());
  await c.answer(await c.call({ app: "com.apple.TextEdit", displayName: "TextEdit" }));
  assert.equal((await c.call()).method, undefined);
  await c.answer(await c.call({ meta: { riskLevel: "high", subtitle: "New warning" } }));
  await c.answer(await c.call({}, "session-b"));
  await c.answer(await c.call({}, "session-a"));
});

for (const action of ["decline", "cancel"]) {
  test(`${action} is not cached`, async (t) => {
    const c = client(t);
    await c.answer(await c.call(), { action });
    await c.answer(await c.call(), { action });
  });
}

const unrelated = [
  { meta: { connector_id: "other-connector" } },
  { meta: { codex_request_type: "approval_request" } },
  { meta: { tool_name: "start_audio_recording" } },
  { meta: { tool_params: {} } },
  { meta: { tool_params: { app: "com.haystacksoftware.Arq", operation: "delete" } } },
  { meta: { persist: ["always"] } },
  { meta: { tool_call_id: "unknown-call" } },
  { meta: { "x-codex-turn-metadata": { session_id: "other-session" } } },
  { params: { message: "Send this email?" } },
  { params: { mode: "url", url: "https://example.com" } },
  { params: { requestedSchema: { type: "object", properties: { confirm: { type: "boolean" } } } } },
];
for (const [index, args] of unrelated.entries()) {
  test(`unrelated or uncorrelated request ${index + 1} always passes through`, async (t) => {
    const c = client(t);
    await c.answer(await c.call());
    await c.answer(await c.call(args));
    await c.answer(await c.call(args));
  });
}

test("a pending approval cannot cross a session change", async (t) => {
  const c = client(t);
  const oldRequest = await c.call();
  const newRequest = await c.call({}, "session-b");
  await c.answer(oldRequest);
  await c.answer(newRequest, { action: "decline" });
  await c.answer(await c.call({}, "session-b"));
});

test("missing session metadata never creates reusable consent", async (t) => {
  const c = client(t);
  await c.answer(await c.call({}, null));
  await c.answer(await c.call({}, null));
});

test("an elicitation error never grants consent", async (t) => {
  const c = client(t);
  const request = await c.call();
  c.send({ jsonrpc: "2.0", id: request.id, error: { code: -32603, message: "Failed" } });
  await c.next();
  await c.answer(await c.call());
});
