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
        "${aws.motosumo.name}" = {
          inherit (aws.motosumo) region;
        };
      };
      credentials = {
        "default" = {
          inherit (aws.default) region;
          credential_process = "/opt/homebrew/bin/op read 'op://Private/${aws.default.opItem}/password'";
        };
        "${aws.motosumo.name}" = {
          inherit (aws.motosumo) region;
          credential_process = "/opt/homebrew/bin/op read 'op://Private/${aws.motosumo.opItem}/password'";
        };
      };
    };
  };
}
