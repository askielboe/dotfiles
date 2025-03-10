{ ... }:

let
  user = "askielboe";
in
{
  programs.ssh = {
    enable = true;
    # includes = [ "/Users/${user}/.ssh/config_external" ];
    matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = "/Users/${user}/.ssh/id_ed25519-github.pub";
      };
      "flextribe" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = "/Users/${user}/.ssh/id_ed25519_flextribe.pub";
      };
      "storagebox-restic" = {
        hostname = "your-storagebox.de";
        user = "u407515-sub6";
        identitiesOnly = true;
        identityFile = "/Users/${user}/.ssh/id_ed25519-storagebox.pub";
      };
      "paperless" = {
        hostname = "135.181.80.183";
        port = 54056;
        user = "paperless";
      };
      "dobby" = {
        hostname = "192.168.1.12";
        identitiesOnly = true;
        user = "andreas";
        identityFile = "/Users/${user}/.ssh/id_ed25519.pub";
      };
      "garage-hetzner" = {
        hostname = "49.13.75.42";
        identitiesOnly = true;
        identityFile = "/Users/${user}/.ssh/id_ed25519-hetzner-garage.pub";
      };
      "nix" = {
        hostname = "135.181.34.240";
        user = "root";
      };
    };
  };
}
