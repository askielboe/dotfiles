{ pkgs, config, ... }:

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
    ./settings/shell.nix
    ./settings/ssh.nix
    ./nixvim
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
      ANTHROPIC_API_KEY = "op://Private/uthlrb6g3fxdc64cgu4scq4zza/API Keys/gwougl7qnnn2tnhhru2r7h6uqm";
    };

    shellAliases = {
      o = "open .";
      lg = "lazygit";
      cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
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
