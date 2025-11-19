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
      "lightdash"
    ];

    casks = [
      "1password"
      "1password-cli"
      "appcleaner"
      "arq"
      "bitwarden"
      "chatgpt"
      "claude"
      "cloudflare-warp"
      "creative"
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "ghostty"
      "gitbutler"
      "handbrake-app"
      "jordanbaird-ice" # Hide menu bar icons
      "macfuse"
      "microsoft-teams"
      "postico"
      "proxyman"
      "raycast"
      "reactotron"
      "signal"
      "slack"
      "sonos"
      "spotify"
      "stats"
      "steam"
      "timing"
      "tor-browser"
      "trainerroad"
      "transmission"
      "vlc"
      "zed"
      "zen"
      "zwift"
    ];
  };
}
