{ private, ... }:
{
  programs = {
    delta = {
      enable = true;
    };

    git = {
      enable = true;
      ignores = [
        "**/*.pyc"
        "**/__pycache__"
        "*.swp"
        "*~"
        ".DS_Store"
        ".aider*"
        ".claude/"
        ".devenv"
        ".devenv.*"
        ".direnv"
        ".envrc"
        ".pytest_cache/"
        ".serena/"
        "cache.sh"
        "cancel-release.sh"
        "devbox.*"
        "upgrade-dependency.sh"
      ];
      lfs = {
        enable = true;
      };
      settings = {
        user = {
          name = private.user.name;
          email = private.user.email;
          signingKey = private.user.signingKey;
        };
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
    };

    lazygit = {
      enable = true;
      settings = {
        gui = {
          showFileTree = true;
        };
        git = {
          pagers = [
            {
              colorArg = "always";
              pager = "delta --dark --paging=never";
            }
          ];
        };
      };
    };
  };
}
