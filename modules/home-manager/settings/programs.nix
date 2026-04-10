{ pkgs, nixpkgs-unstable, private, ... }:
let
  aws = private.accounts.awsProfiles;
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };
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
      package = unstable.direnv; # stable 2.37.1 fish tests fail to build
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
          region = aws.default.region;
        };
        "${aws.motosumo.name}" = {
          region = aws.motosumo.region;
        };
      };
      credentials = {
        "default" = {
          region = aws.default.region;
          credential_process = "/opt/homebrew/bin/op read 'op://Private/${aws.default.opItem}/password'";
        };
        "${aws.motosumo.name}" = {
          region = aws.motosumo.region;
          credential_process = "/opt/homebrew/bin/op read 'op://Private/${aws.motosumo.opItem}/password'";
        };
      };
    };
  };
}
