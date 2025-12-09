# Task Completion Checklist

## After Making Changes

1. **Do NOT run switch commands** - The user will apply changes manually using `hs` alias

2. **No linting/formatting required** - Nix doesn't have a standard formatter configured in this project

3. **No tests** - This is a configuration project without automated tests

4. **Verify syntax** (optional):
   ```bash
   nix flake check
   ```

## Important Notes
- Changes to nix files only take effect after running `hs` (darwin-rebuild switch)
- The user prefers to run the switch command themselves
- Do not add comments or docstrings to code
- Keep changes minimal and focused
