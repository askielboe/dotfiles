{ ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/file.nix
    ./modules/shell.nix
    ./modules/git.nix
    ./modules/ssh.nix
    ./modules/programs.nix
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
    OP_ACCOUNT = "YRRGXLUXVBDZLFNOJZ6GP5ZRFA";
    ANTHROPIC_API_KEY = "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";
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
