{ pkgs }:
let
  fakeGws = pkgs.writeShellScriptBin "gws" ''
    set -euo pipefail
    printf '%s\n' "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"
    for name in GOOGLE_WORKSPACE_CLI_TOKEN GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE GOOGLE_WORKSPACE_CLI_CLIENT_ID GOOGLE_WORKSPACE_CLI_CLIENT_SECRET GOOGLE_APPLICATION_CREDENTIALS GOOGLE_WORKSPACE_PROJECT_ID; do
      if [[ -v "$name" ]]; then
        echo "Unexpected inherited auth override: $name" >&2
        exit 1
      fi
    done
    printf '%s\n' "$@"
  '';
  module = import ../modules/home-manager/settings/packages.nix {
    pkgs = pkgs // {
      gws = fakeGws;
    };
    nixpkgs-unstable = pkgs.path;
  };
  wrapper =
    account: builtins.head (builtins.filter (p: p.name == "gws-${account}") module.home.packages);
in
pkgs.runCommand "gws-account-isolation-tests" { } ''
  export HOME="$TMPDIR/home"
  export XDG_CONFIG_HOME="$TMPDIR/config with spaces"
  export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$TMPDIR/wrong-account"
  export GOOGLE_WORKSPACE_CLI_TOKEN=wrong-account-token
  export GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/wrong/credentials.json
  export GOOGLE_WORKSPACE_CLI_CLIENT_ID=wrong-client
  export GOOGLE_WORKSPACE_CLI_CLIENT_SECRET=wrong-secret
  export GOOGLE_APPLICATION_CREDENTIALS=/wrong/adc.json
  export GOOGLE_WORKSPACE_PROJECT_ID=wrong-project
  mkdir -p "$HOME"

  for account in mo2tion hccreators; do
    wrapper=""
    case "$account" in
      mo2tion) wrapper=${wrapper "mo2tion"}/bin/gws-mo2tion ;;
      hccreators) wrapper=${wrapper "hccreators"}/bin/gws-hccreators ;;
    esac
    if "$wrapper" chat spaces list > unexpected-output 2> expected-error; then
      echo "Unauthenticated account unexpectedly reached gws" >&2
      exit 1
    fi
    test ! -s unexpected-output
    grep -q 'is not authenticated' expected-error
    touch "$XDG_CONFIG_HOME/gws/$account/credentials.enc"

    actual=$("$wrapper" chat spaces list --params '{"pageSize": 1}')
    expected=$(printf '%s\n' "$XDG_CONFIG_HOME/gws/$account" chat spaces list --params '{"pageSize": 1}')
    test "$actual" = "$expected"
    test "$(stat -c %a "$XDG_CONFIG_HOME/gws/$account")" = 700

    chmod 755 "$XDG_CONFIG_HOME/gws/$account"
    "$wrapper" auth status > /dev/null
    test "$(stat -c %a "$XDG_CONFIG_HOME/gws/$account")" = 700

    actual=$(env -u XDG_CONFIG_HOME "$wrapper" auth status)
    expected=$(printf '%s\n' "$HOME/.config/gws/$account" auth status)
    test "$actual" = "$expected"
  done
  touch "$out"
''
