import { randomUUID } from "node:crypto";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let turnId = randomUUID();

  pi.on("before_agent_start", () => {
    turnId = randomUUID();
  });

  pi.on("tool_call", (event, ctx) => {
    let args = event.input;
    if (/^mcp__(node_repl|cua_repl)$/.test(event.toolName)) {
      args = (event.input.args ??= {}) as Record<string, unknown>;
    } else if (
      event.toolName === "mcp" && typeof event.input.tool === "string" &&
      (/^(?:mcp__)?(node_repl|cua_repl)(?:__|_)/.test(event.input.tool) ||
        ["node_repl", "cua_repl"].includes(event.input.server as string))
    ) {
      if (typeof event.input.args === "string") event.input.args = JSON.parse(event.input.args);
      args = (event.input.args ??= {}) as Record<string, unknown>;
    } else if (!/^mcp__(node_repl|cua_repl)__/.test(event.toolName)) return;

    if (typeof args.code !== "string") return;
    const metadata = {
      session_id: ctx.sessionManager.getSessionId(),
      turn_id: turnId,
      call_id: event.toolCallId,
      ...(ctx.model ? { model: ctx.model.id } : {}),
    };
    // A code comment survives strict argument validation; the proxy removes it before execution.
    args.code = `/*__piCodexMetadata:${Buffer.from(JSON.stringify(metadata)).toString("base64")}*/\n${args.code}`;
  });
}
