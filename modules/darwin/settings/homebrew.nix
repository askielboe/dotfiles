_: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      # Newer Homebrew requires an explicit force flag for `brew bundle --cleanup`.
      extraFlags = [ "--force-cleanup" ];
    };

    taps = [
      "max-sixty/worktrunk"
    ];

    brews = [
      "mas"
      "max-sixty/worktrunk/wt"
    ];

    casks = [
      "1password"
      "1password-cli"
      "adguard"
      "appcleaner"
      "arq"
      "claude"
      "cyberduck"
      "datagrip"
      "devonthink"
      "firefox"
      "ghostty"
      "gitbutler"
      "granola"
      "hammerspoon"
      "handbrake-app"
      "linear"
      "meetingbar"
      "microsoft-teams"
      "mimestream"
      "nvidia-geforce-now"
      "postico"
      "proxyman"
      "signal"
      "slack"
      "soulver"
      "stats"
      "tigervnc"
      "tor-browser"
      "ungoogled-chromium"
      "vlc"
      "zed"
      "zoom"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      Bear = 1091189122;
      DaisyDisk = 411643860;
      Keynote = 409183694;
      LookAway = 6747192301;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      SponsorBlock = 1573461917;
      TestFlight = 899247664;
      Bitwarden = 1352778147;
      "In Your Face" = 1476964367;
      "Things 3" = 904280696;
      Albums = 1469948986;
      Xcode = 497799835;
    };
  };
}
