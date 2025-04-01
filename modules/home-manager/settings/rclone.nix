{ config, ... }:
{
  programs.rclone = {
    enable = true;

    remotes = {
      storagebox = {
        config = {
          type = "webdav";
          url = "https://u407515.your-storagebox.de";
          user = "u407515";
        };
        secrets = {
          pass = config.sops.secrets."rclone/storagebox".path;
        };
      };
    };
  };

  sops.secrets."rclone/storagebox" = {
    sopsFile = ../../sops/secrets/rclone.yaml;
  };
}
