{ ... }: {
  system = {
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;

    defaults = {
      NSGlobalDomain = {
        # Dark mode
        AppleInterfaceStyle = "Dark";

        # Show all file extensions
        AppleShowAllExtensions = true;

        # Enable moving window by holding anywhere on it like on Linux
        NSWindowShouldDragOnGesture = true;

        "com.apple.trackpad.forceClick" = false;
      };

      alf = {
        # Enable firewall
        globalstate = 1;

        # Drop incoming requests via ICMP such as ping requests.
        stealthenabled = 1;
      };

      controlcenter = {
        BatteryShowPercentage = true;
        Bluetooth = true;
        Display = true;
        FocusModes = false;
        NowPlaying = false;
        Sound = true;
      };

      dock = {
        autohide = true;

        show-recents = false;

        persistent-apps = [
          # { app = "/System/Library/CoreServices/Finder.app"; }
          { app = "/System/Applications/Calendar.app"; }
          { app = "/Applications/Brave Browser.app"; }
          { app = "/Applications/Todoist.app"; }
          { app = "/System/Applications/Messages.app"; }
          { app = "/Applications/Signal.app"; }
          { app = "/Applications/Slack.app"; }
          { app = "/Applications/Ghostty.app"; }
          { app = "/Applications/1Password.app"; }
          { app = "/Applications/Bear.app"; }
          { app = "/Applications/Spotify.app"; }
          { app = "/Applications/DEVONthink 3.app"; }
          { app = "/Applications/Zed.app"; }
        ];

        persistent-others = [
          "/Users/askielboe/Downloads"
          "/Applications"
        ];
      };

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
        FXRemoveOldTrashItems = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
      };

      loginwindow = {
        GuestEnabled = false;
        autoLoginUser = "askielboe";
      };

      menuExtraClock.ShowDate = 1;
    };
  };

  # Don't change
  system.stateVersion = 4;
}
