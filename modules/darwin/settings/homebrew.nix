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
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "ghostty"
      "handbrake-app"
      "jordanbaird-ice" # Hide menu bar icons
      "microsoft-teams"
      "postico"
      "proxyman"
      "raycast"
      "reactotron"
      "signal"
      "slack"
      "sonos"
      "stats"
      "steam"
      "thingsmacsandboxhelper"
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
