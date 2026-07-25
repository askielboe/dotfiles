{
  pkgs,
  config,
  private,
  ...
}:
let
  # Wrapper that pre-seeds workspace trust in ~/.claude/.claude.json before launching claude
  # Claude resolves the git root of cwd for the trust check, so we do the same
  claude-trusted = pkgs.writeShellScriptBin "claude-trusted" ''
    CLAUDE_JSON="$HOME/.claude/.claude.json"
    if [ -f "$CLAUDE_JSON" ]; then
      DIR="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
      ${pkgs.lib.getExe pkgs.jq} --arg dir "$DIR" '
        .projects[$dir] //= {} |
        .projects[$dir].hasTrustDialogAccepted = true |
        .projects[$dir].hasClaudeMdExternalIncludesApproved = true |
        .projects[$dir].hasClaudeMdExternalIncludesWarningShown = true
      ' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp" && mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    fi
    exec claude "$@"
  '';
in
{
  # Import shared home-manager settings
  imports = [
    ./nixvim
    ./settings/beets.nix
    ./settings/chromium.nix
    ./settings/claude.nix
    ./settings/clickhouse.nix
    ./settings/factory.nix
    ./settings/file.nix
    ./settings/git-annex.nix
    ./settings/git.nix
    ./settings/nodejs.nix
    ./settings/packages.nix
    ./settings/pi.nix
    ./settings/programs.nix
    ./settings/python.nix
    ./settings/shell.nix
    ./settings/sqlit.nix
    ./settings/ssh.nix
    ./settings/syncthing.nix
    ./settings/tmux.nix
    ./settings/whisper.nix
    ./settings/zed.nix
  ];

  home = {
    inherit (private.user) username;
    stateVersion = "24.11"; # Keep this unchanged

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      EDITOR = "nvim";
      HOMEBREW_NO_ENV_HINTS = "1"; # silence brew's "hide these hints" nag block
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
      he = "cd ~/.config/nix/ && nvim && cd -";
      hu = "cd ~/.config/nix/ && nix flake update && cd -";
      c = "claude";
      ch = "claude-history";
      cs = "claude-squad --program 'claude --dangerously-skip-permissions'";
      ws = "wt switch --create $(openssl rand -hex 4) --execute 'claude-trusted' -- --dangerously-skip-permissions";
      wm = "wt merge";
      cm = "claude --dangerously-skip-permissions --continue 'Fix the merge conflicts. Do NOT merge or commit ONLY do rebase continue. Preserve any functionality added to main outside this branch.'";

    };
  };

  # Catppuccin theming, enabled globally. We WANT it on for every program that
  # supports it (Zed, bat, btop, …) — do NOT disable it per-program as a styling
  # preference. Per-program disables below are bug workarounds only.
  catppuccin.enable = true;

  # SOLE exception, and ONLY because of a home-manager bug — not a preference:
  # catppuccin's gemini-cli module still targets the old `programs.gemini-cli` option,
  # which home-manager renamed to `programs.antigravity-cli`. Left enabled it
  # errors/no-ops against the stale name, so we turn it off here. Keep catppuccin
  # enabled for everything else.
  catppuccin.gemini-cli.enable = false;
}
