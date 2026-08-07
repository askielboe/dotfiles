{ config, ... }:

{
  programs = {
    zsh = {
      enable = true;
      autocd = false;
      envExtra = ''
        # Ensure nix-darwin system paths are always available (fixes devshell PATH restrictions)
        typeset -U path
        path=(/etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /opt/homebrew/bin /opt/homebrew/sbin $path)

        # OP_ACCOUNT from the sops-decrypted secret rather than a nix-store-baked
        # sessionVariable; unreadable file (pre-first-decryption) just skips it.
        [ -r ${config.sops.secrets."op-account".path} ] \
          && export OP_ACCOUNT="$(<${config.sops.secrets."op-account".path})"

        # Lets `sops secrets/secrets.yaml` work on Linux too (darwin exports the
        # same path system-wide via modules/darwin/settings/environment.nix).
        export SOPS_AGE_KEY_FILE="$HOME/.config/nix/modules/sops/age/keys.txt"
      '';
      cdpath = [ "~" ];
      initContent = ''
        # worktrunk (wt) shell integration
        command -v wt >/dev/null 2>&1 && eval "$(wt config shell init zsh)"

        # devenv automatic shell activation (cd into a trusted dir → env activates)
        command -v devenv >/dev/null 2>&1 && eval "$(devenv hook zsh)"
      '';
      prezto = {
        enable = true;
        pmodules = [
          "autosuggestions"
          "completion"
          "directory"
          "editor"
          "environment"
          "git"
          "history"
          "history-substring-search"
          "prompt"
          "spectrum"
          "syntax-highlighting"
          "terminal"
          "utility"
        ];
        prompt = {
          theme = "pure";
        };
        extraConfig = ''
          zstyle ':prompt:pure:prompt:success' color green
        '';
      };
      # Platform-specific shell functions will be added by platform modules
    };
  };
}
