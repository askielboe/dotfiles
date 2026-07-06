{
  pkgs,
  nixpkgs-unstable,
  sqlit,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # sqlit TUI with the ClickHouse driver. Upstream's makeSqlit only covers
  # extras packaged in nixpkgs (clickhouse-connect is excluded there), so we
  # append it to the dependencies ourselves.
  sqlit-clickhouse =
    (sqlit.lib.${pkgs.stdenv.hostPlatform.system}.makeSqlit {
      extras = [
        "ssh"
        "postgres"
        "mysql"
        "duckdb"
      ];
    }).overridePythonAttrs
      (old: {
        dependencies = old.dependencies ++ [ pkgs.python3.pkgs.clickhouse-connect ];
      });

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
    google-cloud-sdk
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
    mr # myrepos: run sync/status/etc. across many repos at once
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
    specify-cli # GitHub Spec Kit: bootstrap projects for Spec-Driven Development
    sqlit-clickhouse # TUI for SQL databases, with ClickHouse driver
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
