{ private, ... }:
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
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    atuin = {
      enable = true;
      enableZshIntegration = true;
      # Bind Ctrl-R to atuin but leave the up-arrow to prezto's
      # history-substring-search. Local-only db (no sync server configured).
      flags = [ "--disable-up-arrow" ];
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
