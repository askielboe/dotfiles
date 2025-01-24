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
      };
      initExtraFirst = '''';
      initExtra = ''
        hs() {
          echo "home-manager switch --flake"
          home-manager switch --flake "$HOME/.config/home-manager#askielboe"
          exec $SHELL
        }
      '';
    };
  };
}
