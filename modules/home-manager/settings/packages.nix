{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in

{
  home.packages = with pkgs; [
    age
    aichat
    btop
    bzip2
    cargo
    ccache
    clippy
    coreutils
    curl
    d2
    dbt
    deploy-rs
    devbox
    devenv
    difftastic
    docker
    docker-compose
    duckdb
    duf # Disk usage
    dust # Disk usage by folder
    fd
    ffmpeg
    findutils
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
    jq
    just
    k9s
    killall
    kubectl
    kubernetes-helm
    magic-wormhole
    mariadb
    ngrok
    nixpkgs-review
    npm-check-updates
    openssh
    parallel
    postgresql
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    rust-analyzer
    rustfmt
    shellcheck
    sqlite
    ssm-session-manager-plugin
    terraform
    timewarrior
    tree
    unstable.claude-code
    unstable.rustic
    uv
    wget
    which
    xcbeautify
    xh # Rust re-write of httpie
    yazi
    zip
  ];
}
