{ lib, ... }:

{
  programs = {
    zsh = {
      enable = true;
      autocd = false;
      envExtra = ''
        # Ensure nix-darwin system paths are always available (fixes devshell PATH restrictions)
        typeset -U path
        path=(/etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /opt/homebrew/bin /opt/homebrew/sbin $path)
      '';
      cdpath = [ "~" ];
      initContent = ''
        # worktrunk (wt) shell integration
        command -v wt >/dev/null 2>&1 && eval "$(wt config shell init zsh)"
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
