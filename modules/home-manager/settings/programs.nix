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
