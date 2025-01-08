{ ... }:

let
  name = "Andreas Skielboe";
  user = "askielboe";
  email = "skielboe@gmail.com";
in
{
  imports = [
    ./modules/packages.nix
    ./modules/programs/starship.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "askielboe";
  home.homeDirectory = "/Users/askielboe";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".config/ghostty/config".source = dotfiles/ghostty/config;
    ".config/nvim/lua".source = dotfiles/nvim/lua;
    "rustic.toml".source = dotfiles/rustic/rustic.toml;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/askielboe/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    VISUAL = "nvim";
    EDITOR = "nvim";
    XDG_CONFIG_HOME = "$HOME/.config";
    DIRENV_LOG_FORMAT = "";
    OP_ACCOUNT = "***REMOVED-SECRET***";
    ANTHROPIC_API_KEY = "***REMOVED-SECRET***";
  };

  home.shellAliases = {
    o = "open .";
    lg = "lazygit";
    he = "cd ~/.config/home-manager/ && nvim && cd -";
  };

  catppuccin = {
    enable = true;
  };

  programs = {
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~" ];
      prezto = {
        enable = true;
        pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "history-substring-search"
          "prompt"
          "git"
          "autosuggestions"
          "syntax-highlighting"
        ];
        prompt = {
          theme = "sorin";
        };
      };
      initExtraFirst = ''
      '';
      initExtra = ''
        hs() {
          echo "home-manager: switch"
          home-manager switch
          exec $SHELL
        }
      '';
    };

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

    git = {
      enable = true;
      ignores = [ "*.swp" ];
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
        push.autoSetupRemote = true;
        commit.gpgSign = true;
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
      settings =
        {
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

    ssh = {
      enable = true;
      # includes = [ "/Users/${user}/.ssh/config_external" ];
      matchBlocks = {
        "*" = {
          extraOptions = {
            IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
          };
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identitiesOnly = true;
          identityFile = "/Users/${user}/.ssh/id_ed25519-github.pub";
        };
        "flextribe" = {
          hostname = "github.com";
          user = "git";
          identitiesOnly = true;
          identityFile = "/Users/${user}/.ssh/id_ed25519_flextribe.pub";
        };
        "storagebox-restic" = {
          hostname = "your-storagebox.de";
          user = "u407515-sub6";
          identitiesOnly = true;
          identityFile = "/Users/${user}/.ssh/id_ed25519-storagebox.pub";
        };
        "paperless" = {
          hostname = "135.181.80.183";
          port = 54056;
          user = "paperless";
        };
        "dobby" = {
          hostname = "192.168.1.12";
        };
        "garage-hetzner" = {
          hostname = "49.13.75.42";
          identitiesOnly = true;
          identityFile = "/Users/${user}/.ssh/id_ed25519-hetzner-garage.pub";
        };
      };
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
