{ ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    caskArgs.no_quarantine = true;

    taps = [
      "lightdash/lightdash"
    ];

    brews = [
      "claude-squad"
      "lightdash"
      "mas"
    ];

    casks = [
      "1password"
      "1password-cli"
      "anytype"
      "appcleaner"
      "arq"
      "bitwarden"
      "claude"
      "cloudflare-warp"
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "ghostty"
      "handbrake-app"
      "microsoft-teams"
      "notion"
      "plex"
      "postico"
      "proxyman"
      "raycast"
      "reactotron"
      "signal"
      "slack"
      "sonos"
      "stats"
      "steam"
      "tor-browser"
      "trainerroad"
      "transmission"
      "vlc"
      "zed"
      "zen"
      "zoom"
      "zwift"
    ];

    masApps = {
      "1Blocker" = 1365531024;
      "1Password for Safari" = 1569813296;
      Bear = 1091189122;
      DaisyDisk = 411643860;
      Jomo = 1609960918;
      Keynote = 409183694;
      LookAway = 6747192301;
      Magnet = 441258766;
      Messenger = 1480068668;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      TestFlight = 899247664;
      "Things 3" = 904280696;
      Xcode = 497799835;
    };
  };
}
