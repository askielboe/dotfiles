{ ... }:

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
    awscli = {
      enable = true;
      settings = {
        "default" = {
          region = "eu-west-1";
        };
        "motosumo-ms" = {
          region = "eu-central-1";
        };
      };
      credentials = {
        "default" = {
          region = "eu-west-1";
          credential_process = "/opt/homebrew/bin/op read 'op://Private/4th5zdmzuccmmkk2jvwq5ftt3m/password'";
        };
        "motosumo-ms" = {
          region = "eu-central-1";
          credential_process = "/opt/homebrew/bin/op read 'op://Private/qwm6obmd4fb4ijz3mr2qfvcajm/password'";
        };
      };
    };
  };
}
