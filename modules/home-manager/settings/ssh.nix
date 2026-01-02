{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # includes = [ "~/.ssh/config_external" ];
    matchBlocks = {
      "*" = {
        identityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
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
      "k3s" = {
        hostname = "37.27.196.7";
        user = "root";
        identityFile = "~/.ssh/id_rsa-motosumo-m1";
        identitiesOnly = true;
      };
    };
  };
}
