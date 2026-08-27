{ config, ... }:
{
  # Replication stays server-side because Perkeep 0.12 has no client-side
  # numCopies setting; the k3s server writes through two replica backends.
  sops.templates."perkeep-client-config.json" = {
    path = "${config.xdg.configHome}/perkeep/client-config.json";
    mode = "0600";
    content = builtins.toJSON {
      identity = "8706274AC894915B";
      identitySecretRing = config.sops.secrets."perkeep-identity-secring".path;
      ignoredFiles = [
        ".DS_Store"
        "*~"
      ];
      servers.default = {
        auth = config.sops.placeholder."perkeep-auth";
        default = true;
        server = "https://perkeep.skielboe.com";
      };
    };
  };
}
