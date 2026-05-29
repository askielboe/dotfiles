- Never run terraform commands.
- Add rustdoc comments to public APIs (structs, functions, methods).
- Use nix-shell to run command line tools not already in PATH.
- Use alias hs to run darwin-rebuild switch.
- Always use uv for Python projects.
- Always use -f when deleting files.
- Never run nix home manager switch commands - I will run these manually!
- It's 2026, NOT 2025.
- Use fd instead of find.
- Use rg instead of grep.
- NEVER try to fix warnings, errors or other output messages by simply changing the logging behaviour to remove the messages. ALWAYS try to fix the underlying issues. DO NOT sweep anything under the rug!
- It's 2026, NOT 2025.
- Always use justfiles (just) instead of shell scripts or Makefiles for task running.

## Refactoring discipline

For structural or multi-file changes, prefer `/refactor` — it maps blast radius via a read-only subagent, proposes 2–3 distinct options, and stops for my selection before editing. Don't skip the stop. If I want a hard floor (no edits at all until I approve a plan), I'll engage plan mode with Shift+Tab; the soft `/refactor` path is the default.
