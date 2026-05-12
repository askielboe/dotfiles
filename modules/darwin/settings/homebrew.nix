{ ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    taps = [
      "jeanregisser/tap"
      "lightdash/lightdash"
      "max-sixty/worktrunk"
    ];

    brews = [
      "jeanregisser/tap/bitwarden-cli-bio"
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
      "claude"
      "conductor"
      "cyberduck"
      "datagrip"
      "devonthink"
      "element"
      "firefox"
      "ghostty"
      "gitbutler"
      "granola"
      "hammerspoon"
      "handbrake-app"
      "linear-linear"
      "meetingbar"
      "microsoft-teams"
      "nvidia-geforce-now"
      "obsidian"
      "postico"
      "proxyman"
      "shortwave"
      "slack"
      "soulver"
      "stats"
      "sunsama"
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
      Numbers = 409203825;
      Pages = 409201541;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      TestFlight = 899247664;
      Bitwarden = 1352778147;
      "In Your Face" = 1476964367;
      "Things 3" = 904280696;
      Albums = 1469948986;
      Xcode = 497799835;
    };
  };
}
