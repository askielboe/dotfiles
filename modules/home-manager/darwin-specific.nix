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
    "*".extraOptions = {
      IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
    };
    "github.com".identityFile = "~/.ssh/id_ed25519-github.pub";
    "flextribe".identityFile = "~/.ssh/id_ed25519_flextribe.pub";
    "storagebox-restic".identityFile = "~/.ssh/id_ed25519-storagebox.pub";
    "garage-hetzner".identityFile = "~/.ssh/id_ed25519-hetzner-garage.pub";
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
    # macOS-specific
    colima # Container runtimes on macOS (and Linux) with minimal setup
    mas # Mac App Store CLI

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

