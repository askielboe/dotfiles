{ lib, ... }:

{
  # NixOS-specific home directory
  home.homeDirectory = "/home/askielboe";

  # NixOS-specific shell configuration
  programs.zsh.initContent = ''
    hs() {
      echo "nixos-rebuild switch --flake"
      sudo nixos-rebuild switch --flake ~/.config/nix/'.#nixos-server'
      exec $SHELL
    }
  '';

  # Import platform-agnostic modules that were previously in home-manager/default.nix
  # Only include the ones that make sense for a server environment
  imports = [
    ./settings/git.nix
    ./settings/programs.nix
    ./settings/ssh.nix
  ];
}