{
  config,
  pkgs,
  ...
}:
{
  home = {
    packages = [ pkgs.pi ];

    file.".pi/agent/AGENTS.md".text = config.home.file.".codex/AGENTS.md".text;
  };
}
