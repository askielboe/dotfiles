{ lib, pkgs, ... }:

{
  # Darwin-specific home directory
  home.homeDirectory = "/Users/askielboe";

  # Darwin-specific config files
  home.file = {
    ".config/ghostty/config".source = ./dotfiles/ghostty/config;
  };

  # Darwin-specific shell aliases
  home.shellAliases = {
    o = "open .";
    cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
  };

  # Darwin-specific shell configuration
  programs.zsh.initContent = ''
    hs() {
      echo "darwin-rebuild switch --flake"
      sudo darwin-rebuild switch --flake ~/.config/nix/'.#askielboe'
      exec $SHELL
    }
  '';

  # Darwin-specific packages only
  home.packages = with pkgs; [
    # macOS-specific
    colima # Container runtimes on macOS (and Linux) with minimal setup
    mas    # Mac App Store CLI
    
    # Darwin-only development tools
    cargo
    d2
    deploy-rs
    gh
    git-annex
    git-filter-repo
    gnupg
    hcloud
    ipfs
    isync # IMAP sync tool
    nixpkgs-review
    ripsecrets # Find secrets
    tor
    transmission_4
    yt-dlp
  ];

}