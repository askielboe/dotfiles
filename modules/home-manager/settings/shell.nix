{ lib, ... }:

{
  programs = {
    zsh = {
      enable = true;
      autocd = false;
      cdpath = [ "~" ];
      prezto = {
        enable = true;
        pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "history-substring-search"
          "prompt"
          "git"
          "autosuggestions"
          "syntax-highlighting"
        ];
        prompt = {
          theme = "pure";
        };
        extraConfig = ''
          zstyle ':prompt:pure:prompt:success' color green
        '';
      };
      initExtraFirst = '''';
      initExtra = ''
        hs() {
          echo "darwin-rebuild switch --flake"
          darwin-rebuild switch --flake ~/.config/nix/'.#swaggermis'
          exec $SHELL
        }
      '';
    };
  };
}
