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
      };

      dock = {
        # Automatically hide and show the Dock
        autohide = true;

        # Style options
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
      };

      finder = {
        AppleShowAllExtensions = true;
        _FXShowPosixPathInTitle = true;
      };
    };
  };

  # Don't change
  system.stateVersion = 4;
}
