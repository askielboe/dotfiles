import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const [command, ...args] = process.argv.slice(2);
if (!command) throw new Error("Expected an MCP server command");
const child = spawn(command, args, { stdio: ["pipe", "pipe", "inherit"] });
const input = createInterface({ input: process.stdin });
const output = createInterface({ input: child.stdout });
const calls = new Map();
const pending = new Map();
const approvals = new Map();
let sessionId;
let generation = 0;

function appConsent(message) {
  const params = message.params;
  const meta = params?._meta;
  const schema = params?.requestedSchema;
  const app = meta?.tool_params?.app;
  const display = meta?.tool_params_display;
  const call = [...calls.values()].find((call) => call.callId === meta?.tool_call_id);
  if (
    message.method !== "elicitation/create" ||
    message.id === undefined ||
    params?.mode !== "form" ||
    meta?.codex_approval_kind !== "mcp_tool_call" ||
    meta.connector_id !== "computer-use" ||
    meta.connector_name !== "Computer Use" ||
    meta.codex_request_type !== undefined ||
    !Array.isArray(meta.persist) || !meta.persist.includes("session") ||
    !["low", "high"].includes(meta.riskLevel) ||
    (meta.subtitle !== undefined && typeof meta.subtitle !== "string") ||
    typeof meta.tool_name !== "string" || meta.tool_name === "start_audio_recording" ||
    typeof app !== "string" || !/^[\w-]+(?:\.[\w-]+)+$/.test(app) ||
    Object.keys(meta.tool_params).length !== 1 ||
    !Array.isArray(display) || display.length !== 1 ||
    display[0]?.name !== "app" || display[0]?.display_name !== "App" ||
    typeof display[0].value !== "string" ||
    params.message !== `Allow Computer Use to use "${display[0].value}"?` ||
    schema?.type !== "object" || !schema.properties ||
    Object.keys(schema.properties).length !== 0 ||
    (schema.required !== undefined && (!Array.isArray(schema.required) || schema.required.length !== 0)) ||
    !call || call.generation !== generation || !sessionId ||
    meta["x-codex-turn-metadata"]?.session_id !== sessionId
  ) return;

  // A changed warning must not inherit consent to a less risky request.
  return { app, scope: JSON.stringify([meta.riskLevel, meta.subtitle ?? null, schema]), generation };
}

async function forwardOutput() {
  for await (const line of output) {
    const message = JSON.parse(line);
    const consent = appConsent(message);
    if (consent) {
      if (approvals.get(consent.app) === consent.scope) {
        child.stdin.write(`${JSON.stringify({
          jsonrpc: "2.0", id: message.id,
          result: {
            action: "accept",
            content: { source: "computer-use-persisted-state", scope: "session" },
            _meta: { persist: "session" },
          },
        })}\n`);
        continue;
      }
      pending.set(message.id, consent);
    }
    if (message.result !== undefined || message.error !== undefined) calls.delete(message.id);
    if (!process.stdout.write(`${line}\n`)) {
      await new Promise((resolve) => process.stdout.once("drain", resolve));
    }
  }
}
forwardOutput().catch((error) => {
  console.error(error.message);
  child.kill();
});
child.on("error", (error) => {
  console.error(error.message);
  process.exit(1);
});
child.on("exit", (code, signal) => {
  process.exit(code ?? (signal ? 1 : 0));
});
for (const signal of ["SIGTERM", "SIGINT"]) {
  process.on(signal, () => child.kill(signal));
}
process.on("exit", () => child.kill());

for await (const line of input) {
  const message = JSON.parse(line);
  if (message.method === "tools/call") {
    const params = message.params;
    const code = params.arguments?.code;
    const prefix = typeof code === "string" && /^\/\*__piCodexMetadata:([A-Za-z0-9+/=]+)\*\/\n/.exec(code);
    if (prefix) {
      const metadata = JSON.parse(Buffer.from(prefix[1], "base64").toString("utf8"));
      params.arguments.code = code.slice(prefix[0].length);
      // Transport metadata must not become a model-visible tool argument.
      params._meta = {
        ...params._meta,
        "x-codex-turn-metadata": params._meta?.["x-codex-turn-metadata"] ?? metadata,
      };
    }
  }
  if (message.method === "tools/call") {
    const metadata = message.params._meta?.["x-codex-turn-metadata"];
    const nextSessionId = metadata?.session_id;
    if (nextSessionId !== undefined && nextSessionId !== sessionId) {
      sessionId = nextSessionId;
      generation++;
      approvals.clear();
      pending.clear();
      calls.clear();
    }
    if (typeof metadata?.call_id === "string" && metadata.call_id && typeof nextSessionId === "string" && nextSessionId) {
      calls.set(message.id, { generation, callId: metadata.call_id });
    }
  }
  const consent = pending.get(message.id);
  if (consent && message.method === undefined) {
    pending.delete(message.id);
    if (consent.generation === generation) {
      const result = message.result;
      if (result?.action === "accept" && result.content && typeof result.content === "object" &&
        !Array.isArray(result.content) && Object.keys(result.content).length === 0) {
        approvals.set(consent.app, consent.scope);
      } else {
        approvals.delete(consent.app);
      }
    }
  }
  if (!child.stdin.write(`${JSON.stringify(message)}\n`)) {
    await new Promise((resolve) => child.stdin.once("drain", resolve));
  }
}
child.stdin.end();
