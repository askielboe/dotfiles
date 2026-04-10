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
    # bear-litestream = {
    #   serviceConfig = {
    #     Label = "com.bear.litestream";
    #     ProgramArguments = [
    #       "${pkgs.litestream}/bin/litestream"
    #       "replicate"
    #       "-config"
    #       "/Users/askielboe/work/mcp/servers/bear/litestream.yml"
    #     ];
    #     EnvironmentVariables = {
    #       LITESTREAM_ACCESS_KEY_ID = private.hetznerS3BearMcp.accessKey;
    #       LITESTREAM_SECRET_ACCESS_KEY = private.hetznerS3BearMcp.secretKey;
    #     };
    #     RunAtLoad = true;
    #     KeepAlive = true;
    #     StandardOutPath = "/tmp/bear-litestream.log";
    #     StandardErrorPath = "/tmp/bear-litestream.log";
    #   };
    # };
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
