{ lib, pkgs, ... }:

{
  # Linux-specific home directory
  home.homeDirectory = "/home/askielboe";

  # Linux-specific shell aliases
  home.shellAliases = {
    # Remove macOS-specific aliases
    o = "xdg-open .";
  };

  # Linux-specific shell configuration
  programs.zsh.initExtra = ''
    hs() {
      echo "home-manager switch --flake"
      home-manager switch --flake ~/.config/nix/'.#askielboe'
      exec $SHELL
    }
  '';

  # Linux-specific packages
  home.packages = with pkgs; [
    # Linux development tools
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