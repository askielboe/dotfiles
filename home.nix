{ config, ... }:

{
  imports = [
    ./modules/age.nix
    ./modules/file.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/python.nix
    ./modules/shell.nix
    ./modules/ssh.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "askielboe";
    homeDirectory = "/Users/askielboe";
    stateVersion = "24.11"; # Keep this unchanged

    sessionVariables = {
      VISUAL = "nvim";
      EDITOR = "nvim";
      PAGER = "bat";
      XDG_CONFIG_HOME = "$HOME/.config";
      DIRENV_LOG_FORMAT = "";
      OP_ACCOUNT = "YRRGXLUXVBDZLFNOJZ6GP5ZRFA";
      ANTHROPIC_API_KEY = "$(cat ${config.age.secrets.anthropic.path})";
    };

    shellAliases = {
      o = "open .";
      lg = "lazygit";
      he = "cd ~/.config/home-manager/ && nvim && cd -";
      hu = "cd ~/.config/home-manager/ && nix flake update && cd -";
    };
  };

  catppuccin.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
