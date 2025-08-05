{ ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    caskArgs.no_quarantine = true;

    casks = [
      "1password"
      "1password-cli"
      "appcleaner"
      "arq"
      "bitwarden"
      "claude"
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "domzilla-caffeine"
      "firefox"
      "ghostty"
      "gpxsee"
      "handbrake-app"
      "jordanbaird-ice" # Hide menu bar icons
      "little-snitch"
      "macfuse"
      "microsoft-teams"
      "mimestream"
      "pocket-casts"
      "postico"
      "proxyman"
      "qobuz"
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
