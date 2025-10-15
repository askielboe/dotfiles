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
      "bleunlock"
      "bruno"
      "chatgpt"
      "claude"
      "creative"
      "cyberduck"
      "db-browser-for-sqlite"
      "dbeaver-community"
      "devonthink"
      "discord"
      "domzilla-caffeine"
      "firefox"
      "ghostty"
      "gitbutler"
      "gpxsee"
      "handbrake-app"
      "jordanbaird-ice" # Hide menu bar icons
      "little-snitch"
      "macfuse"
      "microsoft-teams"
      "mimestream"
      "netdownloadhelpercoapp"
      "notion"
      "pocket-casts"
      "postico"
      "proxyman"
      "qobuz"
      "raycast"
      "reactotron"
      "signal"
      "slack"
      "sonos"
      "spotify"
      "stats"
      "steam"
      "sunsama"
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
