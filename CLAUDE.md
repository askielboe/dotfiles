# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Nix flake managing system and user configuration for macOS (nix-darwin + home-manager) and Linux (home-manager standalone). All inputs are pinned to the 26.05 release channel.

## Commands

- **Build & apply (macOS):** `hs` (alias for `darwin-rebuild switch --flake ~/.config/nix`)
- **Build & apply (Linux):** `./build-and-switch-linux.sh`
- **Update flake inputs:** `nix flake update` (or alias `hu`, which also bumps `nvim/flake.lock`)
- **Rebuild the standalone neovim:** `just build-nvim` (hs runs this automatically); `just update-nvim` bumps its own lock
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
│   └── settings/                  # packages.nix, shell.nix, git.nix, claude.nix, etc.
├── nvim/                          # Neovim config: standalone nixvim child flake (own flake.lock);
│                                  # prebuilt by the hs pre-step into .gc-roots/, consumed as a
│                                  # store path by settings/nvim.nix (in-eval fallback if absent)
└── secrets/                       # settings.nix (tracked, non-sensitive) + secrets.yaml (tracked, sops-encrypted)
```

**Key patterns:**
- `flake.nix` wires darwin and home-manager together. Darwin config imports `modules/darwin` and includes home-manager as a darwin module. Linux uses home-manager standalone.
- Eval is fully PURE (no `--impure` anywhere). Non-sensitive eval-time values live in `secrets/settings.nix` (tracked plaintext), passed as `specialArgs` to all modules via `private`. Sensitive values live sops-encrypted in `secrets/secrets.yaml` (tracked; edit with `sops secrets/secrets.yaml`), decrypted at activation by sops-nix's home-manager module (declared in `modules/home-manager/settings/sops.nix`; age key at `modules/sops/age/keys.txt`, gitignored — never commit it, never reference it as a nix path literal).
- Small custom packages/wrappers are defined inline in `modules/home-manager/settings/packages.nix`; cross-cutting nixpkgs tweaks go in `sharedOverlays` in flake.nix.
- Homebrew casks/formulae are declared in `modules/darwin/settings/homebrew.nix` and managed by nix-darwin.

## Important Rules

- **Never run home-manager switch commands** — the user runs these manually via `hs`.
- **Never run terraform commands.**
- Use `nix-shell` to run CLI tools not already in PATH.
