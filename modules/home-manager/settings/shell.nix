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
      initContent = ''
        hs() {
          echo "darwin-rebuild switch --flake"
          sudo -E env NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --flake ~/.config/nix/'.#swaggermis' --impure
          exec $SHELL
        }
      '';
    };
  };
}
