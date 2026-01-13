{ lib, ... }:

{
  programs = {
    zsh = {
      enable = true;
      autocd = false;
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
