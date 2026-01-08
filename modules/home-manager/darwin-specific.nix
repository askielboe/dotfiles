{ lib, pkgs, private, ... }:
{
  home.homeDirectory = private.user.homeDirectory;

  home.file = {
    ".config/ghostty/config".source = ./dotfiles/ghostty/config;
  };

  home.shellAliases = {
    o = "open .";
    cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
  };

  programs.ssh.matchBlocks = {
    "github.com".identityFile = "~/.ssh/id_ed25519-github";
    "flextribe".identityFile = "~/.ssh/id_ed25519-github";
    "storagebox-restic".identityFile = "~/.ssh/id_ed25519-storagebox";
    "garage-hetzner".identityFile = "~/.ssh/id_ed25519-hetzner-garage";
  };

  programs.zsh.initContent = ''
    hs() {
      echo "darwin-rebuild switch --flake"
      export NIXPKGS_ALLOW_UNFREE=1
      sudo -E darwin-rebuild switch --flake ~/.config/nix/'.#${private.user.username}' --impure
      exec $SHELL
    }
  '';

  home.packages = with pkgs; [
    colima # Container runtimes (docker) on macOS (and Linux) with minimal setup
    ripsecrets # Find secrets
    transmission_4
    yt-dlp
  ];

}
