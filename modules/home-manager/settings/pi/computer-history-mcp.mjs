import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const [codex] = process.argv.slice(2);
if (!codex) throw new Error("Expected the Codex CLI executable");

// Codex authenticates native clients; direct launches lack that process authentication.
const child = spawn(codex, ["app-server", "--listen", "stdio://"], {
  stdio: ["pipe", "pipe", "inherit"],
});
const pending = new Map();
const elicitations = new Map();
let sequence = 0;
let ready;
let threadId;
let tools;
let closed = false;
const input = createInterface({ input: process.stdin });
const output = createInterface({ input: child.stdout });

function emit(message) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", ...message })}\n`);
}
function send(message) {
  child.stdin.write(`${JSON.stringify(message)}\n`);
}
function request(method, params) {
  if (closed) return Promise.reject(new Error("Codex app-server is closed"));
  const id = ++sequence;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      stop(new Error(`Codex app-server request timed out: ${method}`));
    }, 110_000);
    pending.set(id, { resolve, reject, timer });
    send({ id, method, params });
  });
}
function stop(error) {
  if (closed) return;
  closed = true;
  for (const call of pending.values()) {
    clearTimeout(call.timer);
    call.reject(error);
  }
  pending.clear();
  elicitations.clear();
  child.kill();
}
async function initialize(params) {
  await request("initialize", {
    clientInfo: { name: "pi-computer-history", version: "1" },
    capabilities: {
      experimentalApi: true,
      extensions: params.capabilities ?? {},
    },
  });
  send({ method: "initialized" });
  const result = await request("thread/start", {
    ephemeral: true,
    cwd: process.cwd(),
    sandbox: "read-only",
    approvalPolicy: "on-request",
  });
  threadId = result.thread.id;
  const inventory = await request("mcpServerStatus/list", {
    threadId,
    serverName: "computer-history",
    detail: "toolsAndAuthOnly",
  });
  const server = inventory.data.find((item) => item.name === "computer-history");
  if (!server || server.toolsError) {
    throw new Error(server?.toolsError ?? "Computer History plugin is unavailable in Codex");
  }
  tools = Object.values(server.tools);
  return {
    protocolVersion: params.protocolVersion,
    capabilities: { tools: {} },
    serverInfo: { name: "Computer History (Codex bridge)", version: "1" },
  };
}
async function handle(message) {
  if (message.method === undefined) {
    const id = elicitations.get(message.id);
    if (id !== undefined) {
      elicitations.delete(message.id);
      send(message.error ? { id, error: message.error } : { id, result: message.result });
    }
    return;
  }
  if (message.id === undefined) return;
  try {
    let result;
    if (message.method === "initialize") {
      if (ready) throw new Error("Bridge is already initialized");
      ready = initialize(message.params);
      result = await ready;
    } else if (message.method === "ping") {
      result = {};
    } else {
      if (!ready) throw new Error("Bridge is not initialized");
      await ready;
      switch (message.method) {
        case "tools/list":
          result = { tools };
          break;
        case "tools/call":
          if (!tools.some((tool) => tool.name === message.params.name)) {
            throw new Error("Unknown Computer History tool");
          }
          {
            const params = {
              threadId,
              server: "computer-history",
              tool: message.params.name,
              arguments: message.params.arguments ?? {},
            };
            if (message.params._meta !== undefined) params._meta = message.params._meta;
            result = await request("mcpServer/tool/call", params);
          }
          break;
        default:
          emit({ id: message.id, error: { code: -32601, message: "Method not found" } });
          return;
      }
    }
    emit({ id: message.id, result });
  } catch (error) {
    emit({ id: message.id, error: { code: -32603, message: error.message } });
  }
}
output.on("line", (line) => {
  try {
    const message = JSON.parse(line);
    if (message.method && message.id !== undefined) {
      if (message.method === "mcpServer/elicitation/request" &&
          message.params.serverName === "computer-history" && message.params.threadId === threadId) {
        const { serverName, threadId: sourceThread, turnId, ...params } = message.params;
        const id = `history-approval-${++sequence}`;
        elicitations.set(id, message.id);
        emit({ id, method: "elicitation/create", params });
      } else {
        send({ id: message.id, error: { code: -32601, message: "Unsupported server request" } });
      }
      return;
    }
    const call = pending.get(message.id);
    if (!call) return;
    pending.delete(message.id);
    clearTimeout(call.timer);
    if (message.error) call.reject(new Error(message.error.message));
    else call.resolve(message.result);
  } catch (error) {
    stop(error);
  }
});
input.on("line", (line) => {
  try {
    void handle(JSON.parse(line));
  } catch (error) {
    emit({ id: null, error: { code: -32700, message: "Invalid JSON" } });
  }
});
input.on("close", () => stop(new Error("MCP client disconnected")));
child.on("error", (error) => {
  stop(error);
  process.exitCode = 1;
  input.close();
});
child.on("exit", (code) => {
  stop(new Error("Codex app-server exited"));
  process.exitCode = code ?? 1;
  input.close();
});
for (const signal of ["SIGTERM", "SIGINT"]) {
  process.on(signal, () => {
    stop(new Error(`Bridge received ${signal}`));
    input.close();
  });
}
process.on("exit", () => child.kill());
