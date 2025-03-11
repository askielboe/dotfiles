{ pkgs, agenix, ... }:

{
  home.packages = with pkgs; [
    age
    agenix.packages.${pkgs.system}.default
    aider-chat
    btop
    bzip2
    cargo
    coreutils
    curl
    d2
    dart
    deploy-rs
    devbox
    devenv
    difftastic
    docker
    docker-compose
    duf # Disk usage
    dust # Disk usage by folder
    eza
    ffmpeg
    findutils
    gawk
    gh
    git
    git-annex
    git-filter-repo
    gnugrep
    gnupg
    gnused
    gnutar
    go
    harper # Local LLM spelling language server for developers
    hcloud
    htop
    ipfs
    jq
    killall
    magic-wormhole
    mas
    neovim
    ngrok
    nixpkgs-review
    openssh
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    ripsecrets # Find secrets
    rustic
    sqlite
    ssm-session-manager-plugin
    terraform
    timewarrior
    tmux
    tor
    transmission_4
    tree
    wget
    which
    xh # Send HTTP requests
    yazi
    zip
  ];
}
