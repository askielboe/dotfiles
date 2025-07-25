{ lib, pkgs, ... }:

{
  # Linux-specific home directory
  home.homeDirectory = "/home/askielboe";

  # Linux-specific shell configuration
  programs.zsh.initExtra = ''
    hs() {
      echo "home-manager switch --flake"
      home-manager switch --flake ~/.config/nix/'.#askielboe'
      exec $SHELL
    }
  '';

  # Import platform-agnostic modules
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