{ ... }:
{
  programs.ssh = {
    enable = true;
    # includes = [ "~/.ssh/config_external" ];
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
      };
      "flextribe" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
      };
      "storagebox-restic" = {
        hostname = "your-storagebox.de";
        user = "u407515-sub6";
        identitiesOnly = true;
      };
      "paperless" = {
        hostname = "135.181.80.183";
        port = 54056;
        user = "paperless";
      };
      "synology" = {
        hostname = "192.168.1.10";
        identitiesOnly = true;
        user = "askielboe";
      };
      "dobby" = {
        hostname = "192.168.1.12";
        identitiesOnly = true;
        user = "andreas";
      };
      "macmini" = {
        hostname = "192.168.1.11";
        identitiesOnly = true;
        user = "askielboe";
      };
      "garage-hetzner" = {
        hostname = "49.13.75.42";
        identitiesOnly = true;
      };
      "nix" = {
        hostname = "135.181.34.240";
        user = "root";
      };
      "simply-tm" = {
        hostname = "linux215.unoeuro.com";
        user = "toustrupmark.dk";
      };
    };
  };
}
