{ pkgs, ... }:
let
  # Importer that turns Claude Code's per-session JSONL logs into ActivityWatch
  # activity. Terminal/shell watchers can't see Claude work — a multi-hour
  # `claude` session is one opaque foreground process and the commands it runs go
  # through non-interactive shells with no preexec/precmd hooks. The session logs
  # under ~/.claude/projects, however, are timestamped and carry the cwd, so we
  # coalesce each cwd's events into active-time intervals (split on an 8-min gap)
  # and POST them to a local `aw-import-claude_<host>` bucket. cwd is the real
  # "what am I working on" axis (it can change mid-session), so we key on it
  # rather than the session id or the encoded project-dir name.
  #
  # Zero third-party imports (stdlib urllib/json/glob only) → a self-contained
  # writePython3Bin, no venv/uv. flake8 runs at build time; only long comment and
  # argparse-help lines exceed 79 cols, so we ignore E501.
  awImportClaude = pkgs.writers.writePython3Bin "aw-import-claude" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./aw-import-claude.py);
in
{
  # ActivityWatch: automatic window + idle (AFK) time tracking.
  #
  # Installed via Homebrew because the nixpkgs `activitywatch` package is
  # Linux-only and does not evaluate on aarch64-darwin. `activitywatch@beta` is
  # the native arm64 build (requires Apple Silicon); on an Intel Mac swap it for
  # the plain `activitywatch` cask, which runs under Rosetta 2. nix-darwin merges
  # `homebrew.casks` across modules, so this appends to the list in homebrew.nix.
  #
  # MANUAL ONE-TIME STEP — grant Accessibility permission so aw-watcher-window
  # can read window *titles* (not just app names); keyword categorization depends
  # on the title. This TCC grant cannot be set declaratively:
  #   System Settings → Privacy & Security → Accessibility → enable ActivityWatch
  #   (also approve the terminal app if macOS prompts for it).
  #
  # LOGIN LAUNCH is owned by the app itself, NOT by a launchd agent. The 0.14
  # beta (Tauri rewrite) has a built-in autostart: aw-tauri writes
  # `[autostart] enabled = true` to ~/Library/Application Support/activitywatch/
  # aw-tauri/config.toml and registers a macOS login item (SMAppService). That
  # launcher also supervises the bundled modules (aw-watcher-afk,
  # aw-watcher-window, aw-sync) with their correct args.
  #
  # We deliberately do NOT add a `launchd.user.agents` KeepAlive agent for the
  # app. aw-tauri is a single-instance GUI app: a launchd agent pointing at the
  # .app binary spawns a SECOND copy that loses the single_instance.lock, exits
  # 0, and gets respawned by KeepAlive every ~10s — flashing the dock forever
  # while the real (RunningBoard-launched) instance runs fine. If autostart ever
  # stops working, re-enable it inside the app (tray/menu → autostart) rather
  # than reintroducing a launchd agent. (The importer agent below is a plain
  # StartInterval script, not the GUI app, so it is exempt from this hazard.)
  #
  # Category rules (what counts as Work/Media/Comms) are edited in the AW web UI
  # (Settings → Categories) and stored in aw-server's own DB — nix does not manage
  # them. The stock rules are Linux/browser-oriented and dump most macOS app time
  # into "Uncategorized", so retune them there. They feed the `productive`
  # sketchybar item (dotfiles/sketchybar/plugins/productive.sh — today's active
  # time under the "Work" tree) and the AW dashboard alike.
  homebrew.casks = [ "activitywatch@beta" ];

  # Periodic Claude Code activity importer (script + rationale in the `let` above).
  # Runs as a user agent (needs ~/.claude read + ~/.local/state write + the
  # per-user aw-server on :5600). Backfills the full history on first run when no
  # state file exists, then imports only newly-closed intervals each tick.
  launchd.user.agents.aw-import-claude = {
    command = "${awImportClaude}/bin/aw-import-claude";
    serviceConfig = {
      Label = "com.user.aw-import-claude";
      # Backfill at login, then every 15 min. Closed intervals need the 8-min gap
      # to settle before they're posted anyway, so a tighter interval buys little.
      RunAtLoad = true;
      StartInterval = 900;
      # If aw-server isn't up yet the script skips cleanly (exit 0) and retries
      # next tick; the state frontier only advances after a successful post, so a
      # skipped run loses nothing. Logs kept so failures surface (never hidden).
      StandardOutPath = "/Users/askielboe/Library/Logs/aw-import-claude.out.log";
      StandardErrorPath = "/Users/askielboe/Library/Logs/aw-import-claude.err.log";
    };
  };
}
