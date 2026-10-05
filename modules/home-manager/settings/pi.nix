{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = [ pkgs.pi ];

    file.".pi/agent/AGENTS.md".text = config.home.file.".codex/AGENTS.md".text;

    # Pi edits these files itself; preserve runtime choices outside the managed defaults.
    activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" "codexFullAccess" ] ''
      ${pkgs.python3}/bin/python3 ${./pi-migrate.py}
    '';
  };
}
