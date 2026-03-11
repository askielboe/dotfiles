{
  pkgs,
  config,
  private,
  ...
}:
let
  # Wrapper that pre-seeds workspace trust in ~/.claude/.claude.json before launching claude
  claude-trusted = pkgs.writeShellScriptBin "claude-trusted" ''
    CLAUDE_JSON="$HOME/.claude/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      ${pkgs.lib.getExe pkgs.jq} --arg dir "$PWD" \
        '.projects[$dir] //= {} | .projects[$dir].hasTrustDialogAccepted = true' \
        "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    fi
    exec claude "$@"
  '';
in
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
    ./settings/openclaw.nix
    ./settings/packages.nix
    ./settings/programs.nix
    ./settings/screenpipe.nix
    ./settings/python.nix
    ./settings/shell.nix
    ./settings/ssh.nix
    ./settings/tmux.nix
    ./settings/whisper.nix
  ];

  home = {
    username = private.user.username;
    stateVersion = "24.11"; # Keep this unchanged

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      EDITOR = "nvim";
      OP_ACCOUNT = private.accounts.opAccount;
      PAGER = "bat";
      VISUAL = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
      KUBECONFIG = "$HOME/.kube/k3s.yaml";
      YARN_CACHE_FOLDER = "$HOME/.cache/yarn-global";
    };

    packages = [ claude-trusted ];

    shellAliases = {
      ef = "e $(fzf)";
      cf = "cd $(fzf)";
      lg = "lazygit";
      rp = "resticprofile --config ~/.config/restic/profiles.yaml";
      aider = "op run --no-masking aider";
      ai = "aichat -e";
      he = "cd ~/.config/nix/ && nvim && cd -";
      hu = "cd ~/.config/nix/ && nix flake update && cd -";
      c = "claude";
      cs = "claude-squad --program 'claude --dangerously-skip-permissions'";
      ws = "wt switch --create $(openssl rand -hex 4) --execute 'claude-trusted' -- --dangerously-skip-permissions";
      wm = "wt merge";
      cm = "claude --dangerously-skip-permissions --continue 'Fix the merge conflicts. Do NOT merge or commit ONLY do rebase continue. Preserve any functionality added to main outside this branch.'";

    };
  };

  catppuccin.enable = true;
}
