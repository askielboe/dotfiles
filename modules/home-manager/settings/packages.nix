{ pkgs, ... }:

{
  home.packages = with pkgs; [
    age
    aider-chat
    btop
    bzip2
    cargo
    colima # Container runtimes on macOS (and Linux) with minimal setup
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
    httpie
    ipfs
    jq
    killall
    llm
    magic-wormhole
    mas
    ngrok
    nil
    nixd
    nixfmt-rfc-style
    nixpkgs-review
    npm-check-updates
    openssh
    parallel
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    ripsecrets # Find secrets
    rustic
    sops
    sqlite
    ssm-session-manager-plugin
    timewarrior
    tmux
    tor
    transmission_4
    tree
    wget
    which
    xh # Send HTTP requests
    yazi
    yt-dlp
    zip
  ];
}
