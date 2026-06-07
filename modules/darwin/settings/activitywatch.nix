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
  homebrew.casks = [ "activitywatch@beta" ];

  # Launch the aw-qt tray at login. aw-qt is the supervisor that spawns and keeps
  # aw-server, aw-watcher-afk and aw-watcher-window running. KeepAlive relaunches
  # it if it exits. Path is the standard bundle launcher — confirm it exists after
  # the cask first installs (ls /Applications/ActivityWatch.app/Contents/MacOS).
  launchd.user.agents.activitywatch = {
    serviceConfig = {
      Label = "net.activitywatch.aw-qt";
      ProgramArguments = [ "/Applications/ActivityWatch.app/Contents/MacOS/aw-qt" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/askielboe/Library/Logs/activitywatch/aw-qt.out.log";
      StandardErrorPath = "/Users/askielboe/Library/Logs/activitywatch/aw-qt.err.log";
    };
  };

  # launchd will not create the log directory, so ensure it exists.
  home-manager.users.askielboe.home.file."Library/Logs/activitywatch/.keep".text = "";
}
