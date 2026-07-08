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
  # Category rules (what counts as Work/Media/Comms) are edited in the AW web UI
  # (Settings → Categories) and stored in aw-server's own DB — nix does not manage
  # them. The stock rules are Linux/browser-oriented and dump most macOS app time
  # into "Uncategorized", so retune them there. They feed the `productive`
  # sketchybar item (dotfiles/sketchybar/plugins/productive.sh — today's active
  # time under the "Work" tree) and the AW dashboard alike.
  homebrew.casks = [ "activitywatch@beta" ];

  # Launch the ActivityWatch desktop app at login. The 0.14 beta is the Tauri
  # rewrite: the launcher is aw-tauri (not the old aw-qt tray), and it supervises
  # the bundled aw-server-rust + aw-watcher-afk + aw-watcher-window (under
  # Contents/Resources). KeepAlive relaunches it if it exits.
  launchd.user.agents.activitywatch = {
    serviceConfig = {
      Label = "net.activitywatch.aw-tauri";
      ProgramArguments = [ "/Applications/ActivityWatch.app/Contents/MacOS/aw-tauri" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/askielboe/Library/Logs/activitywatch/aw-tauri.out.log";
      StandardErrorPath = "/Users/askielboe/Library/Logs/activitywatch/aw-tauri.err.log";
    };
  };

  # launchd will not create the log directory, so ensure it exists.
  home-manager.users.askielboe.home.file."Library/Logs/activitywatch/.keep".text = "";
}
