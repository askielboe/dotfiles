{ config, pkgs, lib, ... }:

let
  name = "Andreas Skielboe";
  user = "askielboe";
  email = "skielboe@gmail.com";
in
{
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
  home.stateVersion = "24.05"; # Please read the comment before changing.

  nixpkgs.config = {
    allowUnfree = true;
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # System and Core Utilities
    coreutils
    gnused
    killall
    htop
    btop
    tree
    wget
    zip
    bzip2
    sqlite

    # Terminal and Text Tools
    ripgrep
    tmux
    neovim
    difftastic
    jq

    # Version Control and Git Tools
    git
    git-annex

    # Development Tools and SDKs
    aider-chat
    cargo
    d2
    devenv
    nodePackages.npm
    nodePackages.prettier
    nodejs

    # Cloud and Container Tools
    docker
    docker-compose
    ssm-session-manager-plugin
    ngrok

    # Backup and Sync Tools
    magic-wormhole
    rclone
    restic
    rustic

    # Security and Encryption
    age
    gnupg
    openssh
    tor

    # Media Processing
    ffmpeg

    # MacOS Specific Tools
    mas

    # Python packages
    #python39
    #python39Packages.virtualenv # globally install virtualenv
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".config/ghostty/config".source = dotfiles/ghostty/config;
    ".config/nvim/lua".source = dotfiles/nvim/lua;

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
    OP_ACCOUNT = "***REMOVED-SECRET***";
    ANTHROPIC_API_KEY = "***REMOVED-SECRET***";
  };

  programs = {
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~/.local/share/src" ];
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
        hs() {
          echo "running home-manager switch.."
          home-manager switch
          exec $SHELL
        }

        alias o='open .'
        alias he='cd ~/.config/home-manager/ && nvim && echo "running home manager switch.." && hs'
      '';
      initExtra = ''
      '';
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
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

  programs.home-manager.enable = true;
}
