import { randomUUID } from "node:crypto";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  let turnId = randomUUID();

  pi.on("before_agent_start", () => {
    turnId = randomUUID();
  });

  pi.on("tool_call", (event, ctx) => {
    if (!/^mcp__(node_repl|cua_repl)__/.test(event.toolName)) return;

    // The Codex browser bridge requires correlation IDs even outside Codex.
    event.input.__piCodexMetadata = {
      session_id: ctx.sessionManager.getSessionId(),
      turn_id: turnId,
      call_id: event.toolCallId,
      ...(ctx.model ? { model: ctx.model.id } : {}),
    };
  });
}
