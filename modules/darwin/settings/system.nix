_: {
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
        # AeroSpace resizes windows on every layout change; the default ~0.2s
        # resize animation makes tiling feel mushy.
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.001;
        # Activating an app must not yank macOS to another Space — AeroSpace
        # owns workspace placement.
        AppleSpacesSwitchOnActivate = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
        # Keep the native menu bar visible. Must be an explicit false: the
        # sketchybar era wrote true here, and nix-darwin never deletes keys it
        # stops managing, so an unmanaged (absent) key leaves whatever the
        # login session last saw. AeroSpace gaps assume a visible bar.
        _HIHideMenuBar = false;
      };

      # Keep macOS's own window management out of AeroSpace's way.
      WindowManager = {
        # Clicking bare wallpaper (e.g. a gap between tiles) must not hide all windows.
        EnableStandardClickToShowDesktop = false;
        # Disable Sequoia's drag-to-edge tiling suggestions and margins.
        EnableTilingByEdgeDrag = false;
        EnableTopTilingByEdgeDrag = false;
        EnableTilingOptionAccelerator = false;
        EnableTiledWindowMargins = false;
        StandardHideWidgets = true;
        StageManagerHideWidgets = true;
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
        autohide-delay = 0.0;
        show-recents = false;
        tilesize = 56;
        # 1 = disabled; the macOS default puts Quick Note in this corner.
        wvous-br-corner = 1;
        # AeroSpace parks hidden-workspace windows in a corner; grouping by app
        # keeps Mission Control legible (recommended by the AeroSpace docs).
        expose-group-apps = true;
        mru-spaces = false;
        persistent-apps = [
          { app = "/System/Applications/Calendar.app"; }
          { app = "/Applications/Linear.app"; }
          { app = "/System/Applications/Mail.app"; }
          { app = "/Applications/Mimestream.app"; }
          { app = "/Applications/Shortwave.app"; }
          { app = "/System/Applications/Messages.app"; }
          { app = "/Applications/Signal.app"; }
          { app = "/Applications/Slack.app"; }
          { app = "/System/Cryptexes/App/System/Applications/Safari.app"; }
          { app = "/Applications/Claude.app"; }
          { app = "/Applications/Zed.app"; }
          { app = "/Applications/Bear.app"; }
          { app = "/Applications/DEVONthink.app"; }
          { app = "/Applications/1Password.app"; }
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
        FXPreferredViewStyle = "Nlsv";
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

      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable Spotlight search (Cmd+Space)
            "64" = {
              enabled = false;
              value = {
                parameters = [
                  32
                  49
                  1048576
                ];
                type = "standard";
              };
            };
          };
        };
        "com.1password.1password" = {
          NSUserKeyEquivalents = {
            "Search" = "@$f";
          };
        };
        "com.apple.mail" = {
          NSUserKeyEquivalents = {
            "Archive" = "@e";
            "Mailbox Search" = "@$f";
          };
        };
      };
    };
  };

  # Don't change
  system.stateVersion = 4;
}
