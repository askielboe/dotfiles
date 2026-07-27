{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    (lib.hiPrio (
      pkgs.writeShellApplication {
        name = "ch";
        runtimeInputs = [ pkgs.clickhouse ];
        # Endpoint + 1Password item ref come from the sops-decrypted secrets at
        # RUN time (the interpolated .path values are plain home-dir strings),
        # so nothing about the ClickHouse account lands in the nix store.
        text = ''
          host=$(<${config.sops.secrets."clickhouse-host".path})
          user=$(<${config.sops.secrets."clickhouse-user".path})
          op_item=$(<${config.sops.secrets."clickhouse-op-item".path})
          password=$(/opt/homebrew/bin/op read "op://Private/$op_item/password")
          exec clickhouse-client \
            --host "$host" \
            --secure \
            --user "$user" \
            --password "$password" \
            "$@"
        '';
      }
    ))
  ];
}
