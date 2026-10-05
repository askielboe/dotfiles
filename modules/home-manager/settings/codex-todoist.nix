{ config, pkgs, ... }:
let
  collector = pkgs.writeText "codex-status-collector.py" (
    builtins.readFile ./codex-status/collector.py
  );
in
{
  launchd.agents.codex-status-tunnel = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.kubectl}/bin/kubectl"
        "--kubeconfig"
        "${config.home.homeDirectory}/.kube/k3s.yaml"
        "--context"
        "default"
        "--namespace"
        "codex-todoist"
        "port-forward"
        "--address"
        "127.0.0.1"
        "service/codex-todoist"
        "19098:80"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/codex-status-tunnel.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/codex-status-tunnel.log";
    };
  };
  launchd.agents.codex-status-collector = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${collector}"
        "--url"
        "http://127.0.0.1:19098"
        "--token-file"
        config.sops.secrets.codex-todoist-collector-token.path
        "--codex-home"
        "${config.home.homeDirectory}/.codex"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/codex-status-collector.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/codex-status-collector.log";
      EnvironmentVariables.PYTHONUNBUFFERED = "1";
    };
  };
}
