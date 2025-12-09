# Nix Configuration Project

## Purpose
Personal nix-darwin and home-manager configuration for user `askielboe`. Manages system configuration for macOS (darwin) and Linux systems declaratively using Nix flakes.

## Tech Stack
- **Nix Flakes** - Main configuration system
- **nix-darwin** - macOS system configuration (release-25.11)
- **home-manager** - User environment management (release-25.11)
- **nixvim** - Neovim configuration via Nix
- **catppuccin** - Theming
- **sops** - Secrets management

## Project Structure
```
.
├── flake.nix              # Main flake configuration
├── flake.lock             # Locked dependencies
├── modules/
│   ├── darwin/            # macOS-specific system config
│   │   ├── default.nix    # Darwin module entrypoint
│   │   └── settings/      # Individual darwin settings
│   │       ├── homebrew.nix
│   │       ├── mas.nix
│   │       ├── system.nix
│   │       └── ...
│   ├── home-manager/      # User environment config
│   │   ├── default.nix    # Home-manager entrypoint
│   │   ├── darwin-specific.nix
│   │   ├── linux-specific.nix
│   │   ├── settings/      # Individual home settings
│   │   │   ├── claude.nix
│   │   │   ├── git.nix
│   │   │   ├── shell.nix
│   │   │   └── ...
│   │   ├── nixvim/        # Neovim configuration
│   │   │   ├── default.nix
│   │   │   ├── keys.nix
│   │   │   ├── sets.nix
│   │   │   └── plugins/
│   │   └── dotfiles/      # Static config files
│   └── sops/              # Secrets (age keys)
├── build-and-switch-darwin.sh
├── build-and-switch-linux.sh
└── clean-nix.sh
```

## Targets
- **macOS (darwin)**: `darwinConfigurations.askielboe` - aarch64-darwin (Apple Silicon)
- **Linux**: `homeConfigurations.askielboe` - x86_64-linux
