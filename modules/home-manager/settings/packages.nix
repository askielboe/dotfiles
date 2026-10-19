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
    exec "$appCodex" "$@"
  '';

  hax = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "hax";
    version = "0.6.1";

    src = pkgs.fetchurl {
      url = "https://github.com/OleksandrChekhovskyi/hax/releases/download/v${finalAttrs.version}/hax-${finalAttrs.version}.tar.xz";
      hash = "sha256-tGwTGHdw36tXfO47CnfQx9YigMcVw7g5YCyoihrjeho=";
    };

    nativeBuildInputs = with pkgs; [
      meson
      ninja
      pkg-config
    ];
    buildInputs = with pkgs; [
      curl
      jansson
    ];
    doCheck = true;
    # Terminal integration tests need tmux; Darwin's sandbox does not preserve setuid bits.
    postPatch = ''
      substituteInPlace tests/meson.build \
        --replace-fail "'repl_complete'," "" \
        --replace-fail "'repl_interrupt'," "" \
        --replace-fail "'repl_smoke'," ""
    ''
    + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
      substituteInPlace tests/meson.build --replace-fail "'tools/test_write.c'," ""
    '';

    meta = {
      description = "Lightweight terminal coding agent";
      homepage = "https://usehax.dev/";
      license = pkgs.lib.licenses.mit;
      mainProgram = "hax";
      platforms = pkgs.lib.platforms.unix;
    };
  });

  hax-search = pkgs.writeShellScriptBin "hax-search" ''
    set -euo pipefail
    sessions="''${XDG_STATE_HOME:-$HOME/.local/state}/hax/sessions"
    if [ ! -d "$sessions" ]; then
      echo "No saved hax sessions in $sessions" >&2
      exit 1
    fi

    selected=$(
      ${pkgs.ripgrep}/bin/rg -il --glob '*.jsonl' -- "''${*:-.}" "$sessions" |
        ${pkgs.fzf}/bin/fzf --layout=default --no-multi \
          --prompt='hax session> ' \
          --preview "${pkgs.jq}/bin/jq -r 'select(.kind == \"user\" or .kind == \"assistant\") | \"\\n── \\(.kind) ──\\n\\(.text)\"' {}" \
          --preview-window=up,70%,wrap
    ) || exit 0
    [ -n "$selected" ] || exit 0

    # hax resolves session IDs relative to the original working directory.
    IFS= read -r metadata < "$selected"
    cwd=$(printf '%s\n' "$metadata" | ${pkgs.jq}/bin/jq -er '.cwd')
    id=$(printf '%s\n' "$metadata" | ${pkgs.jq}/bin/jq -er '.id')
    cd -- "$cwd"
    exec ${hax}/bin/hax --resume="$id"
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
  xdg.configFile."hax/skills/google-workspace/SKILL.md".text = ''
    ---
    name: google-workspace
    description: Google Workspace tasks for mo2tion and hccreators through the authenticated gws CLI, including Chat, Gmail, Drive, and Calendar.
    ---

    # Workspace access

    Google Workspace access uses account-specific commands:

    | Account | Command |
    | --- | --- |
    | andreas@mo2tion.com | `gws-mo2tion` |
    | askielboe@hccreators.com | `gws-hccreators` |

    The account follows the user's request or verified resource ownership. Ambiguous account selection requires clarification.
    Requests spanning both accounts use separate commands.
    The named wrappers select credentials; bare `gws` and the active `gcloud` account are not substitutes.

    ## Discovery and reads

    Method help comes from `<account-cli> <service> <resource> --help`.
    Method schemas come from `<account-cli> schema <service.resource.method>`.
    Commands use `--params` for path and query parameters, and `--json` for request bodies.
    Responses are JSON. Read calls use bounded page sizes and field selection where supported.
    Subsequent pages use the response's `nextPageToken` as the next request's `pageToken`.
    Resource names come from API responses, not guessed identifiers.

    ```sh
    gws-mo2tion chat spaces list --params '{"pageSize":10}'
    gws-hccreators chat spaces list --params '{"pageSize":10}'
    gws-mo2tion schema chat.spaces.messages.list
    gws-hccreators gmail users getProfile --params '{"userId":"me"}'
    ```

    Authorized services include Chat, Gmail, Drive, Calendar, Docs, Sheets, and Slides.
    Mutations remain limited to the user's requested scope. Authentication alone does not authorize external actions.

    ## Email approval

    Sending, replying, forwarding, and scheduling email require review of the exact draft before explicit approval to send.
    The review includes To, CC, BCC, subject, complete body, attachments, and any scheduled delivery time.
    Changes to those details require renewed approval.
    General permission, silence, and requests to continue do not replace approval of the reviewed draft.
    This requirement applies across commands, tools, APIs, and delegated work.

    ## Authentication

    Each wrapper uses a separate directory under `~/.config/gws/`, named `mo2tion` or `hccreators`.
    Credentials are encrypted; their encryption key resides in the operating system's keyring.
    Refresh tokens renew access tokens automatically. Routine service calls do not require another login.
    Internal OAuth apps avoid the seven-day refresh-token expiry associated with External Testing apps.
    Revocation and Workspace security policies can still require reauthorization.

    ```sh
    gws-mo2tion auth status
    gws-hccreators auth status
    ```

    Authentication failures are reported for the affected account. Another account is not a fallback.
    Credential exports, tokens, and client secrets remain outside model output, repository files, and logs.
    Reauthorization and credential changes require an explicit setup request.
    Nix owns persistent configuration at `~/.config/nix`; the user applies changes with `hs`.
  '';

  home.packages =
    with pkgs;
    [
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
      hax
      hax-search
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
