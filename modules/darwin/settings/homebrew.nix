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
      "zwift"
      "brave-browser"
      "cyberduck"
      "devonthink"
      "discord"
      "docker"
      "domzilla-caffeine"
      "ghostty"
      "gitbutler"
      "jordanbaird-ice" # Hide menu bar icons
      "little-snitch"
      "macfuse"
      "notion"
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
      "sunsama"
      "tor-browser"
      "transmission"
      "vlc"
      "zed"
    ];
  };
}
