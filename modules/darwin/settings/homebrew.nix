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
      "devonthink"
      "discord"
      "domzilla-caffeine"
      "firefox"
      "ghostty"
      "httpie"
      "jordanbaird-ice" # Hide menu bar icons
      "little-snitch"
      "macfuse"
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
      "zwift"
    ];
  };
}
