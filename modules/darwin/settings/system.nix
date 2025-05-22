{ ... }:
{
  system = {
    primaryUser = "askielboe";

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
        FocusModes = false;
        NowPlaying = false;
        Sound = true;
      };

      dock = {
        autohide = true;

        show-recents = false;

        persistent-apps = [
          { app = "/System/Applications/Calendar.app"; }
          { app = "/System/Applications/Mail.app"; }
          { app = "/Applications/Vivaldi.app"; }
          { app = "/Applications/Things3.app"; }
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

      # persistent-others
      # https://github.com/nix-darwin/nix-darwin/pull/1004#issuecomment-2440899127
      CustomUserPreferences = {
        # Sets Downloads folder with fan view in Dock
        "com.apple.dock" = {
          persistent-others = [
            {
              "tile-data" = {
                "file-data" = {
                  "_CFURLString" = "/Users/askielboe/Downloads";
                  "_CFURLStringType" = 0;
                };
                "arrangement" = 2; # sorting order
                "displayas" = 1; # 1 for fan display
                "showas" = 1; # 1 for stack view
              };
              "tile-type" = "directory-tile";
            }
            {
              "tile-data" = {
                "file-data" = {
                  "_CFURLString" = "/Applications";
                  "_CFURLStringType" = 0;
                };
                "arrangement" = 2; # sorting order
                "displayas" = 1; # 1 for fan display
                "showas" = 1; # 1 for stack view
              };
              "tile-type" = "directory-tile";
            }
          ];
        };
      };
    };
  };

  # Don't change
  system.stateVersion = 4;
}
