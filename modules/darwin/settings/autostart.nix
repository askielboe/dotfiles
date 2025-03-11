{ config, lib, pkgs, ... }:

{
  launchd.user.agents = {
    ice = {
      serviceConfig = {
        Label = "com.jordanbaird.ice.LaunchAtLogin";
        ProgramArguments = [
          "/Applications/Ice.app/Contents/MacOS/Ice"
        ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };
}
