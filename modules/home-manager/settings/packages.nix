{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

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
      dua # Parallel disk usage TUI (dua i = interactive)
      duckdb
      duf # Disk usage
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
      numbat # Soulver for the terminal
      openssh
      parallel
      postgresql
      qsv # CSV wrangler
      radicle-node # `rad`: peer-to-peer, sovereign code collaboration (node + CLI)
      rclone
      repomix-skeleton
      restic
      resticprofile
      ripgrep
      rsync
      rust-analyzer
      rustc
      rustfmt
      sops # edits secrets/secrets.yaml (age recipient in .sops.yaml)
      sqlite
      ssm-session-manager-plugin
      statix
      taskwarrior-tui
      taskwarrior3
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
    # macOS-only: Granola & Things are macOS apps; openpomodoro-cli is the
    # Pomodoro timer (pom* aliases); sourcekit-lsp/xcbeautify are the Swift/Xcode
    # toolchain. Keeping them off Linux is both correct and keeps that config lean.
    ++ lib.optionals stdenv.isDarwin [
      openpomodoro-cli
      sourcekit-lsp
      xcbeautify
    ]
    # Linux-only: dwarfs isn't packaged for darwin in nixpkgs — macOS gets the
    # (mount-less) tools from Homebrew instead (darwin/settings/homebrew.nix).
    ++ lib.optionals stdenv.isLinux [
      dwarfs # DwarFS: fast high-compression read-only FUSE filesystem
    ];
}
