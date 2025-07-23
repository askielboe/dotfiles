{ pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in

{
  # Shared packages for both Darwin and NixOS
  home.packages = with pkgs; [
    # Essential tools
    git
    curl
    openssh
    ripgrep
    eza
    btop
    unstable.claude-code

    # Development and system tools (shared between platforms)
    age
    bzip2
    coreutils
    devbox
    devenv
    difftastic
    docker
    docker-compose
    duf # Disk usage
    dust # Disk usage by folder
    ffmpeg
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    go
    htop
    httpie
    jq
    killall
    magic-wormhole
    ngrok
    nil
    nixd
    nixfmt-rfc-style
    npm-check-updates
    parallel
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    sqlite
    ssm-session-manager-plugin
    timewarrior
    tree
    wget
    which
    yazi
    zip
  ];
}

