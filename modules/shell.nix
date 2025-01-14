{ lib, ... }:

{
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
      initExtraFirst = '''';
      initExtra = ''
        hs() {
          echo "home-manager switch --flake"
          home-manager switch --flake "$HOME/.config/home-manager#askielboe"
          exec $SHELL
        }
      '';
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$cmd_duration"
          "$line_break"
          "$python"
          "$character"
        ];

        directory = {
          style = "fg:blue";
        };

        character = {
          success_symbol = "[❯](purple)";
          error_symbol = "[❯](red)";
          vimcmd_symbol = "[❮](green)";
        };

        git_branch = {
          style = "fg:bright-black";
          format = "[$branch]($style)";
        };

        git_status = {
          style = "fg:cyan";
          format = " ($ahead_behind$stashed)]($style)";
          conflicted = "​";
          untracked = "​";
          modified = "​";
          staged = "​";
          renamed = "​";
          deleted = "​";
          stashed = "≡";
        };

        git_state = {
          style = "fg:bright-black";
          format = "\([ $state ($progress_current/$progress_total) ] ($style)\) ";
        };

        cmd_duration = {
          style = "fg:yellow";
          format = "[$duration]($style) ";
        };

        python = {
          style = "fg:bright-black";
          format = "[$virtualenv]($style) ";
        };
      };
    };
  };
}
