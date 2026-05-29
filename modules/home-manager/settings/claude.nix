{
  pkgs,
  nixpkgs-unstable,
  addy-skills,
  private,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    DIR=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.project_dir')
    echo "$DIR"
  '';

  lspServers = {
    rust = {
      command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      args = [ ];
      extensionToLanguage = {
        ".rs" = "rust";
      };
    };
    swift = {
      command = "${pkgs.sourcekit-lsp}/bin/sourcekit-lsp";
      args = [ ];
      extensionToLanguage = {
        ".swift" = "swift";
      };
    };
  };

  icons = {
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
  googleChatCredentialsPath = "${private.user.homeDirectory}/.config/google-chat-mcp/credentials.json";
  googleChatTokenPath = "${private.user.homeDirectory}/.local/state/google-chat-mcp/token.json";

  bearMcp = {
    command = "/Applications/Bear.app/Contents/MacOS/bearcli";
    args = [ "mcp-server" ];
    env = { };
  };
  dbaMcp = {
    command = "${pkgs.nodejs_22}/bin/node";
    args = [ "/Users/askielboe/work/mcp/servers/dba/dist/index.js" ];
    env = { };
  };
  bilbasenMcp = {
    command = "${pkgs.nodejs_22}/bin/node";
    args = [ "/Users/askielboe/work/mcp/servers/bilbasen/dist/index.js" ];
    env = { };
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
in
{
  programs.claude-code = {
    enable = true;
    package = unstable.claude-code;

    settings = {
      model = "claude-opus-4-8";
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

    mcpServers = {
      bear = bearMcp // {
        type = "stdio";
      };
      dba = dbaMcp // {
        type = "stdio";
      };
      bilbasen = bilbasenMcp // {
        type = "stdio";
      };
    };

    skills = {
      using-agent-skills = "${addy-skills}/skills/using-agent-skills";
      refactor = ./claude-assets/skills/refactor;
    };

    agents = {
      refactor-mapper = ./claude-assets/agents/refactor-mapper.md;
    };

    memory.source = ./claude-assets/memory.md;
  };

  home.file.".claude/.lsp.json".text = builtins.toJSON lspServers;

  home.file.".config/google-chat-mcp/credentials.json".text = googleChatCredentials;

  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    force = true;
    text = builtins.toJSON {
      globalShortcut = "Alt+Space";
      mcpServers = {
        bear = bearMcp;
        google-chat = {
          command = "${pkgs.mcp-google-chat}/bin/google-chat-mcp";
          args = [ ];
          env = {
            GOOGLE_CREDENTIALS_FILE = googleChatCredentialsPath;
            GOOGLE_TOKEN_FILE = googleChatTokenPath;
          };
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
