{
  lib,
  pkgs,
  nixpkgs-unstable,
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
    DIR=$(${pkgs.jq}/bin/jq -r '.workspace.project_dir' <<<"$input")
    MODEL=$(${pkgs.jq}/bin/jq -r '.model.display_name // .model.id // "?"' <<<"$input")
    echo "$DIR  ·  $MODEL"
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
  # NOTE: the directory MUST be named `gitbutler`. GitButler's `but skill check`
  # (run debounced on every `but` invocation) detects an installed skill purely by
  # folder name — it scans agent skill locations for a subdir literally called
  # `gitbutler`, ignoring the SKILL.md `name:` field. Installing under any other name
  # (e.g. `but`) makes `but` print "AGENT ACTION REQUIRED: skill not installed" on
  # every mutation. Claude still surfaces it as `but` via the frontmatter `name:`.
  butSkillDir = ./claude-assets/skills/gitbutler;
  butSkillVersion =
    let
      versionLine = lib.findFirst (lib.hasPrefix "version:") "version: unknown" (
        lib.splitString "\n" (builtins.readFile (butSkillDir + "/SKILL.md"))
      );
    in
    lib.removePrefix "version: " versionLine;

  # PreToolUse(Bash) hook: a skill/CLAUDE.md rule is only advisory — Claude can still
  # reach for `git`. This hook makes `but` non-optional by blocking raw `git` WRITE
  # commands (exit 2 feeds the message back to Claude) whenever the repo is
  # GitButler-managed (has a `gitbutler/workspace` branch). Reads (status/log/diff/
  # show/blame), `but ...`, and every non-git command pass through untouched, and in
  # plain-git repos the hook is a no-op. The regex tolerates global options that take
  # an argument (`git -C <path> commit`, `git -c k=v commit`) without swallowing the
  # subcommand. Tested against commit/add/push/checkout/rm and the `-C`/`-c`/absolute
  # -path forms.
  butGitGuard = pkgs.writeShellScript "but-git-guard" ''
    input=$(cat)
    cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""' <<<"$input")
    cwd=$(${pkgs.jq}/bin/jq -r '.cwd // ""' <<<"$input")
    [ -z "$cwd" ] && cwd="$PWD"

    # Only enforce inside GitButler-managed repos.
    ${pkgs.git}/bin/git -C "$cwd" show-ref --verify --quiet refs/heads/gitbutler/workspace 2>/dev/null || exit 0

    re='(^|[^[:alnum:]_])git[[:space:]]+(((-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|--?[[:alnum:]-]+)[[:space:]]+)*(add|commit|push|pull|checkout|switch|merge|rebase|stash|cherry-pick|restore|reset|revert|am|clean|rm|mv|tag)([[:space:]]|$)'
    if [[ "$cmd" =~ $re ]]; then
      echo 'BLOCKED: this repo is GitButler-managed (gitbutler/workspace). Use the `but` CLI, not git, for write operations:' >&2
      echo '  but status -fv                                    # current state + the CLI IDs you need' >&2
      echo '  but commit <branch-id> -m "msg" --changes <ids>  # commit specific files to a branch' >&2
      echo '  but branch new <name> | but push | but amend | but undo' >&2
      exit 2
    fi
    exit 0
  '';

in
{
  programs.claude-code = {
    enable = true;
    package = unstable.claude-code;

    settings = {
      model = "opus";
      effortLevel = "xhigh";
      alwaysThinkingEnabled = true;
      skipDangerousModePermissionPrompt = true;
      tui = "fullscreen";
      permissions = {
        defaultMode = "bypassPermissions";
        allow = [ ];
        deny = [ ];
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${butGitGuard}";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "${statuslineScript}";
      };
    };

    # No local stdio MCP servers in the CLI: dba/bilbasen are served remotely by
    # the k3s gateway (registered at claude.ai), not duplicated into local config.
    mcpServers = { };

    skills = {
      refactor = ./claude-assets/skills/refactor;
      # Teaches Claude to drive GitButler's `but` CLI instead of raw git for all
      # write operations (commit/push/branch), enabling parallel virtual-branch
      # agents. Vendored via `but skill install --path ...` and pinned to the CLI
      # version; the activation check below flags drift after a `but` upgrade.
      # The attr key is the installed dir name and MUST be `gitbutler` (see the
      # butSkillDir note above) — that is how `but` detects the skill is present.
      gitbutler = butSkillDir;
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
  # machine, before the cask lands). To clear the warning: run `just
  # update-but-skill` (re-vendors the skill into the checkout and commits just
  # that change), then `hs` again.
  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    checkButSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      plist=/Applications/GitButler.app/Contents/Info.plist
      if [ -f "$plist" ]; then
        cliVersion="$(/usr/bin/defaults read /Applications/GitButler.app/Contents/Info CFBundleShortVersionString 2>/dev/null)"
        if [ -n "$cliVersion" ] && [ "$cliVersion" != "${butSkillVersion}" ]; then
          echo "" >&2
          echo "⚠️  GitButler 'but' skill is stale: vendored ${butSkillVersion}, app $cliVersion." >&2
          echo "    Fix:  cd $HOME/.config/nix && just update-but-skill   (re-vendors + commits)" >&2
          echo "    then run hs again to apply." >&2
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

  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    force = true;
    text = builtins.toJSON {
      globalShortcut = "Alt+Space";
      # Only genuinely-local tools live here. Everything served by the k3s gateway
      # (trengo, dba, bilbasen, google-chat-moto/-hcc, bear) is reached remotely as
      # a claude.ai connector at https://mcp.skielboe.com/<path>/mcp, not locally.
      mcpServers = {
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
        # outline moved to a claude.ai OAuth connector (its /mcp endpoint supports
        # OAuth + dynamic client registration), so it no longer needs a local
        # mcp-remote bridge or a plaintext bearer token baked into this config.
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
