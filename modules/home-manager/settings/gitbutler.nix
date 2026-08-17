{
  lib,
  pkgs,
  ...
}:
let
  # GitButler detects the installed skill by this directory name, not its frontmatter.
  butSkillDir = ./agent-assets/skills/gitbutler;
  butSkillVersion =
    let
      versionLine = lib.findFirst (lib.hasPrefix "version:") "version: unknown" (
        lib.splitString "\n" (builtins.readFile (butSkillDir + "/SKILL.md"))
      );
    in
    lib.removePrefix "version: " versionLine;

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
  programs.claude-code = {
    settings.hooks.PreToolUse = [ butHook ];
    skills.gitbutler = butSkillDir;
  };

  programs.codex.skills.gitbutler = butSkillDir;

  home.file.".codex/hooks.json".text = builtins.toJSON {
    description = "Protect GitButler-managed repositories from raw git writes.";
    hooks.PreToolUse = [ butHook ];
  };

  home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    checkButSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      plist=/Applications/GitButler.app/Contents/Info.plist
      if [ -f "$plist" ]; then
        cliVersion="$(/usr/bin/defaults read /Applications/GitButler.app/Contents/Info CFBundleShortVersionString 2>/dev/null)"
        if [ -n "$cliVersion" ] && [ "$cliVersion" != "${butSkillVersion}" ]; then
          echo "" >&2
          echo "⚠️  GitButler 'but' skill is stale: vendored ${butSkillVersion}, app $cliVersion." >&2
          echo "    Fix:  cd $HOME/.config/nix && just update-but-skill" >&2
          echo "    then run hs again to apply." >&2
          echo "" >&2
        fi
      fi
    '';
  };
}
