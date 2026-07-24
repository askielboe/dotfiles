# Task runner for the nix config repo. Run `just` to list recipes.

# Path to the vendored GitButler `but` skill, relative to the repo root. Kept in
# sync with `butSkillDir` in modules/home-manager/settings/claude.nix.
but_skill_dir := "modules/home-manager/settings/claude-assets/skills/gitbutler"

# List available recipes.
default:
    @just --list

# Install the tracked secret-scanning pre-commit hook. Idempotent, GitButler-aware.
install-hooks:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    chmod +x .githooks/pre-commit
    pc=".git/hooks/pre-commit"
    if [ -f "$pc" ] && grep -q GITBUTLER_MANAGED_HOOK_V1 "$pc"; then
        # GitButler owns .git/hooks/pre-commit and runs `pre-commit-user` first,
        # aborting the commit if it exits non-zero. Chain under it — do NOT set
        # core.hooksPath here, which would disable GitButler's workspace guard.
        ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit-user
        echo "Installed as .git/hooks/pre-commit-user (chains under GitButler's hook)."
    else
        git config core.hooksPath .githooks
        echo "core.hooksPath -> .githooks (pre-commit runs gitleaks on staged changes)."
    fi

# Scan the entire git history for committed secrets.
scan-secrets:
    nix-shell -p gitleaks --run 'gitleaks git --no-banner --redact --verbose'

# Re-vendor the `but` skill to match the installed GitButler app, then commit it.
update-but-skill:
    #!/usr/bin/env bash
    set -euo pipefail
    # Clears the "skill is stale" drift warning printed by `hs` after a GitButler
    # upgrade. After this, re-run `hs` to apply. Safe on a dirty tree: it stages
    # and commits ONLY the skill path via a partial (`--only`) commit, leaving any
    # other staged/unstaged changes exactly as they were. Idempotent.
    cd "{{justfile_directory()}}"
    skill="{{but_skill_dir}}"

    # Regenerate the skill files from the installed `but` CLI into the working tree.
    but skill install --path "$PWD/$skill"

    # Stage adds, modifications, and deletions within the skill dir only.
    git add -A -- "$skill"

    if git diff --cached --quiet -- "$skill"; then
        echo "but skill already up to date — nothing to commit."
        exit 0
    fi

    ver="$(rg -m1 '^version:[[:space:]]*' "$skill/SKILL.md" | sed 's/^version:[[:space:]]*//')"

    # Partial commit: `--only <pathspec>` records just the skill path from the
    # working tree and leaves every other index entry untouched, so a dirty tree's
    # other staged/unstaged changes survive intact.
    git commit --only -m "claude: re-vendor but skill to ${ver:-installed app version}" -- "$skill"

    echo "Committed re-vendored but skill (${ver:-unknown}). Run \`hs\` to apply."
