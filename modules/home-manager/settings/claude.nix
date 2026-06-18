{
  lib,
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

  # GitButler's `but` CLI is the desktop-app binary invoked under a different
  # argv[0]; the app ships it inside the cask declared in homebrew.nix. GitButler's
  # "Install CLI" button only drops an imperative symlink in /opt/homebrew/bin, so we
  # provide `but` declaratively via this wrapper instead (macOS-only; the path is the
  # fixed cask install location). `exec -a but` preserves the basename the binary
  # dispatches on. Pair with the vendored `but` skill below for Claude ↔ GitButler.
  butCli = pkgs.writeShellScriptBin "but" ''
    exec -a but /Applications/GitButler.app/Contents/MacOS/gitbutler-tauri "$@"
  '';

  # Version the vendored skill was generated against, read from its SKILL.md
  # frontmatter at eval time. The activation check below compares this against the
  # installed app's bundle version so a CLI upgrade that outdates the skill is
  # flagged on the next `hs` instead of silently drifting.
  butSkillDir = ./claude-assets/skills/but;
  butSkillVersion =
    let
      versionLine = lib.findFirst (lib.hasPrefix "version:") "version: unknown" (
        lib.splitString "\n" (builtins.readFile (butSkillDir + "/SKILL.md"))
      );
    in
    lib.removePrefix "version: " versionLine;

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
        allow = [ ];
        deny = [ ];
      };
      statusLine = {
        type = "command";
        command = "${statuslineScript}";
      };
    };

    mcpServers = {
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
      # Teaches Claude to drive GitButler's `but` CLI instead of raw git for all
      # write operations (commit/push/branch), enabling parallel virtual-branch
      # agents. Vendored via `but skill install --path ...` and pinned to the CLI
      # version; the activation check below flags drift after a `but` upgrade.
      but = butSkillDir;
    };

    agents = {
      refactor-mapper = ./claude-assets/agents/refactor-mapper.md;
    };
  };

  # Provide the `but` CLI on PATH declaratively (macOS only; wraps the cask app).
  home.packages = lib.optionals pkgs.stdenv.isDarwin [ butCli ];

  # On every `hs`, warn (without failing the switch) if the GitButler CLI has moved
  # past the version the vendored skill was generated against. The version is read
  # from the app bundle's Info.plist (CFBundleShortVersionString == the `but`
  # version) rather than by running `but --version`: the CLI is the Tauri GUI binary,
  # which blocks indefinitely when launched from the activation context (no GUI
  # session to attach to). Reading the plist is cheap and never launches the app.
  # Skips silently when the app isn't installed yet (e.g. first switch on a fresh
  # machine, before the cask lands). To clear the warning: re-run the vendoring
  # command it prints, then `git add` the skill and `hs` again.
  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    checkButSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      plist=/Applications/GitButler.app/Contents/Info.plist
      if [ -f "$plist" ]; then
        cliVersion="$(/usr/bin/defaults read /Applications/GitButler.app/Contents/Info CFBundleShortVersionString 2>/dev/null)"
        if [ -n "$cliVersion" ] && [ "$cliVersion" != "${butSkillVersion}" ]; then
          echo "" >&2
          echo "⚠️  GitButler 'but' skill is stale: vendored ${butSkillVersion}, app $cliVersion." >&2
          echo "    Re-vendor:  but skill install --path ${toString butSkillDir}" >&2
          echo "    then 'git add' the skill and run hs again." >&2
          echo "" >&2
        fi
      fi
    '';
  };

  home.file.".claude/.lsp.json".text = builtins.toJSON lspServers;

  # End-of-session maintainability review slash commands. Managed as individual
  # files so the rest of ~/.claude/commands (other commands + runtime files)
  # stays untouched and writable. These become read-only store symlinks — to
  # change a command, edit the source .md and re-run `hs`.
  home.file.".claude/commands/review-audit.md".source = ./claude-assets/commands/review-audit.md;
  home.file.".claude/commands/review-fix.md".source = ./claude-assets/commands/review-fix.md;

  home.file.".config/google-chat-mcp/credentials.json".text = googleChatCredentials;

  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    force = true;
    text = builtins.toJSON {
      globalShortcut = "Alt+Space";
      mcpServers = {
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
