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

        # devenv automatic shell activation (cd into a trusted dir → env activates)
        command -v devenv >/dev/null 2>&1 && eval "$(devenv hook zsh)"

        # just: make `just <recipe> <TAB>` complete file paths.
        # just's generated `_just` completer prints the recipe signature (via
        # `_message`) for recipe arguments instead of completing files. Force-load
        # the real function body and rewrite that one branch to fall back to
        # `_files`. If a future just release changes the line, the substitution
        # simply no-ops and upstream behaviour returns — nothing breaks.
        () {
          autoload +X _just 2>/dev/null || return
          local search='_message "`just --show $recipe`"'
          local replace="_arguments -s -S \$common '*:: :_files'"
          functions[_just]=''${functions[_just]//$search/$replace}
        }
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
