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
    # upgrade. After this, re-run `hs` to apply. Safe on a dirty tree: it commits
    # ONLY the skill path, leaving any other uncommitted changes exactly as they
    # were. Idempotent.
    cd "{{justfile_directory()}}"
    skill="{{but_skill_dir}}"

    # Regenerate the skill files from the installed `but` CLI into the working tree.
    but skill install --path "$PWD/$skill"

    ver="$(rg -m1 '^version:[[:space:]]*' "$skill/SKILL.md" | sed 's/^version:[[:space:]]*//')"
    msg="claude: re-vendor but skill to ${ver:-installed app version}"

    # A raw `git commit` is blocked on the gitbutler/workspace branch by GitButler's
    # managed pre-commit guard, so this must commit via `but` when GitButler owns the
    # repo. Detect that the same way `install-hooks` does. `but skill install` above
    # already requires the `but` CLI; the plain-Git branch only fires post-teardown.
    pc=".git/hooks/pre-commit"
    if [ -f "$pc" ] && grep -q GITBUTLER_MANAGED_HOOK_V1 "$pc"; then
        # Commit ONLY the skill files, matched by path from `but status` so adds,
        # modifications, and deletions are all covered, onto their own branch —
        # every other uncommitted change stays assigned exactly as it was.
        # `--create` reuses the branch if it already exists, so re-runs are idempotent.
        ids="$(but status --format json \
            | jq -r --arg dir "$skill/" \
                '[.uncommittedChanges[] | select(.filePath | startswith($dir)) | .cliId] | join(",")')"
        if [ -z "$ids" ]; then
            echo "but skill already up to date — nothing to commit."
            exit 0
        fi
        but commit --create revendor-but-skill --changes "$ids" -m "$msg"
    else
        # Plain Git (e.g. after `but teardown`): stage adds/mods/deletions within the
        # skill dir, then a partial (`--only`) commit that leaves every other index
        # entry untouched, so a dirty tree's other changes survive intact.
        git add -A -- "$skill"
        if git diff --cached --quiet -- "$skill"; then
            echo "but skill already up to date — nothing to commit."
            exit 0
        fi
        git commit --only -m "$msg" -- "$skill"
    fi

    echo "Committed re-vendored but skill (${ver:-unknown}). Run \`hs\` to apply."
