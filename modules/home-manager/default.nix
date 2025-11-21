{ pkgs, config, ... }:
{
  # Import shared home-manager settings
  imports = [
    ./nixvim
    ./settings/claude.nix
    ./settings/file.nix
    ./settings/git-annex.nix
    ./settings/git.nix
    ./settings/nodejs.nix
    ./settings/ollama.nix
    ./settings/packages.nix
    ./settings/programs.nix
    ./settings/python.nix
    ./settings/shell.nix
    ./settings/ssh.nix
    ./settings/tmux.nix
  ];

  home = {
    username = "askielboe";
    stateVersion = "24.11"; # Keep this unchanged

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      EDITOR = "nvim";
      OP_ACCOUNT = "***REMOVED-SECRET***";
      PAGER = "bat";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      KUBECONFIG = "$HOME/.kube/k3s.yaml";
      YARN_CACHE_FOLDER = "$HOME/.cache/yarn-global";
    };

    shellAliases = {
      ef = "e $(fzf)";
      cf = "cd $(fzf)";
      lg = "lazygit";
      rp = "resticprofile --config ~/.config/restic/profiles.yaml";
      aider = "op run --no-masking aider";
      ai = "aichat -e";
      he = "cd ~/.config/nix/ && nvim && cd -";
      hu = "cd ~/.config/nix/ && nix flake update && cd -";
    };
  };

  catppuccin.enable = true;
}
