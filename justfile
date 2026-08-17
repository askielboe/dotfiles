# Task runner for the nix config repo. Run `just` to list recipes.

# Path to the vendored GitButler `but` skill, relative to the repo root. Kept in
# sync with `butSkillDir` in modules/home-manager/settings/gitbutler.nix.
but_skill_dir := "modules/home-manager/settings/agent-assets/skills/gitbutler"

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
    msg="gitbutler: re-vendor but skill to ${ver:-installed app version}"

    # A raw `git commit` is blocked on the gitbutler/workspace branch by GitButler's
    # managed pre-commit guard, so this must commit via `but` when GitButler owns the
    # repo. Detect that the same way `install-hooks` does. `but skill install` above
    # already requires the `but` CLI; the plain-Git branch only fires post-teardown.
    pc=".git/hooks/pre-commit"
    if [ -f "$pc" ] && grep -q GITBUTLER_MANAGED_HOOK_V1 "$pc"; then
        # Commit ONLY the skill files, matched by path from `but status` so adds,
        # modifications, and deletions are all covered, onto their own branch —
        # every other uncommitted change stays assigned exactly as it was.
        # `-b` creates the branch or reuses it if it already exists, so re-runs are
        # idempotent. Changes are passed as positional CLI IDs.
        ids=()
        while IFS= read -r id; do
            [ -n "$id" ] && ids+=("$id")
        done < <(but status --json \
            | jq -r --arg dir "$skill/" \
                '.uncommittedChanges[] | select(.filePath | startswith($dir)) | .cliId')
        if [ ${#ids[@]} -eq 0 ]; then
            echo "but skill already up to date — nothing to commit."
            exit 0
        fi
        but commit -b revendor-but-skill -m "$msg" "${ids[@]}"
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

# Tier-0 Linux guard: dry-run evaluate the standalone home-manager config for
# Linux straight from macOS — no Linux box needed. Catches eval/overlay/broken-
# platform breakage (e.g. an ungated macOS-only package) in seconds. Run before
# pushing changes that could affect the shared modules.
check-linux arch="aarch64-linux":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    user="$(nix eval --raw --file ./secrets/settings.nix user.username)"
    target=".#homeConfigurations.${user}-{{arch}}.activationPackage"
    echo "Dry-run evaluating ${target} ..."
    nix build --dry-run "$target"
    echo "OK: ${target} evaluates cleanly."

# Tier-2 Linux e2e: full install-Nix -> build -> activate -> smoke-test in a
# throwaway Ubuntu container (native aarch64 on Apple Silicon). Needs Docker /
# colima running. This is the real "does it deploy on Ubuntu" test.
test-linux:
    #!/usr/bin/env bash
    set -euo pipefail
    docker run --rm -v "{{justfile_directory()}}:/work:ro" -w /work ubuntu:24.04 \
        bash tests/linux-e2e.sh

# Same e2e under x86_64 emulation (slower; validates the Intel target too).
test-linux-x86:
    #!/usr/bin/env bash
    set -euo pipefail
    docker run --rm --platform linux/amd64 -v "{{justfile_directory()}}:/work:ro" -w /work ubuntu:24.04 \
        bash tests/linux-e2e.sh

# Build the standalone nixvim child flake (nvim/) and refresh its gc-rooted
# out-link + content-hash stamp. hs runs this automatically; use directly to
# iterate on the nvim config without a full switch.
build-nvim:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    case "$(uname -sm)" in
      "Darwin arm64") sys="aarch64-darwin" ;;
      "Linux aarch64") sys="aarch64-linux" ;;
      "Linux x86_64") sys="x86_64-linux" ;;
      *) echo "unsupported platform: $(uname -sm)" >&2; exit 1 ;;
    esac
    mkdir -p .gc-roots
    nix build "path:$PWD/nvim" --out-link ".gc-roots/nvim-$sys"
    nix hash path "$PWD/nvim" > ".gc-roots/nvim-$sys.hash"
    echo "OK: .gc-roots/nvim-$sys -> $(readlink ".gc-roots/nvim-$sys")"

# Update the nvim child flake's own lock (nixvim + nixpkgs), then rebuild it.
# The hu alias runs the lock update too; this recipe is the standalone form.
update-nvim:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    nix flake update --flake "path:$PWD/nvim"
    just build-nvim
