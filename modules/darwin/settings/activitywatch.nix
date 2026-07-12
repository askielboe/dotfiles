_: {
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
  # We deliberately do NOT add a `launchd.user.agents` KeepAlive agent here.
  # aw-tauri is a single-instance GUI app: a launchd agent pointing at the .app
  # binary spawns a SECOND copy that loses the single_instance.lock, exits 0, and
  # gets respawned by KeepAlive every ~10s — flashing the dock forever while the
  # real (RunningBoard-launched) instance runs fine. If autostart ever stops
  # working, re-enable it inside the app (tray/menu → autostart) rather than
  # reintroducing a launchd agent.
  #
  # Category rules (what counts as Work/Media/Comms) are edited in the AW web UI
  # (Settings → Categories) and stored in aw-server's own DB — nix does not manage
  # them. The stock rules are Linux/browser-oriented and dump most macOS app time
  # into "Uncategorized", so retune them there. They feed the `productive`
  # sketchybar item (dotfiles/sketchybar/plugins/productive.sh — today's active
  # time under the "Work" tree) and the AW dashboard alike.
  homebrew.casks = [ "activitywatch@beta" ];
}
