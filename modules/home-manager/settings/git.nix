{ ... }:

let
  name = "Andreas Skielboe";
  email = "skielboe@gmail.com";
in
{
  programs = {
    git = {
      enable = true;
      ignores = [
        "**/*.pyc"
        "**/__pycache__"
        "*.swp"
        "*~"
        ".DS_Store"
        ".aider*"
        ".devenv"
        ".devenv.*"
        ".direnv"
        ".envrc"
        ".pytest_cache/"
        "devbox.*"
        "cancel-release.sh"
      ];
      userName = name;
      userEmail = email;
      delta = {
        enable = true;
      };
      lfs = {
        enable = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core = {
          editor = "nvim";
          autocrlf = "input";
        };
        pull.rebase = true;
        rebase.autoStash = true;
        push = {
          autoSetupRemote = true;
          useForceIfIncludes = true;
        };
        commit.gpgSign = false;
        gpg = {
          format = "ssh";
          "ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUk1npSjpgOHYCDusD19DG+YcnG1lc79VLZBpSqNaHZ";
      };
    };

    lazygit = {
      enable = true;
      settings = {
        gui = {
          showFileTree = true;
        };
        git = {
          paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          };
        };
      };
    };
  };
}
