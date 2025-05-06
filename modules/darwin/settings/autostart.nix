{
  config,
  lib,
  pkgs,
  ...
}:
{
  launchd.user.agents = {
    ice = {
      serviceConfig = {
        Label = "com.jordanbaird.ice.LaunchAtLogin";
        ProgramArguments = [
          "/Applications/Ice.app/Contents/MacOS/Ice"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
    aw-watcher-window = {
      serviceConfig = {
        Label = "com.user.aw-watcher-window";
        ProgramArguments = [ "/Applications/ActivityWatch.app/Contents/MacOS/aw-watcher-window" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Users/askielboe/Library/Logs/aw-watcher-window.log";
        StandardErrorPath = "/Users/askielboe/Library/Logs/aw-watcher-window.err.log";
      };
    };
  };
}
