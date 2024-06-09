{ config, pkgs, lib, ... }:

let name = "Andreas Skielboe";
    user = "askielboe";
    email = "skielboe@gmail.com"; in
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

    # General packages for development and system management
    aspell
    aspellDicts.en
    bash-completion
    bat
    borgbackup
    borgmatic
    btop
    coreutils
    d2
    difftastic
    git-annex
    killall
    mas
    neofetch
    ngrok
    openssh
    rclone
    silver-searcher
    sqlite
    tor
    wget
    zip

    # Encryption and security tools
    age
    age-plugin-yubikey
    gnupg
    libfido2

    # Cloud-related tools and SDKs
    docker
    docker-compose

    # Media-related packages
    #emacs-all-the-icons-fonts
    dejavu_fonts
    ffmpeg
    fd
    font-awesome
    hack-font
    noto-fonts
    noto-fonts-emoji
    meslo-lgs-nf

    # Node.js development tools
    #nodePackages.npm # globally install npm
    #nodePackages.prettier
    #nodejs

    # Text and terminal utilities
    htop
    restic
    devbox
    #hunspell
    #iftop
    #jetbrains-mono
    jq
    ripgrep
    tree
    tmux
    unrar
    unzip
    zsh-powerlevel10k

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
    EDITOR = "vim";
  };

  programs = {
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~/.local/share/src" ];
      plugins = [
        {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
            name = "powerlevel10k-config";
            src = lib.cleanSource ./config;
            file = "p10k.zsh";
        }
      ];
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
      };
      initExtraFirst = ''
        # Remove history data we don't want to see
        export HISTIGNORE="pwd:ls:cd"

        # Ripgrep alias
        alias search=rg -p --glob '!node_modules/*'  $@

        hs() {
            home-manager switch
        }

        alias o='open .'

        c() {
            code .
        }

        w() {
            cd ~/work
        }

        # Use difftastic, syntax-aware diffing
        alias diff=difft

        # Always color ls and group directories
        alias ls='ls --color=auto'
      '';
      initExtra = ''
        # Suppress printing direnv env
        # see https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/
        export DIRENV_LOG_FORMAT="$(printf "\033[2mdirenv: %%s\033[0m")"
        eval "$(direnv hook zsh)"
        _direnv_hook() {
          eval "$(direnv export zsh 2> >(egrep -v -e '^....direnv: export' >&2))"
        };
        # eval "$(devbox global shellenv)"
      '';
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
      lfs = {
        enable = true;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core = {
        editor = "vim";
          autocrlf = "input";
        };
        #commit.gpgsign = true;
        pull.rebase = true;
        rebase.autoStash = true;
        push.autoSetupRemote = true;
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
          identitiesOnly = true;
          identityFile = "/Users/${user}/.ssh/id_github";
        };
        "flextribe" = {
          hostname = "github.com";
          user = "git";
          identityFile = "/Users/${user}/.ssh/id_ed25519_flextribe.pub";
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
          "credential_process" = "/opt/homebrew/bin/op read 'op://Private/AWS Credentials Motosumo/password'";
        };
      };
    };

    vscode = {
      enable = true;
      userSettings = {
        "editor.fontSize" = 11;
        "editor.minimap.enabled" = false;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "off";
        "files.autoSave" = "onFocusChange";
        "files.autoSaveDelay" = 1000;
        "files.trimTrailingWhitespace" = true;
        "github.copilot.editor.enableAutoCompletions" = true;
        "workbench.colorTheme" = "Gruvbox Minor Dark Hard";
        "workbench.iconTheme" = "vscode-icons";
        "workbench.startupEditor" = "newUntitledFile";
        "editor.formatOnSave" = true;
        "window.zoomLevel" = 1.2;
        "[javascript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "ruff.nativeServer" = true;
        "notebook.codeActionsOnSave" = {
          "notebook.source.fixAll" = "explicit";
          "notebook.source.organizeImports" = "explicit";
        };
        "[python]" = {
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "explicit";
            "source.organizeImports" = "explicit";
          };
          "editor.defaultFormatter" = "charliermarsh.ruff";
        };
        "magit.quick-switch-enabled" = true;
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
