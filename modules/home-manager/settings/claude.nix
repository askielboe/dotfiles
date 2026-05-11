{
  pkgs,
  lib,
  private,
  ...
}:
let
  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    DIR=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.project_dir')
    echo "$DIR"
  '';
  icons = {
    bear = pkgs.fetchurl {
      url = "https://bear.app/images/logo.png";
      sha256 = "sha256-gTh0ZcXCLALMlmQmKeW66eCpQD+AySs2/+fOLyoN+uQ=";
    };
    granola = pkgs.fetchurl {
      url = "https://www.granola.ai/favicon.ico";
      sha256 = "sha256-5TEt+YrhKezY4nZ5//D8dvvJr79yTsWj/tmFHgtXoAc=";
    };
    things = pkgs.fetchurl {
      url = "https://culturedcode.com/favicon.ico";
      sha256 = "sha256-AdJQOdKrwWLAelVP6FaLNdFIW3ncTG57WO9s6+CtTWw=";
    };
  };
  googleChatCredentials = builtins.toJSON {
    web = {
      client_id = private.googleChat.clientId;
      project_id = private.googleChat.projectId;
      auth_uri = "https://accounts.google.com/o/oauth2/auth";
      token_uri = "https://oauth2.googleapis.com/token";
      auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs";
      client_secret = private.googleChat.clientSecret;
      redirect_uris = [ "http://localhost:3003/oauth/callback" ];
    };
  };
  googleChatTokenPath = "${private.user.homeDirectory}/.local/state/google-chat-mcp/token.json";
  googleChatDataDir = "${private.user.homeDirectory}/.local/state/google-chat-mcp";
  googleChatOAuthClientInfo = builtins.toJSON {
    client_id = private.googleChat.clientId;
    client_secret = private.googleChat.clientSecret;
  };
  circleciMcp = {
    command = "${pkgs.nodejs_22}/bin/npx";
    args = [
      "-y"
      "@circleci/mcp-server-circleci"
    ];
    env = {
      CIRCLECI_TOKEN = private.apiKeys.circleci;
    };
  };
  toustrupMarkMcp = {
    command = "${pkgs.nodejs_22}/bin/node";
    args = [
      "/Users/askielboe/work/mcp/servers/toustrup-mark/dist/index.js"
    ];
    env = {
      PAPERLESS_URL = "https://docs.toustrupmark.dk";
      PAPERLESS_TOKEN = private.apiKeys.paperless;
      WIKI_URL = "https://wiki.toustrupmark.dk";
      WIKI_USERNAME = "Andreas Skielboe@claude-mcp";
      WIKI_PASSWORD = private.apiKeys.wikiPassword;
    };
  };
  dbaMcp = {
    command = "${pkgs.nodejs_22}/bin/node";
    args = [
      "/Users/askielboe/work/mcp/servers/dba/dist/index.js"
    ];
    env = { };
  };
  bilbasenMcp = {
    command = "${pkgs.nodejs_22}/bin/node";
    args = [
      "/Users/askielboe/work/mcp/servers/bilbasen/dist/index.js"
    ];
    env = { };
  };
  waitingonMcp = {
    command = "${pkgs.uv}/bin/uv";
    args = [
      "run"
      "--directory"
      "/Users/askielboe/work/mcp/servers/waitingon"
      "python"
      "-m"
      "waitingon"
    ];
    env = {
      TRENGO_API_TOKEN = private.apiKeys.trengo;
      SLACK_USER_TOKEN = private.apiKeys.slackUser;
      GCHAT_TOKEN_PATH = "${private.user.homeDirectory}/.local/state/google-chat-mcp/token.json";
    };
  };
in
{
  home.file.".config/google-chat-mcp/credentials.json".text = googleChatCredentials;

  # Disabled: the new stdio-based google-chat MCP server handles OAuth tokens directly.
  # The launchd agent is only needed if you need to re-authorize from scratch
  # (stop it first since it binds port 3003 which is the registered OAuth redirect).
  launchd.agents.google-chat-mcp = {
    enable = false;
    config = {
      Label = "com.google-chat-mcp";
      ProgramArguments = [ "${pkgs.mcp-google-chat}/bin/google-chat-mcp" ];
      EnvironmentVariables = {
        GOOGLE_CREDENTIALS_FILE = "${private.user.homeDirectory}/.config/google-chat-mcp/credentials.json";
        GOOGLE_TOKEN_FILE = googleChatTokenPath;
      };
      WorkingDirectory = googleChatDataDir;
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${googleChatDataDir}/stdout.log";
      StandardErrorPath = "${googleChatDataDir}/stderr.log";
    };
  };

  # NOTE: Do NOT add mcpServers here. Claude Code CLI reads MCP servers from
  # ~/.claude.json (managed via `claude mcp add`), not from settings.json.
  # MCP servers for Claude Code are registered via the activation script below.
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "claude-opus-4-7";
    effortLevel = "xhigh";
    alwaysThinkingEnabled = true;
    skipDangerousModePermissionPrompt = true;
    permissions = {
      defaultMode = "bypassPermissions";
      allow = [ "*" ];
      deny = [ ];
    };
    statusLine = {
      type = "command";
      command = "${statuslineScript}";
    };
  };

  # Claude Code CLI reads MCP servers from ~/.claude.json, not settings.json.
  # Patch the file directly with jq instead of running `claude mcp add` during
  # activation, which can hang inside launchctl asuser/sudo.
  home.activation.claudeCodeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_JSON="$HOME/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      run ${pkgs.jq}/bin/jq --indent 2 '
        .mcpServers.circleci = {
          "type": "stdio",
          "command": "${pkgs.nodejs_22}/bin/npx",
          "args": ["-y", "@circleci/mcp-server-circleci"],
          "env": {"CIRCLECI_TOKEN": "${private.apiKeys.circleci}"}
        } |
        .mcpServers.dba = {
          "type": "stdio",
          "command": "${pkgs.nodejs_22}/bin/node",
          "args": ["/Users/askielboe/work/mcp/servers/dba/dist/index.js"],
          "env": {}
        } |
        .mcpServers.bilbasen = {
          "type": "stdio",
          "command": "${pkgs.nodejs_22}/bin/node",
          "args": ["/Users/askielboe/work/mcp/servers/bilbasen/dist/index.js"],
          "env": {}
        } |
        .mcpServers.waitingon = {
          "type": "stdio",
          "command": "${pkgs.uv}/bin/uv",
          "args": ["run", "--directory", "/Users/askielboe/work/mcp/servers/waitingon", "python", "-m", "waitingon"],
          "env": {
            "TRENGO_API_TOKEN": "${private.apiKeys.trengo}",
            "SLACK_USER_TOKEN": "${private.apiKeys.slackUser}",
            "GCHAT_TOKEN_PATH": "${private.user.homeDirectory}/.local/state/google-chat-mcp/token.json"
          }
        }
      ' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    fi
  '';

  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    force = true;
    text = builtins.toJSON {
      globalShortcut = "Alt+Space";
      mcpServers = {
        bear = {
          command = "${pkgs.mcp-bear}/bin/mcp-bear";
          args = [
            "--token"
            private.apiKeys.bear
          ];
          env = { };
          iconPath = "${icons.bear}";
        };
        granola = {
          command = "${pkgs.mcp-granola}/bin/granola-mcp-server";
          args = [ ];
          env = { };
          iconPath = "${icons.granola}";
        };
        things = {
          command = "${pkgs.mcp-things}/bin/things-mcp";
          args = [ ];
          env = { };
          iconPath = "${icons.things}";
        };
        trengo = {
          command = "${pkgs.nodejs_22}/bin/node";
          args = [
            "/Users/askielboe/work/mcp/servers/trengo/dist/index.js"
          ];
          env = {
            TRENGO_API_TOKEN = private.apiKeys.trengo;
          };
        };
        toustrup-mark = toustrupMarkMcp;
        waitingon = waitingonMcp;
        circleci = circleciMcp;
        google-chat = {
          command = "${pkgs.nodejs_22}/bin/node";
          args = [
            "/Users/askielboe/work/mcp/servers/google-chat/dist/index.js"
          ];
          env = {
            GOOGLE_CREDENTIALS_FILE = "${private.user.homeDirectory}/.config/google-chat-mcp/credentials.json";
            GOOGLE_TOKEN_FILE = googleChatTokenPath;
          };
        };
        dba = dbaMcp;
        bilbasen = bilbasenMcp;
        outline = {
          command = "${pkgs.nodejs_22}/bin/npx";
          args = [
            "-y"
            "mcp-remote"
            "https://mrssporty.getoutline.com/mcp"
            "--header"
            "Authorization: Bearer ${private.apiKeys.outline}"
          ];
        };
      };
      preferences = {
        menuBarEnabled = false;
        quickEntryShortcut = {
          accelerator = "Alt+Space";
        };
      };
    };
  };
}
