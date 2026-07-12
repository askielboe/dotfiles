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
    "herald-email/herald"
    "joncrangle/tap"
    "nikitabobko/tap"
    "raine/claude-history"
  ];

  # Third-party CLI formulae (non-casks). Declared here in the `let` (rather than
  # inline under `homebrew`) so the activation-time "outdated formula" warning below
  # can match these against `brew outdated` output. These are stopgaps we'd rather
  # get from nixpkgs (or drop) eventually.
  brews = [
    "herald-email/herald/herald"
    "herdr"
    # Next-meeting glyph in sketchybar (plugins/meeting.sh) reads EventKit via icalBuddy.
    "ical-buddy"
    "mas"
    # Push-based sketchybar event provider (system_stats event); started by sketchybarrc.
    "joncrangle/tap/sketchybar-system-stats"
    "raine/claude-history/claude-history"
  ];

  # Leaf names (tap prefix stripped) — `brew outdated` prints short names, so match on these.
  brewLeaves = map (b: lib.last (lib.splitString "/" b)) brews;

  # The activation-time "outdated formula" warning lives in a sibling shell script so it
  # gets editor tooling (highlighting/shellcheck) instead of a nix heredoc. nix passes it
  # the primary user + declared formulae as args; see the file header for details.
  brewOutdatedWarning = pkgs.writeShellScript "brew-outdated-warning" (
    builtins.readFile ./brew-outdated-warning.sh
  );

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

    inherit brews;

    casks = [
      "1password"
      "1password-cli"
      "activitywatch@beta"
      "adguard"
      "appcleaner"
      "arq"
      "bitwarden"
      "claude"
      "cyberduck"
      "dbeaver-community"
      "devonthink"
      "firefox"
      "ghostty"
      "gitbutler"
      "granola"
      "handbrake-app"
      "linear"
      "meetingbar"
      "microsoft-teams"
      "mimestream"
      "mixxx"
      "nikitabobko/tap/aerospace"
      "nvidia-geforce-now"
      "postico"
      "proxyman"
      "shortwave"
      "signal"
      "slack"
      "soulver"
      "stats"
      "tigervnc"
      "todoist-app"
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
      Portal = 1436994560;
      "Save to Matter" = 1548677272;
      SponsorBlock = 1573461917;
      TestFlight = 899247664;
      "In Your Face" = 1476964367;
      "Things 3" = 904280696;
      Xcode = 497799835;
    };
  };

  # Install the declarative tap-trust file before `brew bundle` runs (this script
  # is prepended to nix-darwin's own homebrew activation via mkBefore, and runs as
  # root during system activation). It must be a real, user-owned, writable file:
  # brew creates trust.json.lock alongside it during `--cleanup`, so a read-only
  # Nix-store path can't be used here.
  system.activationScripts.homebrew.text = lib.mkMerge [
    (lib.mkBefore ''
      install -d -o ${private.user.username} -g staff -m 700 ${private.user.homeDirectory}/.homebrew
      install -o ${private.user.username} -g staff -m 600 ${trustJson} ${private.user.homeDirectory}/.homebrew/trust.json
    '')

    # After `brew bundle`: warn (never fail) when a declared formula is outdated.
    # `|| true` guards against activation running under `set -e`.
    (lib.mkAfter ''
      ${brewOutdatedWarning} ${private.user.username} ${lib.concatStringsSep " " brewLeaves} || true
    '')
  ];
}
