{
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # statusLine stdin schema (claude-code 2.1.x): `.effort.level` is only present when
  # the current model supports reasoning effort, and `.session_id` is the chat UUID
  # (same id as the transcript filename) — handy for `claude --resume <uuid>` and for
  # pointing tooling at ~/.claude/projects/*/<uuid>.jsonl.
  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    DIR=$(${pkgs.jq}/bin/jq -r '.workspace.project_dir' <<<"$input")
    MODEL=$(${pkgs.jq}/bin/jq -r '.model.display_name // .model.id // "?"' <<<"$input")
    EFFORT=$(${pkgs.jq}/bin/jq -r '.effort.level // "?"' <<<"$input")
    SESSION=$(${pkgs.jq}/bin/jq -r '.session_id // "?"' <<<"$input")
    echo "$DIR  ·  $MODEL ($EFFORT)  ·  $SESSION"
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
      effortLevel = "high";
      alwaysThinkingEnabled = true;
      skipDangerousModePermissionPrompt = true;
      tui = "fullscreen";
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

    # No local stdio MCP servers in the CLI: dba/bilbasen are served remotely by
    # the k3s gateway (registered at claude.ai), not duplicated into local config.
    mcpServers = { };

    skills.refactor = ./claude-assets/skills/refactor;

    agents = {
      refactor-mapper = ./claude-assets/agents/refactor-mapper.md;
    };
  };

  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
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
