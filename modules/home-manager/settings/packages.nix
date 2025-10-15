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
    dbt
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
    k9s
    killall
    kubectl
    kubernetes-helm
    magic-wormhole
    mariadb
    ngrok
    nil
    nixd
    nixfmt-rfc-style
    npm-check-updates
    openssh
    parallel
    postgresql
    qsv # CSV wrangler
    rclone
    restic
    resticprofile
    ripgrep
    ruff
    sqlite
    ssm-session-manager-plugin
    terraform
    timewarrior
    tree
    unstable.claude-code
    unstable.cursor-cli
    uv
    wget
    which
    xh # Rust re-write of httpie
    yazi
    zip
  ];
}
