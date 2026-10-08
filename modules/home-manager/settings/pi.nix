{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  refreshState = "${config.home.homeDirectory}/.local/state/openwiki-refresh";
  refreshConfig = pkgs.writeText "openwiki-refresh-config.json" (
    builtins.toJSON {
      home = config.home.homeDirectory;
      stateDirectory = refreshState;
      openwikiDirectory = "${config.home.homeDirectory}/.openwiki";
      cli = "${agentDir}/npm/node_modules/openwiki/dist/cli/cli.js";
      node = "${pkgs.nodejs_26}/bin/node";
      git = "${pkgs.git}/bin/git";
      path = "${
        lib.makeBinPath [
          pkgs.nodejs_26
          pkgs.git
          pkgs.coreutils
        ]
      }:${config.home.profileDirectory}/bin";
      refreshIntervalMs = 6 * 60 * 60 * 1000;
      retryIntervalMs = 60 * 60 * 1000;
    }
  );
  # Node resolves Home Manager symlinks before imports, so configuration shares the real module directory.
  refreshPackage = pkgs.runCommand "pi-openwiki-refresh" { } ''
    mkdir -p "$out"
    cp ${./pi/openwiki-refresh.ts} "$out/index.ts"
    cp ${./pi/openwiki-sync.mjs} "$out/openwiki-sync.mjs"
    cp ${refreshConfig} "$out/config.json"
  '';
  personalSync = pkgs.writeShellScriptBin "openwiki-sync" ''
    exec ${pkgs.nodejs_26}/bin/node ${refreshPackage}/openwiki-sync.mjs --due "$@"
  '';
in
{
  programs.pi.coding-agent.enable = true;
  programs.pi.coding-agent.settings = {
    packages = [
      "npm:pi-messenger"
      "npm:openwiki"
    ];
    messenger.autoRegister = true;
  };

  launchd.agents.openwiki-personal-sync = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${personalSync}/bin/openwiki-sync" ];
      RunAtLoad = true;
      StartInterval = 3600;
      StandardOutPath = "${refreshState}/personal.log";
      StandardErrorPath = "${refreshState}/personal.log";
    };
  };

  systemd.user = lib.mkIf pkgs.stdenv.isLinux {
    services.openwiki-personal-sync = {
      Unit.Description = "Personal OpenWiki source ingestion";
      Service = {
        Type = "oneshot";
        ExecStart = "${personalSync}/bin/openwiki-sync";
      };
    };
    timers.openwiki-personal-sync = {
      Unit.Description = "Personal OpenWiki freshness check";
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  home.packages = [ personalSync ];
  home.activation.openwikiRefreshState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${lib.escapeShellArg refreshState}
    chmod 700 ${lib.escapeShellArg refreshState}
  '';
  home.file = {
    ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
    ".pi/agent/extensions/openwiki-refresh".source = refreshPackage;
    ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
  };
}
