{ private, ... }:
let
  ch = private.clickhouse;

  # Saved connections for the sqlit TUI (~/.config/sqlit/connections.json,
  # schema version 2). No secret material lands here: sqlit runs
  # password_command at connect time and uses its stdout as the password,
  # so only the 1Password reference is stored. Port 8443 is ClickHouse's
  # HTTPS port and makes sqlit enable TLS automatically.
  #
  # The file is a read-only nix symlink, so add/edit/delete connections
  # here, not inside the app — an in-app save would replace the symlink
  # and the next `hs` would refuse to activate over it.
  connections = [
    {
      name = "ClickHouse Cloud";
      db_type = "clickhouse";
      endpoint = {
        kind = "tcp";
        inherit (ch) host;
        port = "8443";
        database = "default";
        username = ch.user;
        password = null;
        password_command = "/opt/homebrew/bin/op read 'op://Private/${ch.opItem}/password'";
      };
      tunnel.enabled = false;
      source = null;
      connection_url = null;
      folder_path = "";
      extra_options = { };
      options = { };
    }
  ];
in
{
  home.file.".config/sqlit/connections.json".text = builtins.toJSON {
    version = 2;
    inherit connections;
  };
}
