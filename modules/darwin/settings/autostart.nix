_: {
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
    # git-annex watch daemon: auto-add/commit/sync for every repo listed in
    # ~/.config/git-annex/autostart (e.g. ~/annex/audiobooks once registered with `git annex assistant`).
    # --foreground keeps it under launchd supervision; explicit PATH so it finds git/ssh/rsync.
    git-annex-assistant = {
      serviceConfig = {
        Label = "com.askielboe.git-annex-assistant";
        ProgramArguments = [
          "/etc/profiles/per-user/askielboe/bin/git-annex"
          "assistant"
          "--autostart"
          "--foreground"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/askielboe/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
        StandardOutPath = "/tmp/git-annex-assistant.log";
        StandardErrorPath = "/tmp/git-annex-assistant.log";
      };
    };
  };
}
