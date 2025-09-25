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

          # Configure pay-respects AI to be more concise
          export _PR_AI_ADDITIONAL_PROMPT="OUTPUT FORMAT: Single corrected command only. NO lists, NO alternatives, NO explanations. For missing commands: use \", <package>\"."
          export _PR_AI_MODEL="llama-3.3-70b-versatile"

          eval "$(pay-respects zsh --alias)"
        '';
      };
      # Platform-specific shell functions will be added by platform modules
    };
  };
}
