{ ... }:
{
  programs.pi.coding-agent.enable = true;
  programs.pi.coding-agent.settings = {
    packages = [ "npm:pi-messenger" ];
    messenger.autoRegister = true;
  };

  home.file = {
    ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
    ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
  };
}
