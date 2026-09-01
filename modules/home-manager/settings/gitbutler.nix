{
  pkgs,
  ...
}:
let
  butGitGuard = pkgs.writeShellScript "but-git-guard" ''
    input=$(cat)
    cmd=$(${pkgs.jq}/bin/jq -r '.tool_input.command // ""' <<<"$input")
    cwd=$(${pkgs.jq}/bin/jq -r '.cwd // ""' <<<"$input")
    [ -z "$cwd" ] && cwd="$PWD"

    ${pkgs.git}/bin/git -C "$cwd" show-ref --verify --quiet refs/heads/gitbutler/workspace 2>/dev/null || exit 0

    re='(^|[^[:alnum:]_])git[[:space:]]+(((-C|-c|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+|--?[[:alnum:]-]+)[[:space:]]+)*(add|commit|push|pull|checkout|switch|merge|rebase|stash|cherry-pick|restore|reset|revert|am|clean|rm|mv|tag)([[:space:]]|$)'
    if [[ "$cmd" =~ $re ]]; then
      echo 'BLOCKED: this repo is GitButler-managed (gitbutler/workspace). Use the `but` CLI for write operations:' >&2
      echo '  but diff' >&2
      echo '  but commit -b <branch> -m "msg" <ids>' >&2
      echo '  but push <branch> | but undo' >&2
      exit 2
    fi
  '';

  butHook = {
    matcher = "Bash";
    hooks = [
      {
        type = "command";
        command = "${butGitGuard}";
      }
    ];
  };
in
{
  programs.claude-code.settings.hooks.PreToolUse = [ butHook ];
}
