{ config, ... }:

{
  imports = [
    ./modules/age.nix
    ./modules/file.nix
    ./modules/git.nix
    ./modules/git-annex.nix
    ./modules/nodejs.nix
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/python.nix
    ./modules/services.nix
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
      OP_ACCOUNT = "***REMOVED-SECRET***";
      ANTHROPIC_API_KEY = "$(cat ${config.age.secrets.anthropic.path})";
      HCLOUD_TOKEN = "$(cat ${config.age.secrets.hcloud.path})";
    };

    shellAliases = {
      o = "open .";
      lg = "lazygit";
      cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";

      # ls
      ls = "eza";
      l = "eza -l --all --group-directories-first --git";
      ll = "eza -l --all --all --group-directories-first --git";
      lt = "eza -T --git-ignore --level=2 --group-directories-first";
      llt = "eza -lT --git-ignore --level=2 --group-directories-first";
      lT = "eza -T --git-ignore --level=4 --group-directories-first";
      he = "cd ~/.config/home-manager/ && nvim && cd -";
      hu = "cd ~/.config/home-manager/ && nix flake update && cd -";

      # pueue
      pa = "pueue add";
      pk = "pueue kill";
      pl = "pueue log";
    };
  };

  catppuccin.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
