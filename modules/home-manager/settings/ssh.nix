{ private, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = true;
      };
      "flextribe" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = true;
      };
      "storagebox-restic" = {
        HostName = private.ssh.storagebox.hostname;
        User = private.ssh.storagebox.user;
        IdentitiesOnly = true;
      };
      # git-annex export target for the Audiobookshelf library (sub-account u407515-sub14, port 23)
      "storagebox-audiobooks" = {
        HostName = private.ssh.storageboxAudiobooks.hostname;
        User = private.ssh.storageboxAudiobooks.user;
        Port = private.ssh.storageboxAudiobooks.port;
        # Public half of the 1Password-held key; IdentitiesOnly needs it to pick the agent key.
        IdentityFile = "~/.ssh/storagebox-audiobooks.pub";
        IdentitiesOnly = true;
      };
      "paperless" = {
        HostName = private.ssh.paperless.hostname;
        Port = private.ssh.paperless.port;
        User = private.ssh.paperless.user;
      };
      "synology" = {
        HostName = private.ssh.synology.hostname;
        IdentitiesOnly = true;
        User = private.ssh.synology.user;
      };
      "dobby" = {
        HostName = private.ssh.dobby.hostname;
        IdentitiesOnly = true;
        User = private.ssh.dobby.user;
      };
      "macmini" = {
        HostName = private.ssh.macmini.hostname;
        IdentitiesOnly = true;
        User = private.ssh.macmini.user;
      };
      "garage-hetzner" = {
        HostName = private.ssh.garageHetzner.hostname;
        IdentitiesOnly = true;
      };
      "nix" = {
        HostName = private.ssh.nix.hostname;
        User = private.ssh.nix.user;
      };
      "simply-tm" = {
        HostName = private.ssh.simplyTm.hostname;
        User = private.ssh.simplyTm.user;
      };
      "k3s" = {
        HostName = private.ssh.k3s.hostname;
        User = private.ssh.k3s.user;
        IdentityFile = private.ssh.k3s.identityFile;
        IdentitiesOnly = true;
      };
      "oci-1" = {
        HostName = private.ssh.oci1.hostname;
        User = private.ssh.oci1.user;
        IdentityFile = private.ssh.oci1.identityFile;
        IdentitiesOnly = true;
      };
      "oci-2" = {
        HostName = private.ssh.oci2.hostname;
        User = private.ssh.oci2.user;
        IdentityFile = private.ssh.oci2.identityFile;
        IdentitiesOnly = true;
      };
    };
  };
}
