{ ... }:
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
    thingsmacsandboxhelper = {
      command = "/Applications/ThingsMacSandboxHelper.app/Contents/MacOS/ThingsMacSandboxHelper";
      serviceConfig = {
        RunAtLoad = true;
        StandardOutPath = "/tmp/thingsmacsandboxhelper.log";
        StandardErrorPath = "/tmp/thingsmacsandboxhelper.log";
      };
    };
  };
}
