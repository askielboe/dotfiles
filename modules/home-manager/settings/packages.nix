{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };

  pay-respects-with-ai = pkgs.callPackage ../../../pkgs/pay-respects.nix { };
in

{
  home.packages = with pkgs; [
    age
    btop
    bzip2
    coreutils
    curl
    dbt
    devbox
    devenv
    difftastic
    docker
    docker-compose
    duf # Disk usage
    dust # Disk usage by folder
    eza # ls replacement
    fasttext # Language detection for Language Tool
    ffmpeg
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    go
    htop
    httpie
    hugo
    jq
    k9s
    killall
    kubectl
    kubernetes-helm
    languagetool
    magic-wormhole
    mariadb
    ngrok
    nil
    nixd
    nixfmt-rfc-style
    npm-check-updates
    openssh
    parallel
    pay-respects-with-ai
    postgresql
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    ruff
    sqlfluff # SQL linter and formatter
    sqlite
    ssm-session-manager-plugin
    terraform
    timewarrior
    tree
    unstable.claude-code
    uv
    wget
    which
    xh # Rust re-write of httpie
    yazi
    zip
  ];
}
