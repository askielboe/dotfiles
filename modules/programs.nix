{ ... }:

{
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
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
      };
      credentials = {
        "default" = {
          "region" = "eu-west-1";
          "credential_process" = "/opt/homebrew/bin/op read 'op://Private/4th5zdmzuccmmkk2jvwq5ftt3m/password'";
        };
      };
    };
  };
}
