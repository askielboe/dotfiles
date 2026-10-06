{
  config,
  pkgs,
  ...
}:
{
  home = {
    packages = [ pkgs.pi ];

    file = {
      ".pi/agent/AGENTS.md".text = config.home.file.".codex/AGENTS.md".text;
      ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
      ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
    };
  };
}
