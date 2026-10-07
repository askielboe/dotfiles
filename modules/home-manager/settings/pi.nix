{ ... }:
{
  programs.pi.coding-agent.enable = true;

  home.file = {
    ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
    ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
  };
}
