{ pkgs, config, ... }:

{
  launchd.agents.pueued = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.pueue}/bin/pueued" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.local/state/pueued.log";
      StandardErrorPath = "${config.home.homeDirectory}/.local/state/pueued.error.log";
    };
  };
}
