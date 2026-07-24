{
  pkgs,
  nixpkgs-unstable,
  sqlit,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # sqlit TUI with the ClickHouse driver. Upstream's makeSqlit only covers
  # extras packaged in nixpkgs (clickhouse-connect is excluded there), so we
  # append it to the dependencies ourselves.
  #
  # The patch fixes an upstream bug (as of a77d420): the TUI's
  # ConnectionManager.populate_credentials only reads the OS keyring and
  # never runs a connection's password_command, so it connects with an
  # empty password. The CLI path (sqlit query) handles it correctly; the
  # patch copies that logic over.
  sqlit-clickhouse =
    (sqlit.lib.${pkgs.stdenv.hostPlatform.system}.makeSqlit {
      extras = [
        "ssh"
        "postgres"
        "mysql"
        "duckdb"
      ];
    }).overridePythonAttrs
      (old: {
        dependencies = old.dependencies ++ [ pkgs.python3.pkgs.clickhouse-connect ];
        patches = (old.patches or [ ]) ++ [ ./sqlit-password-command.patch ];
      });

  # GYB stores client_secrets.json and OAuth tokens in its config folder,
  # which defaults to the directory of the gyb script itself — the read-only
  # nix store. Wrap it to use a writable config folder instead. An explicit
  # --config-folder on the command line still wins (argparse takes the last
  # occurrence).
  gyb-wrapped = pkgs.writeShellScriptBin "gyb" ''
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/gyb"
    mkdir -p "$cfg"
    exec ${pkgs.gyb}/bin/gyb --config-folder "$cfg" "$@"
  '';

  repomix-skeleton = pkgs.writeShellScriptBin "repomix-skeleton" ''
    set -euo pipefail
    target="''${1:-.}"
    mkdir -p "$target/.repomix"
    out="$target/.repomix/skeleton.md"
    ${unstable.repomix}/bin/repomix --compress --output "$out" "$target"
    echo "Wrote $out"
  '';
in

{
  home.packages =
    with pkgs;
    [
      age
      bitwarden-cli
      btop
      bun
      bzip2
      cargo
      ccache
      clickhouse
      clippy
      coreutils
      curl
      d2
      dbt
      deadnix
      deploy-rs
      devbox
      difftastic
      docker
      docker-compose
      duckdb
      duf # Disk usage
      dust # Disk usage by folder
      exiftool
      fd
      ffmpeg
      findutils
      fswatch
      gawk
      gh
      git
      git-annex
      git-filter-repo
      gnugrep
      gnumake
      gnupg
      gnused
      gnutar
      go
      google-cloud-sdk
      gyb-wrapped # Gmail backup; wrapped so config lives in ~/.config/gyb
      hcloud
      htop
      httpie
      hugo
      imagemagick
      jq
      just
      k9s
      killall
      kubectl
      kubernetes-helm
      magic-wormhole
      mariadb
      mise
      mr # myrepos: run sync/status/etc. across many repos at once
      ngrok
      nixfmt # Formatter for nix files
      nixpkgs-review
      npm-check-updates
      openssh
      parallel
      postgresql
      qsv # CSV wrangler
      rclone
      repomix-skeleton
      restic
      resticprofile
      ripgrep
      rsync
      rust-analyzer
      rustc
      rustfmt
      specify-cli # GitHub Spec Kit: bootstrap projects for Spec-Driven Development
      sqlit-clickhouse # TUI for SQL databases, with ClickHouse driver
      sqlite
      ssm-session-manager-plugin
      statix
      taskwarrior3
      taskwarrior-tui
      terraform
      tree
      unstable.devenv
      unstable.repomix
      uv
      wget
      which
      worktrunk # `wt`: git worktree workflow tool
      xh # Rust re-write of httpie
      yazi
      zip
    ]
    # macOS-only: Granola & Things are macOS apps; openpomodoro drives the macOS
    # sketchybar; sourcekit-lsp/xcbeautify are the Swift/Xcode toolchain. Keeping
    # them off Linux is both correct and part of keeping that config lean.
    ++ lib.optionals stdenv.isDarwin [
      mcp-granola
      mcp-things
      openpomodoro-cli
      sourcekit-lsp
      xcbeautify
    ];
}
