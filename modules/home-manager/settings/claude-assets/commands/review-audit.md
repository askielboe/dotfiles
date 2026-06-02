---
description: Read-only maintainability audit of this branch's changes
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(cargo:*), Bash(clippy:*), Bash(ruff:*), Bash(pytest:*), Bash(mypy:*), Bash(vulture:*), Bash(npm:*), Bash(pnpm:*), Bash(tsc:*), Bash(eslint:*)
---
<!--
  Nix-managed (home-manager). This file is a read-only /nix/store symlink at
  ~/.claude/commands/review-audit.md. To change it, edit the source at
  ~/.config/nix/modules/home-manager/settings/claude-assets/commands/review-audit.md
  and re-run `hs`.

  ASSUMPTIONS — edit per repo:
  - Default base branch / trunk is `origin/main`. If a repo uses a different
    trunk, edit the `git diff origin/main...HEAD` line below.
  - `allowed-tools` lists a superset toolchain (Rust/Python/JS). Trim to taste.
-->
# Context (auto-collected — do not ask me to paste anything)
- Status:                  !`git status --short`
- Uncommitted vs HEAD:     !`git diff HEAD`
- Branch changes vs trunk: !`git diff origin/main...HEAD`   # edit origin/main per repo trunk

# Task
This is an AUDIT. Make NO source edits. Ground every finding in the tools listed above — run them; do not eyeball the diff.

For each item: report (a) what you checked / command run, (b) what you found with file:line or "None", (c) suggested action, (d) risk+effort 1-5, (e) safe-to-automate or needs-my-review.

Tooling-grounded (run the tool, report its output):
1. Compiler/linter warnings — run the build + linter for the stack.
2. Dead code — run the analyzer; list CANDIDATES only. Do NOT assume reachability; flag, never delete.
3. Test gaps — coverage on changed lines only.
4. Type safety — run the typechecker / strict flags.

Judgment (flag only, do NOT fix):
5. Functions that are hard to follow — explain why; ignore raw line count.
6. Duplication worth extracting.
7. Magic numbers.
8. Unsafe indexing/unwraps; missing error handling.
9. "Validate by convention" that could become construction — note as a FOLLOW-UP design item; do not refactor.

Persistence (propose a diff, do NOT write):
10. CLAUDE.md / Serena memories — only durable facts that changed this session. No noise.

Output the per-item report, then a summary table: item | finding count | recommended action | automate/review.
End there. No mutations.
