{
  pkgs,
  lib,
  private,
  ...
}:
let
  ch = private.clickhouse;
in
{
  home.packages = [
    (lib.hiPrio (
      pkgs.writeShellApplication {
        name = "ch";
        runtimeInputs = [ pkgs.clickhouse ];
        text = ''
          password=$(/opt/homebrew/bin/op read "op://Private/${ch.opItem}/password")
          exec clickhouse-client \
            --host "${ch.host}" \
            --secure \
            --user "${ch.user}" \
            --password "$password" \
            "$@"
        '';
      }
    ))
  ];
}
