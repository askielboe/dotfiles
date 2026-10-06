import assert from "node:assert/strict";
import test from "node:test";
import metadataExtension from "./codex-metadata.ts";

function setup() {
  const handlers = new Map();
  metadataExtension({ on: (name, handler) => handlers.set(name, handler) });
  const context = { sessionManager: { getSessionId: () => "session-a" }, model: { id: "model-a" } };
  return { handlers, context };
}

for (const [toolName, input, nested] of [
  ["mcp__cua_repl__js", { code: "example" }, false],
  ["mcp__node_repl__js", { code: "example" }, false],
  ["mcp__cua_repl", { tool: "js", args: { code: "example" } }, true],
  ["mcp__node_repl", { tool: "js", args: { code: "example" } }, true],
  ["mcp", { tool: "cua_repl_js", args: { code: "example" } }, true],
  ["mcp", { tool: "mcp__node_repl__js", args: '{"code":"example"}' }, true],
  ["mcp", { server: "cua_repl", tool: "js", args: { code: "example" } }, true],
]) {
  test(`metadata reaches server arguments via ${toolName} (${input.tool ?? "direct"})`, () => {
    const { handlers, context } = setup();
    const event = { toolName, toolCallId: "call-a", input: structuredClone(input) };
    handlers.get("tool_call")(event, context);
    const args = nested ? event.input.args : event.input;
    assert.deepEqual(Object.keys(args), ["code"]);
    const prefix = /^\/\*__piCodexMetadata:([A-Za-z0-9+/=]+)\*\/\n/.exec(args.code);
    assert.ok(prefix);
    assert.equal(args.code.slice(prefix[0].length), "example");
    const metadata = JSON.parse(Buffer.from(prefix[1], "base64").toString("utf8"));
    assert.equal(metadata.session_id, "session-a");
    assert.equal(metadata.call_id, "call-a");
    assert.equal(metadata.model, "model-a");
    assert.equal(typeof metadata.turn_id, "string");
    assert.equal(event.input.__piCodexMetadata, undefined);
  });
}

test("unrelated tools are unchanged", () => {
  const { handlers, context } = setup();
  for (const event of [
    { toolName: "bash", input: { command: "true" } },
    { toolName: "mcp__bear", input: { tool: "search" } },
    { toolName: "mcp", input: { tool: "bear_search", args: {} } },
    { toolName: "mcp", input: { search: "cua_repl js" } },
  ]) {
    const original = structuredClone(event);
    handlers.get("tool_call")(event, context);
    assert.deepEqual(event, original);
  }
});

test("turn changes do not change session identity", () => {
  const { handlers, context } = setup();
  const call = () => {
    const event = { toolName: "mcp__cua_repl__js", toolCallId: "call-a", input: { code: "example" } };
    handlers.get("tool_call")(event, context);
    const prefix = /^\/\*__piCodexMetadata:([A-Za-z0-9+/=]+)\*\/\n/.exec(event.input.code);
    return JSON.parse(Buffer.from(prefix[1], "base64").toString("utf8"));
  };
  const first = call();
  handlers.get("before_agent_start")();
  const second = call();
  assert.equal(first.session_id, second.session_id);
  assert.notEqual(first.turn_id, second.turn_id);
});
