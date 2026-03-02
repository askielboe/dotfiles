{ ... }:
{
  system = {
    primaryUser = "askielboe";

    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;

    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        NSWindowShouldDragOnGesture = true;
        "com.apple.trackpad.forceClick" = false;
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 300; # Not working?
      };

      screencapture = {
        target = "clipboard";
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
        show-recents = true;
        persistent-apps = [
          { app = "/System/Applications/Calendar.app"; }
          { app = "/Applications/Things3.app"; }
          { app = "/System/Applications/Mail.app"; }
          { app = "/System/Applications/Messages.app"; }
          { app = "/Applications/Signal.app"; }
          { app = "/Applications/Slack.app"; }
          { app = "/System/Cryptexes/App/System/Applications/Safari.app"; }
          { app = "/Applications/Claude.app"; }
          { app = "/Applications/Zed.app"; }
          { app = "/Applications/Bear.app"; }
          { app = "/Applications/DEVONthink 3.app"; }
          { app = "/Applications/1Password.app"; }
          { app = "/System/Applications/Music.app"; }
          { app = "/Applications/Ghostty.app"; }
        ];
        persistent-others = [
          {
            folder = {
              path = "/Users/askielboe/Downloads";
              showas = "fan";
              arrangement = "date-added";
            };
          }
          {
            folder = {
              path = "/Applications";
              showas = "fan";
              arrangement = "date-added";
            };
          }
        ];
      };

      finder = {
        AppleShowAllExtensions = true;
        FXRemoveOldTrashItems = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
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
