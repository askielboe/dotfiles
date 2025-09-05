{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in

{
  home.packages = with pkgs; [
    age
    btop
    bzip2
    coreutils
    curl
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
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    sqlite
    ssm-session-manager-plugin
    timewarrior
    tree
    unstable.claude-code
    wget
    which
    xh # Rust re-write of httpie
    yazi
    zip
  ];
}
