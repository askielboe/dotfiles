# Style and Conventions

## Nix Code Style
- Use 2-space indentation
- No comments or docstrings (per user preference)
- Function arguments on same line: `{ pkgs, lib, ... }:`
- Attribute sets with opening brace on same line
- Semicolons at end of attribute assignments
- Use `let ... in` blocks for local bindings when needed

## File Organization
- Each major configuration area has its own `.nix` file in `settings/`
- Platform-specific configs in `darwin-specific.nix` and `linux-specific.nix`
- Imports are organized in `default.nix` files as module entrypoints
- Nixvim plugins each get their own `default.nix` in dedicated subdirectories

## Naming Conventions
- Files: lowercase with hyphens (e.g., `git-annex.nix`)
- Directories: lowercase (e.g., `home-manager`, `nixvim`)

## Module Pattern
Standard module structure:
```nix
{ pkgs, lib, ... }:
{
  imports = [
    ./submodule.nix
  ];

  # Configuration here
}
```

## User Preferences (from CLAUDE.md)
- Never add comments or docstrings
- Use `fd` instead of `find`
- Use `rg` instead of `grep`
- Use `uv` for Python projects
- Use `-f` flag when deleting files
- Never run nix home manager switch commands directly - user will run manually
- Use `nix-shell` to run command line tools not in PATH
