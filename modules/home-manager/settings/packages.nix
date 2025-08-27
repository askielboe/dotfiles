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
    killall
    magic-wormhole
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
    yazi
    zip
  ];
}
