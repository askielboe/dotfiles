{ ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    caskArgs.no_quarantine = true;

    casks = [
      "1password"
      "1password-cli"
      "activitywatch"
      "appcleaner"
      "arq"
      "bitwarden"
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "domzilla-caffeine"
      "firefox"
      "ghostty"
      "gpxsee"
      "handbrake"
      "httpie"
      "jordanbaird-ice" # Hide menu bar icons
      "little-snitch"
      "macfuse"
      "microsoft-teams"
      "notion"
      "notion-mail"
      "pocket-casts"
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
      "transmission"
      "vivaldi"
      "vlc"
      "zed"
      "zen"
      "zwift"
    ];
  };
}
