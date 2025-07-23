{ lib, pkgs, ... }:

{
  # Darwin-specific home directory
  home.homeDirectory = "/Users/askielboe";

  # Darwin-specific shell aliases
  home.shellAliases = {
    o = "open .";
    cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
  };

  # Darwin-specific shell configuration
  programs.zsh.initContent = ''
    hs() {
      echo "darwin-rebuild switch --flake"
      sudo darwin-rebuild switch --flake ~/.config/nix/'.#swaggermis'
      exec $SHELL
    }
  '';

  # Darwin-specific packages
  home.packages = with pkgs; [
    colima # Container runtimes on macOS (and Linux) with minimal setup
    mas    # Mac App Store CLI
  ];

  # Import platform-agnostic modules that were previously in home-manager/default.nix
  imports = [
    ./settings/file.nix
    ./settings/git-annex.nix
    ./settings/git.nix
    ./settings/nodejs.nix
    ./settings/programs.nix
    ./settings/python.nix
    ./settings/ssh.nix
  ];
}