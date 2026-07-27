{ pkgs, private, ... }:
let
  aws = private.accounts.awsProfiles;
in
{
  programs = {
    java = {
      enable = true;
    };
    less = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      package = pkgs.direnv;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    bat = {
      enable = true;
    };
    yarn = {
      enable = true;
      settings = {
        enableGlobalCache = false;
        compressionLevel = 0;
        nmMode = "hardlinks-local";
      };
    };
    awscli = {
      enable = true;
      settings = {
        "default" = {
          inherit (aws.default) region;
        };
        "${aws.work.name}" = {
          inherit (aws.work) region;
        };
      };
      # No `credentials` attrset: ~/.aws/credentials is the sops-decrypted
      # aws-credentials secret (see settings/sops.nix) so the 1Password item
      # refs in credential_process stay out of the repo and the nix store.
    };
  };
}
