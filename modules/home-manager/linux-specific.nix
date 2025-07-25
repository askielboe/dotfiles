{ lib, pkgs, ... }:

{
  # Linux-specific home directory
  home.homeDirectory = "/home/askielboe";

  # Automatically set zsh as default shell
  home.activation.make-zsh-default-shell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="/usr/bin:/bin:$PATH"
    ZSH_PATH="/home/askielboe/.nix-profile/bin/zsh"
    if [[ $(getent passwd askielboe) != *"$ZSH_PATH" ]]; then
      echo "setting zsh as default shell (using chsh). password might be necessary."
      if ! grep -q $ZSH_PATH /etc/shells; then
        echo "adding zsh to /etc/shells"
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
      fi
      echo "running chsh to make zsh the default shell"
      chsh -s $ZSH_PATH askielboe
      echo "zsh is now set as default shell !"
    fi
  '';

  # Linux-specific shell configuration
  programs.zsh.initContent = ''
    hs() {
      echo "home-manager switch --flake"
      home-manager switch --flake ~/.config/nix/'.#askielboe'
      exec $SHELL
    }
  '';

}