{ pkgs, config, ... }:
{
  # Import shared home-manager settings
  imports = [
    ./nixvim
    ./settings/file.nix
    ./settings/git-annex.nix
    ./settings/git.nix
    ./settings/nodejs.nix
    ./settings/packages.nix
    ./settings/programs.nix
    ./settings/python.nix
    ./settings/shell.nix
    ./settings/ssh.nix
  ];

  home = {
    username = "askielboe";
    stateVersion = "24.11"; # Keep this unchanged

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      EDITOR = "nvim";
      OP_ACCOUNT = "YRRGXLUXVBDZLFNOJZ6GP5ZRFA";
      PAGER = "bat";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
    };

    shellAliases = {
      ef = "e $(fzf)";
      cf = "cd $(fzf)";
      lg = "lazygit";
      rp = "resticprofile --config ~/.config/restic/profiles.yaml";
      aider = "op run --no-masking aider";

      # ls
      ls = "eza";
      l = "eza -l --all --group-directories-first --git";
      ll = "eza -l --all --all --group-directories-first --git";
      lt = "eza -T --git-ignore --level=2 --group-directories-first";
      llt = "eza -lT --git-ignore --level=2 --group-directories-first";
      lT = "eza -T --git-ignore --level=4 --group-directories-first";
      he = "cd ~/.config/nix/ && nvim && cd -";
      hu = "cd ~/.config/nix/ && nix flake update && cd -";
    };
  };

  catppuccin.enable = true;
}