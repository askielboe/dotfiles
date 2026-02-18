{ pkgs, private, ... }:

{
  launchd.agents.openclaw-node = {
    enable = true;
    config = {
      Label = "com.openclaw.node";
      ProgramArguments = [
        "${pkgs.openclaw}/bin/openclaw"
        "node"
        "run"
        "--host"
        "clawdbot.skielboe.com"
        "--port"
        "443"
        "--tls"
        "--display-name"
        "Andreas Mac"
      ];
      EnvironmentVariables = {
        OPENCLAW_GATEWAY_TOKEN = private.apiKeys.openclawGateway;
        HOME = private.user.homeDirectory;
        PATH = "${pkgs.nodejs_22}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/openclaw-node.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/openclaw-node.err.log";
    };
  };
}
