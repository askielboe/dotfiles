{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

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
  home.packages = with pkgs; [
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
    mcp-granola
    mcp-things
    mise
    ngrok
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
    sourcekit-lsp
    sqlite
    ssm-session-manager-plugin
    terraform
    tree
    unstable.devenv
    unstable.repomix
    uv
    wget
    which
    xcbeautify
    xh # Rust re-write of httpie
    yazi
    zip
  ];
}
