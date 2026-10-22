{
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  gws-account =
    account:
    pkgs.writeShellScriptBin "gws-${account}" ''
      set -euo pipefail
      umask 077

      # Inherited auth overrides would silently bypass the account's credential store.
      unset GOOGLE_WORKSPACE_CLI_TOKEN GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE
      unset GOOGLE_WORKSPACE_CLI_CLIENT_ID GOOGLE_WORKSPACE_CLI_CLIENT_SECRET
      unset GOOGLE_APPLICATION_CREDENTIALS GOOGLE_WORKSPACE_PROJECT_ID
      export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/gws/${account}"
      mkdir -p "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"
      chmod 700 "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"

      # gws otherwise falls back to shared gcloud ADC when this account has no credentials.
      case "''${1:-}" in
        auth|schema|--help|-h|--version|-V|"") ;;
        *)
          if [ ! -f "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR/credentials.enc" ] &&
             [ ! -f "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR/credentials.json" ]; then
            echo "${account} is not authenticated. Run gws-${account} auth login first." >&2
            exit 1
          fi
          ;;
      esac
      exec ${pkgs.gws}/bin/gws "$@"
    '';

  # GYB stores client_secrets.json and OAuth tokens in its config folder,
  # which defaults to the directory of the gyb script itself — the read-only
  # nix store. Wrap it to use a writable config folder instead. An explicit
  # --config-folder on the command line still wins (argparse takes the last
  # occurrence).
  gyb-wrapped = pkgs.writeShellScriptBin "gyb" ''
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/gyb"
    mkdir -p "$cfg"
    exec ${pkgs.gyb}/bin/gyb --config-folder "$cfg" "$@"
  '';

  # Sharing the app's client keeps MCP OAuth state compatible after app updates.
  codex-app-cli = pkgs.writeShellScriptBin "codex" ''
    appCodex=/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
    if [ ! -x "$appCodex" ]; then
      echo "Codex CLI is missing or not executable at $appCodex" >&2
      exit 1
    fi
    # The GUI uses the shared default; terminal sessions use the CLI profile.
    defaultProfile=(--profile cli)
    for arg in "$@"; do
      case "$arg" in
        -p|--profile|-p?*|--profile=*) defaultProfile=(); break ;;
      esac
    done
    exec "$appCodex" "''${defaultProfile[@]}" "$@"
  '';

  rex-app-cli = pkgs.writeShellScriptBin "rex" ''
    exec "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex" "$@"
  '';

  cass = pkgs.stdenvNoCC.mkDerivation {
    pname = "cass";
    version = "0.10.0";
    src = pkgs.fetchurl {
      url = "https://github.com/Dicklesworthstone/coding_agent_session_search/releases/download/v0.10.0/cass-darwin-arm64.tar.gz";
      hash = "sha256:1d922fd59b252bc3b4af63dbce5e4007c2f505ba1d6a8cec0a7280b169200580";
    };
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      install -Dm755 cass "$out/bin/cass"
    '';
    meta.platforms = [ "aarch64-darwin" ];
  };

  enzyme = pkgs.stdenvNoCC.mkDerivation {
    pname = "enzyme";
    version = "0.9.2";
    src = pkgs.fetchurl {
      url = "https://github.com/byenzyme/enzyme/releases/download/v0.9.2/enzyme-macos-arm64.tar.gz";
      hash = "sha256-4jMDGWvZgXE+Ngf/VkGXgYuoTfeLfF4FxpzVcWsXwb0=";
    };
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;
    installPhase = ''
      install -Dm755 enzyme "$out/bin/enzyme"
    '';
    meta.platforms = [ "aarch64-darwin" ];
  };

  # nixpkgs's Darwin build still enables X11, omits IOKit linkage, and mishandles its generated app bundle.
  recoll =
    if pkgs.stdenv.isDarwin then
      pkgs.recoll.overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [ "-Dx11mon=false" ];
        env = old.env // {
          NIX_LDFLAGS = "-framework IOKit";
        };
        postInstall = pkgs.lib.replaceString "$out/bin/recoll.app" "qtgui/recoll.app" old.postInstall + ''
          rm $out/bin/recoll
        '';
        postFixup = old.postFixup + ''
          install_name_tool -add_rpath $out/lib $out/Applications/recoll.app/Contents/MacOS/.recoll-wrapped
        '';
      })
    else
      pkgs.recoll;

  # Pi owns the package installation so the terminal and agent use the same version.
  openwiki = pkgs.writeShellScriptBin "openwiki" ''
    cli="$HOME/.pi/agent/npm/node_modules/openwiki/dist/cli/cli.js"
    if [ ! -f "$cli" ]; then
      echo "OpenWiki is not installed yet. Start Pi after applying the Nix configuration." >&2
      exit 1
    fi
    exec ${pkgs.nodejs_26}/bin/node "$cli" "$@"
  '';

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
  xdg.configFile = {
    "mcporter/mcporter.json".text = builtins.toJSON {
      imports = [ ];
      mcpServers = {
        "1password" = {
          description = "1Password Developer Environments";
          command = "1password-mcp";
        };
        tana = {
          description = "Tana workspace";
          baseUrl = "https://home.tana.inc/mcp";
          auth = "oauth";
        };
        granola = {
          description = "Granola meeting notes";
          baseUrl = "https://mcp.granola.ai/mcp";
          auth = "oauth";
        };
      };
    };
  };

  home.packages =
    with pkgs;
    [
      age
      basic-memory
      bitwarden-cli
      btop
      bun
      bzip2
      cargo
      ccache
      clang-tools
      clickhouse
      clippy
      coreutils
      curl
      d2
      dbt
      deadnix
      deploy-rs
      devbox
      difftastic
      docker
      docker-compose
      dua # Parallel disk usage TUI (dua i = interactive)
      duckdb
      duf # Disk usage
      exiftool
      fd
      ffmpeg
      findutils
      fswatch
      gawk
      gh
      git-annex
      git-filter-repo
      gnugrep
      gnumake
      gnupg
      gnused
      gnutar
      go
      google-cloud-sdk
      gws
      (gws-account "mo2tion")
      (gws-account "hccreators")
      gyb-wrapped # Gmail backup; wrapped so config lives in ~/.config/gyb
      hcloud
      htop
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
      mcporter
      meson
      mise
      mr # myrepos: run sync/status/etc. across many repos at once
      ngrok
      nixfmt # Formatter for nix files
      nixpkgs-review
      npm-check-updates
      numbat # Soulver for the terminal
      openssh
      openwiki
      parallel
      postgresql
      qsv # CSV wrangler
      rclone
      rea
      recoll
      repomix-skeleton
      restic
      resticprofile
      ripgrep
      rsync
      rust-analyzer
      rustc
      rustfmt
      sops # edits secrets/secrets.yaml (age recipient in .sops.yaml)
      sqlite
      ssm-session-manager-plugin
      statix
      taskwarrior-tui
      taskwarrior3
      terraform
      tree
      unstable.devenv
      unstable.repomix
      uv
      watch
      wget
      worktrunk # `wt`: git worktree workflow tool
      xh # Rust re-write of httpie
      yazi
      yq
      zip
    ]
    # macOS-only: Granola & Things are macOS apps; openpomodoro-cli is the
    # Pomodoro timer (pom* aliases); sourcekit-lsp/xcbeautify are the Swift/Xcode
    # toolchain. Keeping them off Linux is both correct and keeps that config lean.
    ++ lib.optionals stdenv.isDarwin [
      cass
      codex-app-cli
      enzyme
      openpomodoro-cli
      rex-app-cli
      sourcekit-lsp
      xcbeautify
    ]
    # Linux-only: dwarfs isn't packaged for darwin in nixpkgs — macOS gets the
    # (mount-less) tools from Homebrew instead (darwin/settings/homebrew.nix).
    ++ lib.optionals stdenv.isLinux [
      unstable.codex
      dwarfs # DwarFS: fast high-compression read-only FUSE filesystem
    ];
}
