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

  # Darwin-specific SSH configuration
  programs.ssh.matchBlocks = {
    "github.com".identityFile = "~/.ssh/id_ed25519-github";
    "flextribe".identityFile = "~/.ssh/id_ed25519-github";
    "storagebox-restic".identityFile = "~/.ssh/id_ed25519-storagebox";
    "garage-hetzner".identityFile = "~/.ssh/id_ed25519-hetzner-garage";
  };

  # Darwin-specific shell configuration
  programs.zsh.initContent = ''
    hs() {
      echo "darwin-rebuild switch --flake"
      export NIXPKGS_ALLOW_UNFREE=1
      sudo -E darwin-rebuild switch --flake ~/.config/nix/'.#askielboe' --impure
      exec $SHELL
    }
  '';

  # Darwin-specific packages only
  home.packages = with pkgs; [
    cargo
    colima # Container runtimes (docker) on macOS (and Linux) with minimal setup
    d2
    deploy-rs
    gh
    git-annex
    git-filter-repo
    gnupg
    hcloud
    ipfs
    isync # IMAP sync tool
    mas # Mac App Store CLI
    nixpkgs-review
    openai-whisper
    ripsecrets # Find secrets
    transmission_4
    yt-dlp
  ];

}
