{ pkgs }:

pkgs.writeShellScriptBin "openclaw" ''
  exec ${pkgs.nodejs_22}/bin/npx --yes openclaw@2026.2.17 "$@"
''
