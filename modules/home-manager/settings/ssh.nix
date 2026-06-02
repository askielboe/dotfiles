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
        inherit (private.ssh.storagebox) hostname;
        inherit (private.ssh.storagebox) user;
        identitiesOnly = true;
      };
      # git-annex export target for the Audiobookshelf library (sub-account u407515-sub14, port 23)
      "storagebox-audiobooks" = {
        inherit (private.ssh.storageboxAudiobooks) hostname;
        inherit (private.ssh.storageboxAudiobooks) user;
        inherit (private.ssh.storageboxAudiobooks) port;
        # Public half of the 1Password-held key; IdentitiesOnly needs it to pick the agent key.
        identityFile = "~/.ssh/storagebox-audiobooks.pub";
        identitiesOnly = true;
      };
      "paperless" = {
        inherit (private.ssh.paperless) hostname;
        inherit (private.ssh.paperless) port;
        inherit (private.ssh.paperless) user;
      };
      "synology" = {
        inherit (private.ssh.synology) hostname;
        identitiesOnly = true;
        inherit (private.ssh.synology) user;
      };
      "dobby" = {
        inherit (private.ssh.dobby) hostname;
        identitiesOnly = true;
        inherit (private.ssh.dobby) user;
      };
      "macmini" = {
        inherit (private.ssh.macmini) hostname;
        identitiesOnly = true;
        inherit (private.ssh.macmini) user;
      };
      "garage-hetzner" = {
        inherit (private.ssh.garageHetzner) hostname;
        identitiesOnly = true;
      };
      "nix" = {
        inherit (private.ssh.nix) hostname;
        inherit (private.ssh.nix) user;
      };
      "simply-tm" = {
        inherit (private.ssh.simplyTm) hostname;
        inherit (private.ssh.simplyTm) user;
      };
      "k3s" = {
        inherit (private.ssh.k3s) hostname;
        inherit (private.ssh.k3s) user;
        inherit (private.ssh.k3s) identityFile;
        identitiesOnly = true;
      };
      "oci-1" = {
        inherit (private.ssh.oci1) hostname;
        inherit (private.ssh.oci1) user;
        inherit (private.ssh.oci1) identityFile;
        identitiesOnly = true;
      };
      "oci-2" = {
        inherit (private.ssh.oci2) hostname;
        inherit (private.ssh.oci2) user;
        inherit (private.ssh.oci2) identityFile;
        identitiesOnly = true;
      };
    };
  };
}
