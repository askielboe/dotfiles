# Task runner for the nix config repo. Run `just` to list recipes.

# Path to the vendored GitButler `but` skill, relative to the repo root. Kept in
# sync with `butSkillDir` in modules/home-manager/settings/claude.nix.
but_skill_dir := "modules/home-manager/settings/claude-assets/skills/but"

# List available recipes.
default:
    @just --list

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
