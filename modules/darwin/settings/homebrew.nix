{
  lib,
  pkgs,
  private,
  ...
}:
let
  # Single source of truth: these third-party taps populate both the Brewfile and
  # the trust.json written below. They are ALSO pinned to flake.lock via nix-homebrew
  # (see the `nix-homebrew.taps` block in flake.nix). Keep the two lists in sync:
  # here they use Homebrew's short form (owner/<name>); there the on-disk repo form
  # (owner/homebrew-<name>). Both resolve to the same tap directory.
  taps = [
    "macos-fuse-t/cask" # fuse-t (kext-less FUSE, used by rclone mount)
    "nikitabobko/tap" # aerospace
    "raine/claude-history"
  ];

  # Third-party CLI formulae (non-casks). Declared here in the `let` (rather than
  # inline under `homebrew`) so the activation-time "outdated formula" warning below
  # can match these against `brew outdated` output. These are stopgaps we'd rather
  # get from nixpkgs (or drop) eventually.
  brews = [
    # nixpkgs' dwarfs is Linux-only, hence the brew fallback here (Linux gets it
    # from nixpkgs in home-manager packages.nix). Note: homebrew-core builds with
    # -DWITH_FUSE_DRIVER=OFF, so this ships mkdwarfs/dwarfsck/dwarfsextract but
    # no `dwarfs` mount command (homebrew-core forbids macFUSE/FUSE-T deps).
    "dwarfs"
    "herdr"
    "mas"
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
      # Activation-time `brew bundle` runs under `sudo --preserve-env=PATH`, so the
      # HOMEBREW_NO_ENV_HINTS session variable (home-manager, interactive shells only)
      # never reaches it. extraEnv prepends KEY=VALUE onto the bundle invocation itself,
      # so the hint block is silenced during `hs` too — not just in interactive shells.
      extraEnv = {
        HOMEBREW_NO_ENV_HINTS = "1";
      };
    };

    inherit taps;

    inherit brews;

    casks = [
      "1password"
      "1password-cli"
      "adguard"
      "aerial"
      "appcleaner"
      "arq"
      "brave-browser"
      "chatgpt"
      "claude"
      "claude-status-bar"
      "codexbar"
      "cyberduck"
      "dbeaver-community"
      "devonthink"
      "firefox"
      "ghostty"
      "gitbutler"
      "granola"
      "handbrake-app"
      "hiddenbar"
      "linear"
      "macos-fuse-t/cask/fuse-t"
      "meetingbar"
      "microsoft-teams"
      "mimestream"
      "mixxx"
      "nikitabobko/tap/aerospace"
      "notunes"
      "nvidia-geforce-now"
      "postico"
      "proxyman"
      "qobuz"
      "signal"
      "slack"
      "sony-ps-remote-play"
      "stats"
      "steam"
      "sunsama"
      "tigervnc"
      "todoist"
      "tor-browser"
      "vlc"
      "zed"
      "zotero"
    ];

    masApps = {
      "1Password for Safari" = 1569813296;
      Bear = 1091189122;
      Bitwarden = 1352778147;
      DaisyDisk = 411643860;
      Keynote = 361285480;
      LookAway = 6747192301;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      "Noir – Dark Mode for Safari" = 1592917505;
      Numbers = 361304891;
      Pages = 361309726;
      Portal = 1436994560;
      "Save to Matter" = 1548677272;
      SponsorBlock = 1573461917;
      TestFlight = 899247664;
      "In Your Face" = 1476964367;
      "Things 3" = 904280696;
      "Tock Timer" = 6757497053;
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
      # Interactive `brew` (run as the user, with XDG_CONFIG_HOME=~/.config) reads a
      # *different* trust file than the sudo activation context above. Write the same
      # generated file there too so ad-hoc `brew upgrade`/`install` trusts the declared
      # taps without a per-command warning, and stale hand-added trusts don't accrete.
      install -d -o ${private.user.username} -g staff -m 700 ${private.user.homeDirectory}/.config/homebrew
      install -o ${private.user.username} -g staff -m 600 ${trustJson} ${private.user.homeDirectory}/.config/homebrew/trust.json
    '')

    # After `brew bundle`: warn (never fail) when a declared formula is outdated.
    # `|| true` guards against activation running under `set -e`.
    (lib.mkAfter ''
      ${brewOutdatedWarning} ${private.user.username} ${lib.concatStringsSep " " brewLeaves} || true
    '')
  ];
}
