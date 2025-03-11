{ config, ... }:

{
  imports = [
    ./settings/age.nix
    ./settings/file.nix
    ./settings/git.nix
    ./settings/git-annex.nix
    ./settings/nodejs.nix
    ./settings/packages.nix
    ./settings/programs.nix
    ./settings/python.nix
    ./settings/services.nix
    ./settings/shell.nix
    ./settings/ssh.nix
  ];

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
      he = "cd ~/.config/nix/ && nvim && cd -";
      hu = "cd ~/.config/nix/ && nix flake update && cd -";

      # pueue
      pa = "pueue add";
      pk = "pueue kill";
      pl = "pueue log";
    };
  };

  catppuccin.enable = true;
}
