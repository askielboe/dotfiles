{ ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    caskArgs.no_quarantine = true;

    taps = [
      "lightdash/lightdash"
      "max-sixty/worktrunk"
    ];

    brews = [
      "lightdash"
      "mas"
      "max-sixty/worktrunk/wt"
      "neonctl"
    ];

    casks = [
      "1password"
      "1password-cli"
      "adguard"
      "appcleaner"
      "arq"
      "bartender"
      "bitwarden"
      "claude"
      "cloudflare-warp"
      "cyberduck"
      "devonthink"
      "discord"
      "element"
      "ghostty"
      "granola"
      "hammerspoon"
      "handbrake-app"
      "microsoft-teams"
      "notion"
      "plex"
      "postico"
      "proxyman"
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
      "zoom"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      Bear = 1091189122;
      DaisyDisk = 411643860;
      Keynote = 409183694;
      LookAway = 6747192301;
      Numbers = 409203825;
      Pages = 409201541;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      TestFlight = 899247664;
      "Things 3" = 904280696;
      Xcode = 497799835;
    };
  };
}
