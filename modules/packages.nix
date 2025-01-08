{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # System and Core Utilities
    btop
    bzip2
    coreutils
    gnused
    htop
    killall
    sqlite
    tree
    wget
    yazi
    zip

    # Terminal and Text Tools
    ripgrep
    tmux
    neovim
    difftastic
    jq

    # Version Control and Git Tools
    git
    git-annex

    # Development Tools and SDKs
    aider-chat
    cargo
    d2
    devenv
    nodePackages.npm
    nodePackages.prettier
    nodejs

    # Cloud and Container Tools
    docker
    docker-compose
    ssm-session-manager-plugin
    ngrok

    # Backup and Sync Tools
    magic-wormhole
    rclone
    restic
    rustic

    # Security and Encryption
    age
    gnupg
    openssh
    tor

    # Media Processing
    ffmpeg

    # MacOS Tools and SDKs
    mas
  ];
}
