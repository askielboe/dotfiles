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
  slackSource = {
    id = "slack-motosumo";
    connectorId = "slack";
    name = "Motosumo Slack";
    ingestionGoal = "Motosumo Slack is a read-only user-token source for the personal wiki. Bot identities, bot tokens, channel joining, posting, and all write operations are excluded. Coverage is bounded by the connector configuration; incomplete history remains explicit.";
  };
  slackSourcePatch = pkgs.writeText "openwiki-slack-source.json" (builtins.toJSON slackSource);
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
  ossKit = pkgs.fetchFromGitHub {
    owner = "svyatov";
    repo = "oss-kit";
    rev = "84b1458e10980e6ba9c7b4f4e3e097abd7b39890";
    hash = "sha256-iw02Am+OljQddZbx/xEZF/RF8DBtRX1P/adIk45hOOI=";
  };
in
{
  programs.openwikiGoogle.accounts.hccreators.email = "askielboe@hccreators.com";

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
      computer-history = {
        command = "${pkgs.nodejs_26}/bin/node";
        args = [
          "${agentDir}/lib/computer-history-mcp.mjs"
          "${appResources}/codex-cli/CodexCLI.app/Contents/MacOS/codex"
        ];
        cwd = codexDir;
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

      openWikiSlackSource = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.openwiki/onboarding.json"
        env="$HOME/.openwiki/.env"
        if [ -f "$cfg" ] && [ -f "$env" ] && ${pkgs.gnugrep}/bin/grep -q '^OPENWIKI_SLACK_USER_TOKEN=.' "$env"; then
          tmp="$(mktemp "$cfg.XXXXXX")"
          if ${pkgs.jq}/bin/jq --slurpfile patch ${slackSourcePatch} '
            .sourceInstances = (
              (.sourceInstances // []) as $sources
              | ($patch[0] + {connectedAt: (now | todateiso8601)}) as $source
              | if any($sources[]; .id == $source.id) then
                  $sources | map(if .id == $source.id then . + $patch[0] + {connectedAt: (.connectedAt // $source.connectedAt)} else . end)
                else $sources + [$source] end
            )
          ' "$cfg" > "$tmp"; then
            chmod 600 "$tmp"
            mv -f "$tmp" "$cfg"
          else
            rm -f "$tmp"
            echo "OpenWiki source registration failed; onboarding was left untouched." >&2
            exit 1
          fi
        fi
      '';

    };
    file = {
      ".pi/agent/lib/gmail-api.mjs".source = ./pi/gmail-api.ts;
      ".openwiki/accounts/hccreators/collection-policy.json".text = builtins.toJSON {
        ignoreTooLarge = true;
      };
      ".openwiki/connectors/google/config.json".text = builtins.toJSON {
        enabled = true;
        provider = "gmail";
        format = "full";
        includeSpamTrash = false;
        labelIds = [ ];
        maxMessages = 100;
        pageSize = 100;
        query = "newer_than:1d";
        metadataHeaders = [
          "From"
          "To"
          "Cc"
          "Bcc"
          "Subject"
          "Date"
          "Message-ID"
        ];
      };
      ".openwiki/connectors/slack/config.json".text = builtins.toJSON {
        enabled = true;
        assistantSearchQueries = [ ];
        conversationScanLimit = 500;
        conversationTypes = [
          "public_channel"
          "private_channel"
          "im"
          "mpim"
        ];
        maxConversations = 50;
        messagesPerConversation = 50;
        myMessagesSearchLimit = 20;
        streams = [
          "my_messages_search"
          "recent_messages"
        ];
      };
      ".pi/agent/AGENTS.md".force = true;
      ".pi/agent/AGENTS.md".text = ''
        ## HARD CONSTRAINT: Email requires prior draft review

        - NEVER send, reply to, forward, or schedule an email until I have reviewed the exact draft and explicitly approved sending it afterward.
        - First show the recipients (including CC/BCC), subject, complete body, and any attachments. Wait for my explicit approval of that draft before sending. If any of these change, obtain approval again.
        - Requests such as "reply to the email thread", "send an email", "continue", or general permission to act authorize preparation only when I have not yet reviewed the exact draft. Silence is never approval.
        - This is mandatory globally, across all projects, tasks, agents, automations, accounts, plugins, connectors, APIs, command-line tools, and browser/native-app actions. Never bypass it by changing the sending method or delegating. Routine confirmations have no exception.

        ## Club account deactivation

        - Only accounts belonging exclusively to a verified closed club are eligible for deactivation.
        - Personal, franchisee, and shared accounts are excluded from club-closure deactivation, including sign-in blocking and session revocation.
        - Account identity, exclusive club ownership, and closure status require authoritative verification before any access change.

        ## Code hygiene

        - Permanent documentation uses declarative statements, not imperative instructions. Temporal transition phrases such as "from now on", "going forward", and "henceforth" are excluded; documentation states the enduring rule or current state.
        - Documentation work uses the `oss-writing` skill, including its documentation reference and completion gate. The declarative-only rule takes precedence over imperative examples in the skill.
        - Completion requires a clean prose checker run and a full editorial pass on the final revision. The editorial pass covers declarative wording and temporal phrases that the checker does not detect.
        - Comments explain why, never what.
        - Do not create documentation unless explicitly requested.
        - Do not duplicate information across code, comments, and documentation.
        - Before adding an abstraction or helper, search for an existing one.
        - Prefer deletion and consolidation over addition.
        - When modifying code, remove code and comments made obsolete by the change.
        - Do not preserve obsolete compatibility paths unless required.

        ## Primary information sources

        - Bear notes and Granola are my primary sources of personal and work context. Proactively search them when a request involves my projects, people, meetings, decisions, plans, preferences, or previous work, even when I do not name either app.
        - Use Bear for written notes and reference material, and Granola for meeting notes, discussions, decisions, and action items. Search both when the topic could span them, before asking me for context or relying on memory alone.
        - Start with focused searches and read the relevant results. Cite the notes or meetings used, including dates when useful; verify time-sensitive claims against current authoritative sources.
        - If a connector is not listed, discover its tools or use an existing configured connection. If access fails, say which source could not be checked; do not treat unavailable access as no results.
        - Skip these searches for self-contained requests that do not need personal context, such as translations, simple rewrites, general facts, or code changes fully specified by the repository and prompt.

        ## Environment management

        - Manage installed CLI tools through my Nix configuration at `~/.config/nix`, not ad hoc Homebrew, npm-global, or installer-script installations. Follow that repository's instructions; I apply changes with `hs`.

        ## Configuration ownership

        - Nix at `~/.config/nix` is the source of truth for all configuration, including Pi plugins, package lists, settings, preferences, MCP configuration, extension deployment, and agent instructions. Make persistent configuration changes in Nix; do not install plugins or create local configuration workarounds as the final setup.
        - Local configuration files are runtime outputs, not an alternative source of truth. Keep credentials, OAuth tokens, session history, caches, and other mutable runtime state outside the Nix store.
        - Follow the Nix repository instructions. I apply changes with `hs`; do not run switch commands yourself.

        ## Browser use

        - Use Google Chrome through the browser extension for browser tasks. Give parallel tasks separate tabs. Do not use Safari or desktop mouse-and-keyboard control for browsing. If extension-based control is unavailable, ask before switching methods.
        - When Chrome's extension connection fails, check whether Chrome is running. If not, proactively ask for explicit permission to launch it; a request to fix the connection is not launch permission.
        - After approval, use the browser plugin's documented launcher, wait two seconds, and retry the extension connection. If Chrome is already running or the retry fails, follow the plugin's documented extension and native-host diagnostics and report the specific problem.

        ## Autonomy

        - When a request includes implementation, run in-scope commands and edit in-scope files without asking for confirmation.
      '';
      ".pi/agent/skills/oss-writing".source = "${ossKit}/skills/oss-writing";
      ".pi/agent/extensions/codex-metadata.ts".source = ./pi/codex-metadata.ts;
      ".pi/agent/extensions/openwiki-refresh".source = refreshPackage;
      ".pi/agent/lib/codex-mcp-proxy.mjs".source = ./pi/codex-mcp-proxy.mjs;
      ".pi/agent/lib/computer-history-mcp.mjs".source = ./pi/computer-history-mcp.mjs;
    };
  };
}
