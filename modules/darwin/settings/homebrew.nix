{
  lib,
  pkgs,
  private,
  ...
}:
let
  # Single source of truth: these third-party taps populate both the Brewfile and
  # the trust.json written below.
  taps = [
    "beeper/tap"
    "max-sixty/worktrunk"
  ];

  # Homebrew 6.0 refuses to load untrusted third-party taps. During `darwin-rebuild`,
  # `brew bundle` runs under `sudo --preserve-env=PATH`, which strips XDG_CONFIG_HOME,
  # so brew reads ~/.homebrew/trust.json (not the ~/.config copy `brew trust` writes
  # in an interactive shell). Generate the trusted-taps set from `taps` so it always
  # matches the Brewfile; it is installed to ~/.homebrew/trust.json by the activation
  # step below (a writable real file, since brew also writes trust.json.lock there
  # during `--cleanup`).
  trustJson = pkgs.writeText "homebrew-trust.json" (builtins.toJSON { trustedtaps = taps; });
in
{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      # Newer Homebrew requires an explicit force flag for `brew bundle --cleanup`.
      extraFlags = [ "--force-cleanup" ];
    };

    inherit taps;

    brews = [
      "beeper/tap/bbctl"
      "herdr"
      "mas"
      "max-sixty/worktrunk/wt"
    ];

    casks = [
      "1password"
      "1password-cli"
      "adguard"
      "appcleaner"
      "arq"
      "beeper"
      "bitwarden"
      "claude"
      "cyberduck"
      "datagrip"
      "dbeaver-community"
      "devonthink"
      "firefox"
      "ghostty"
      "gitbutler"
      "granola"
      "hammerspoon"
      "handbrake-app"
      "linear"
      "meetingbar"
      "microsoft-teams"
      "mimestream"
      "mixxx"
      "nvidia-geforce-now"
      "postico"
      "proxyman"
      "shortwave"
      "signal"
      "slack"
      "soulver"
      "stats"
      "tigervnc"
      "tor-browser"
      "ungoogled-chromium"
      "visual-studio-code"
      "vlc"
      "zed"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      Bear = 1091189122;
      DaisyDisk = 411643860;
      Keynote = 361285480;
      LookAway = 6747192301;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      Numbers = 361304891;
      Pages = 361309726;
      SponsorBlock = 1573461917;
      TestFlight = 899247664;
      "In Your Face" = 1476964367;
      "Things 3" = 904280696;
      Albums = 1469948986;
      Xcode = 497799835;
    };
  };

  # Install the declarative tap-trust file before `brew bundle` runs (this script
  # is prepended to nix-darwin's own homebrew activation via mkBefore, and runs as
  # root during system activation). It must be a real, user-owned, writable file:
  # brew creates trust.json.lock alongside it during `--cleanup`, so a read-only
  # Nix-store path can't be used here.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    install -d -o ${private.user.username} -g staff -m 700 ${private.user.homeDirectory}/.homebrew
    install -o ${private.user.username} -g staff -m 600 ${trustJson} ${private.user.homeDirectory}/.homebrew/trust.json
  '';
}
