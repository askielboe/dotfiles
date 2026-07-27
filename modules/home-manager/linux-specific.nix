{
  lib,
  pkgs,
  private,
  ...
}:

let
  username = private.user.username;
in
{
  # Linux-specific home directory
  home.homeDirectory = "/home/${username}";

  # Make the nix-profile zsh the default login shell. Hardened to never block a
  # non-interactive activation (CI / container e2e): it prefers passwordless sudo,
  # falls back to an interactive self-chsh only when attached to a tty, and
  # otherwise skips with a clear message instead of hanging on a password prompt.
  home.activation.make-zsh-default-shell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="/usr/bin:/bin:$PATH"
    USER_NAME="${username}"
    ZSH_PATH="$HOME/.nix-profile/bin/zsh"
    if [[ -x "$ZSH_PATH" && $(getent passwd "$USER_NAME" 2>/dev/null) != *"$ZSH_PATH" ]]; then
      # Ensure zsh is a valid login shell (needs root to edit /etc/shells).
      if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
        if sudo -n true 2>/dev/null; then
          echo "adding $ZSH_PATH to /etc/shells"
          echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
      fi
      # Switch the login shell.
      if sudo -n true 2>/dev/null; then
        sudo chsh -s "$ZSH_PATH" "$USER_NAME" && echo "default shell -> zsh"
      elif [ -t 0 ] && command -v chsh >/dev/null; then
        echo "setting zsh as default shell (chsh may prompt for your password)"
        chsh -s "$ZSH_PATH" && echo "default shell -> zsh"
      else
        echo "skip: leaving login shell unchanged (no tty / no passwordless sudo); run: chsh -s $ZSH_PATH"
      fi
    fi
  '';

  # Linux-specific shell configuration. `hs` rebuilds the standalone home-manager
  # config for the box's own arch (arm64/x86_64) and re-execs the shell.
  programs.zsh.initContent = ''
    hs() {
      local arch
      case "$(uname -m)" in
        aarch64 | arm64) arch=aarch64-linux ;;
        x86_64) arch=x86_64-linux ;;
        *) echo "hs: unsupported arch $(uname -m)" >&2; return 1 ;;
      esac
      home-manager switch --flake ~/.config/nix#"${username}-''${arch}"
      exec $SHELL
    }
  '';

}
