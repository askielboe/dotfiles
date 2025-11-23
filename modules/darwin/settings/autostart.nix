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
    trainerroad-transcripts-mcp = {
      serviceConfig = {
        Label = "com.askielboe.trainerroad-transcripts-mcp";
        ProgramArguments = [
          "/Users/askielboe/.nix-profile/bin/uv"
          "run"
          "/Users/askielboe/work/trainerroad-transcribe/mcp_server.py"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/trainerroad-transcripts-mcp.log";
        StandardErrorPath = "/tmp/trainerroad-transcripts-mcp.log";
      };
    };
  };
}
