{
  config,
  lib,
  pkgs,
  ...
}:
let
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  codexDir = "${config.home.homeDirectory}/.codex";
  appResources = "/Applications/ChatGPT.app/Contents/Resources";
  nodeDir = "${appResources}/cua_node";
  nodeEnv = {
    NODE_REPL_NATIVE_PIPE_CONNECT_TIMEOUT_MS = "1000";
    NODE_REPL_NODE_MODULE_DIRS = "${nodeDir}/lib/node_modules";
    NODE_REPL_NODE_PATH = "${nodeDir}/bin/node";
    NODE_REPL_TRUSTED_CODE_PATHS = "${codexDir}:${nodeDir}/lib/node_modules";
    CODEX_HOME = codexDir;
    BROWSER_USE_AVAILABLE_BACKENDS = "chrome,iab,mcpapps";
    BROWSER_USE_TINYSKY_ENABLED = "1";
    BROWSER_USE_CODEX_APP_BUILD_FLAVOR = "prod";
    BROWSER_USE_CODEX_APP_VERSION = "26.930.51102";
    NODE_REPL_TRUSTED_SERVICES = builtins.toJSON {
      browser = "@oai/browser-desktop/service";
      sky = "@oai/sky/service";
    };
    SKY_CUA_SERVICE_PATH = "${codexDir}/computer-use/Codex Computer Use.app";
    CODEX_CLI_PATH = "${appResources}/codex-cli/CodexCLI.app/Contents/MacOS/codex";
  };
  googleServices = {
    gmail = [
      "https://www.googleapis.com/auth/gmail.readonly"
      "https://www.googleapis.com/auth/gmail.compose"
    ];
    drive = [
      "https://www.googleapis.com/auth/drive.readonly"
      "https://www.googleapis.com/auth/drive.file"
    ];
    chat = [
      "https://www.googleapis.com/auth/chat.spaces.readonly"
      "https://www.googleapis.com/auth/chat.memberships.readonly"
      "https://www.googleapis.com/auth/chat.messages.readonly"
      "https://www.googleapis.com/auth/chat.messages.create"
      "https://www.googleapis.com/auth/chat.users.readstate"
    ];
  };
  googleAccounts = {
    mo2tion = "andreas@mo2tion.com";
    hccreators = "askielboe@hccreators.com";
  };
  adapterConfig = {
    mcpServers = {
      granola.url = "https://mcp.granola.ai/mcp";
      trengo = {
        url = "https://mcp.pipedream.net/v2";
        oauth.scope = "openid profile email offline_access mcp";
      };
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      cua_repl = {
        includeTools = [
          "js"
          "js_reset"
          "turn_ended"
        ];
        excludeTools = [ ];
      };
    }
    // lib.listToAttrs (
      lib.concatMap (
        account:
        lib.mapAttrsToList (service: scopes: {
          name = "${service}-${account}";
          value = {
            url = "https://${service}mcp.googleapis.com/mcp/v1";
            oauth = {
              clientId = "415069867080-h7uvl35oqlmt52sas8ts2dibst9308jp.apps.googleusercontent.com";
              clientSecret = "!${pkgs.jq}/bin/jq -er '.installed.client_secret' ${lib.escapeShellArg "${agentDir}/credentials/google-workspace-oauth.json"}";
              redirectUri = "http://127.0.0.1:{port}/callback";
              scope = lib.concatStringsSep " " scopes;
              authorizationParams = {
                login_hint = googleAccounts.${account};
                access_type = "offline";
                prompt = "consent";
              };
            };
          };
        }) googleServices
      ) (builtins.attrNames googleAccounts)
    )
    // lib.mapAttrs' (account: email: {
      name = "gmail-${account}";
      value = {
        command = "${pkgs.bun}/bin/bun";
        args = [
          "${agentDir}/lib/gmail-api.mjs"
          "gmail-${account}"
          email
        ];
      };
    }) googleAccounts;
  };
  adapterPatch = pkgs.writeText "pi-mcp-adapter.json" (builtins.toJSON adapterConfig);
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
  programs.pi.coding-agent = {
    enable = true;
    settings = {
      defaultProvider = "openai";
      defaultModel = "gpt-6.1-sol";
      defaultThinkingLevel = "medium";
      hideThinkingBlock = true;
      showLastPrompt = false;
      collapseChangelog = true;
      packages = [
        "npm:pi-mcp-adapter"
        "npm:pi-web-access"
        "npm:pi-subagents"
        "npm:pi-messenger"
        "npm:pi-goal-x"
        "npm:context-mode"
        "npm:openwiki"
        "npm:pi-lens"
        "npm:pi-session-search"
        "npm:pi-powerline-footer"
      ];
      messenger.autoRegister = true;
      extensions = [ "-builtin:mcp" ];
    };
    mcp.mcpServers = {
      openaiDeveloperDocs = {
        url = "https://developers.openai.com/mcp";
        timeout = 120;
      };
      metabase = {
        url = "https://motosumo.metabaseapp.com/api/metabase-mcp";
        timeout = 120;
      };
      outline = {
        url = "https://mrssporty.getoutline.com/mcp";
        timeout = 120;
      };
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      bear = {
        command = "/Applications/Bear.app/Contents/MacOS/bearcli";
        args = [ "mcp-server" ];
        timeout = 120;
      };
      enzyme = {
        command = "${config.home.profileDirectory}/bin/enzyme";
        args = [ "mcp" ];
        timeout = 120;
      };
      node_repl = {
        command = "${nodeDir}/bin/node";
        args = [
          "${agentDir}/lib/codex-mcp-proxy.mjs"
          "${nodeDir}/bin/node_repl"
        ];
        env = nodeEnv // {
          NODE_REPL_INSTRUCTIONS_USE_CASE_BROWSER = "";
          NODE_REPL_INSTRUCTIONS_USE_CASE_CHROME = "";
          NODE_REPL_INSTRUCTIONS_USE_CASE_COMPUTER_USE = "";
        };
        timeout = 120;
      };
      cua_repl = {
        command = "${nodeDir}/bin/node";
        args = [
          "${agentDir}/lib/codex-mcp-proxy.mjs"
          "${nodeDir}/bin/node"
          "${nodeDir}/lib/node_modules/@oai/cua-repl/bin/cua-repl.mjs"
        ];
        env = nodeEnv // {
          CUA_REPL_NODE_REPL_PATH = "${nodeDir}/bin/node_repl";
          CUA_REPL_ENABLED_SURFACES = "browser,computer";
        };
        timeout = 120;
        toolExposure = {
          js = "codemode";
          js_reset = "codemode";
          turn_ended = "codemode";
          "*" = "hidden";
        };
      };
    };
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

  # The adapter needs fields Pi's native MCP translator drops, and edits this file itself.
  home = {
    packages = [ personalSync ];
    activation = {
      openwikiRefreshState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p ${lib.escapeShellArg refreshState}
        chmod 700 ${lib.escapeShellArg refreshState}
      '';
      piMcpAdapter = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.pi/agent/mcp-adapter.json"
        mkdir -p "$(dirname "$cfg")"
        tmp="$(mktemp "$cfg.XXXXXX")"
        if [ -f "$cfg" ]; then
          input="$cfg"
        else
          input=/dev/null
        fi
        if ${pkgs.jq}/bin/jq -s --slurpfile patch ${adapterPatch} '
          (if length == 0 then {} elif length == 1 and (.[0] | type) == "object" then .[0] else error("Expected a JSON object") end)
          | (.mcpServers["gmail-hccreators"], .mcpServers["gmail-mo2tion"]) |= del(.url, .oauth, .headers)
          | . * $patch[0]
        ' "$input" > "$tmp"; then
          chmod 600 "$tmp"
          mv -f "$tmp" "$cfg"
        else
          rm -f "$tmp"
          echo "Pi MCP adapter config isn't valid JSON; left it untouched." >&2
          exit 1
        fi
      '';

    };
    file = {
      ".pi/agent/lib/gmail-api.mjs".source = ./pi/gmail-api.ts;
      ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
      ".pi/agent/extensions/openwiki-refresh".source = refreshPackage;
      ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
    };
  };
}
