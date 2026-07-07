# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Nix flake managing system and user configuration for macOS (nix-darwin + home-manager) and Linux (home-manager standalone). All inputs are pinned to the 26.05 release channel.

## Commands

- **Build & apply (macOS):** `hs` (alias for `darwin-rebuild switch --flake ~/.config/nix`)
- **Build & apply (Linux):** `./build-and-switch-linux.sh`
- **Update flake inputs:** `nix flake update` (or alias `hu`)
- **Check flake validity:** `nix flake check`
- **Format nix files:** `nixfmt <file>`
- **Lint nix files:** `statix check .` and `deadnix .`

There is no test suite. Validation happens at build time via Nix evaluation.

## Architecture

```
flake.nix                          # Entry point: defines darwin + home-manager configurations
├── modules/darwin/                # macOS system-level (nix-darwin)
│   └── settings/                  # system.nix, homebrew.nix, autostart.nix, etc.
├── modules/home-manager/          # User environment (cross-platform)
│   ├── darwin-specific.nix        # macOS-only: home dir, SSH agent, hs alias
│   ├── linux-specific.nix         # Linux-only adaptations
│   ├── settings/                  # packages.nix, shell.nix, git.nix, claude.nix, etc.
│   └── nixvim/                    # Neovim config (~60 files, plugins/ subdirectory)
├── packages/                      # Custom Nix packages (MCP servers) with own flake.nix
└── secrets/                       # private.nix (gitignored), SOPS age keys
```

**Key patterns:**
- `flake.nix` wires darwin and home-manager together. Darwin config imports `modules/darwin` and includes home-manager as a darwin module. Linux uses home-manager standalone.
- Private/sensitive values live in `secrets/private.nix` (not committed). Copy from `secrets/private.example.nix`. It provides `user`, `accounts`, `machine`, `apiKeys`, and `ssh` attrsets passed as `specialArgs` to all modules via `private`.
- Custom packages (in `packages/`) are exposed via an overlay applied to nixpkgs in flake.nix.
- Homebrew casks/formulae are declared in `modules/darwin/settings/homebrew.nix` and managed by nix-darwin.

## Important Rules

- **Never run home-manager switch commands** — the user runs these manually via `hs`.
- **Never run terraform commands.**
- Use `nix-shell` to run CLI tools not already in PATH.
