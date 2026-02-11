{ private, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
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
        hostname = private.ssh.storagebox.hostname;
        user = private.ssh.storagebox.user;
        identitiesOnly = true;
      };
      "paperless" = {
        hostname = private.ssh.paperless.hostname;
        port = private.ssh.paperless.port;
        user = private.ssh.paperless.user;
      };
      "synology" = {
        hostname = private.ssh.synology.hostname;
        identitiesOnly = true;
        user = private.ssh.synology.user;
      };
      "dobby" = {
        hostname = private.ssh.dobby.hostname;
        identitiesOnly = true;
        user = private.ssh.dobby.user;
      };
      "macmini" = {
        hostname = private.ssh.macmini.hostname;
        identitiesOnly = true;
        user = private.ssh.macmini.user;
      };
      "garage-hetzner" = {
        hostname = private.ssh.garageHetzner.hostname;
        identitiesOnly = true;
      };
      "nix" = {
        hostname = private.ssh.nix.hostname;
        user = private.ssh.nix.user;
      };
      "simply-tm" = {
        hostname = private.ssh.simplyTm.hostname;
        user = private.ssh.simplyTm.user;
      };
      "k3s" = {
        hostname = private.ssh.k3s.hostname;
        user = private.ssh.k3s.user;
        identityFile = private.ssh.k3s.identityFile;
        identitiesOnly = true;
      };
      "oci-1" = {
        hostname = private.ssh.oci1.hostname;
        user = private.ssh.oci1.user;
        identityFile = private.ssh.oci1.identityFile;
        identitiesOnly = true;
      };
      "dokku-1" = {
        hostname = private.ssh.dokku1.hostname;
        user = private.ssh.dokku1.user;
        identityFile = private.ssh.dokku1.identityFile;
        identitiesOnly = true;
      };
    };
  };
}
