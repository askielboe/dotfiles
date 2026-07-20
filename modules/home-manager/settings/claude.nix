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

  # A self-correcting `rg` for the ripgrep `-r` footgun. In GNU grep `-r` means
  # "recursive"; in ripgrep `-r`/`--replace` instead takes the following text as a
  # REPLACEMENT and rewrites every match (rg already recurses by default). A
  # habit-driven `rg -rn` / `-rin` / `-nri` parses as --replace=n / =in / =i and
  # silently rewrites the output — which reads back as "mangled," sending Claude off
  # to re-Read the file for the real value.
  #
  # This is NOT enforced via a PreToolUse hook: a hook only sees the raw command
  # STRING and can't tell which command a flag belongs to, so it false-fired on
  # `rg -i … ; rm -rf …` (the `-rf` is rm's) and on the legitimate `rg -trust`
  # (search Rust files: `-t` takes value "rust"), and even on a true hit Claude just
  # abandoned rg. A wrapper sees rg's REAL argv, so it fixes exactly the footgun and
  # nothing else — zero false positives.
  #
  # It rewrites only a cluster whose chars before `r` are all *boolean* short flags
  # (so `-rn`→`-n`, `-rin`→`-in`); it leaves untouched `--replace=` (long form),
  # `-r <text>` (space form), and value-taking clusters like `-trust` / `-glob`
  # (their leading flag consumes the rest, so the `r` isn't --replace). It runs the
  # real rg and prints a one-line stderr note so the correction is visible, not swept
  # away. Wired in below via `claude-code.override { ripgrep = rgGuard; }` — that is
  # the ONLY `rg` Claude's Bash tool and built-in Grep tool resolve to, because the
  # nixpkgs claude-code wrapper sets USE_BUILTIN_RIPGREP=0 and PREPENDS its `ripgrep`
  # input to PATH (ahead of the home-manager profile). Diagnosed 2026-07 from real
  # sessions (`rg -rin "cachix|..."`).
  rgGuard = pkgs.writeShellScriptBin "rg" ''
    args=()
    # A short cluster of boolean flags with ripgrep's -r (--replace) glued on:
    # either `r` followed by more chars (-rn, -rin) or a trailing `r` after >=1
    # boolean (-nr, -lir). Bare `-r`, `--replace=`, `-r <text>` (space form), and
    # value-taking clusters like `-trust` (-t consumes "rust") are all excluded.
    re='^-[acFhiIlLnNoPpqsSuUvwxz]*r[a-zA-Z0-9]|^-[acFhiIlLnNoPpqsSuUvwxz]+r$'
    for a in "$@"; do
      if [[ "$a" =~ $re ]]; then
        fixed=''${a/r/}
        echo "rg: corrected $a -> $fixed  (ripgrep -r is --replace, not grep-style recursive; rg already recurses)" >&2
        args+=("$fixed")
      else
        args+=("$a")
      fi
    done
    exec ${unstable.ripgrep}/bin/rg "''${args[@]}"
  '';

in
{
  programs.claude-code = {
    enable = true;
    # rgGuard replaces the ripgrep claude-code prepends to PATH (see the note in the
    # let block), so every `rg` Claude runs self-corrects the `-r`/--replace footgun.
    package = unstable.claude-code.override { ripgrep = rgGuard; };

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

    # Claude Desktop rewrites this file at runtime (window + cowork state), atomically
    # replacing any home.file symlink with a plain file — so a read-only store symlink
    # can never hold it. Instead we own only the `mcpServers` slice: force it empty. No
    # local stdio servers run in Desktop; every integration is a claude.ai connector
    # (3rd-party, or the mcp.skielboe.com k3s gateway). All app-written keys are
    # preserved; globalShortcut + preferences are seeded as defaults only (the app's own
    # values win via the deep-merge below). This also keeps plaintext API tokens out of
    # the on-disk config. To reintroduce a genuinely-local server, add it to the jq
    # `.mcpServers = {...}` assignment here rather than a home.file block.
    claudeDesktopMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
      seed='{"globalShortcut":"Alt+Space","preferences":{"menuBarEnabled":false,"quickEntryShortcut":{"accelerator":"Alt+Space"}}}'
      if [ -f "$cfg" ]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp "$cfg.XXXXXX")"
        if ${pkgs.jq}/bin/jq --argjson seed "$seed" '($seed * .) | .mcpServers = {}' "$cfg" > "$tmp"; then
          ${pkgs.coreutils}/bin/mv -f "$tmp" "$cfg"
        else
          ${pkgs.coreutils}/bin/rm -f "$tmp"
          echo "⚠️  claude_desktop_config.json isn't valid JSON; left it untouched." >&2
        fi
      else
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$cfg")"
        echo "$seed" | ${pkgs.jq}/bin/jq '.mcpServers = {}' > "$cfg"
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

}
