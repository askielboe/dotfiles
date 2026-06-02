---
description: Apply approved findings from /review-audit, one logical group per commit
argument-hint: <approved item numbers/categories, e.g. "1,2,6">
allowed-tools: Read, Grep, Glob, Edit, MultiEdit, Write, Bash(git diff:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(cargo:*), Bash(clippy:*), Bash(ruff:*), Bash(pytest:*), Bash(mypy:*), Bash(npm:*), Bash(pnpm:*), Bash(tsc:*), Bash(eslint:*)
---
<!--
  Nix-managed (home-manager). This file is a read-only /nix/store symlink at
  ~/.claude/commands/review-fix.md. To change it, edit the source at
  ~/.config/nix/modules/home-manager/settings/claude-assets/commands/review-fix.md
  and re-run `hs`.

  ASSUMPTIONS — edit per repo:
  - Default base branch / trunk is `origin/main`. If a repo uses a different
    trunk, edit the `git diff origin/main...HEAD` line below.
  - `allowed-tools` lists a superset toolchain (Rust/Python/JS). Trim to taste.
-->
# Context
- Status:                  !`git status --short`
- Branch changes vs trunk: !`git diff origin/main...HEAD`   # edit origin/main per repo trunk

# Task
Apply ONLY these approved findings: $ARGUMENTS

Rules:
- Re-locate each approved finding (re-run the relevant tool). Touch nothing outside the approved set.
- Work in logical groups, ONE commit per group. After each group, run build + tests + linter. A group is "resolved" only when those pass — not on your say-so. If they fail, fix or revert the group; do not proceed.
- Dead-code removals require confirmation from the analyzer first. Never blanket-delete based on a diff scan.
- "Validate by convention → construction" and other architecture items are OUT OF SCOPE unless explicitly in $ARGUMENTS.
- Do not amend or rebase existing commits. Do not push.

After all groups: show the commits made (oneline) and a table: item | what changed | build/test/lint status. Stop.
