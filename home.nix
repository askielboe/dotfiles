{ config, ... }:

{
  imports = [
    ./modules/age.nix
    ./modules/file.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/programs.nix
    ./modules/shell.nix
    ./modules/ssh.nix
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

  home.sessionVariables = {
    VISUAL = "nvim";
    EDITOR = "nvim";
    XDG_CONFIG_HOME = "$HOME/.config";
    DIRENV_LOG_FORMAT = "";
    OP_ACCOUNT = "YRRGXLUXVBDZLFNOJZ6GP5ZRFA";
    ANTHROPIC_API_KEY = "$(cat ${config.age.secrets.anthropic.path})";
  };

  home.shellAliases = {
    o = "open .";
    lg = "lazygit";
    he = "cd ~/.config/home-manager/ && nvim && cd -";
  };

  catppuccin = {
    enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
