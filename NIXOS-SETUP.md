# NixOS Setup

This setup extends the existing nix-darwin dotfiles to support NixOS deployments with shared configuration.

## Structure

- `modules/shared/` - Shared configuration between Darwin and NixOS
  - `nixvim/` - Neovim configuration (reuses existing nixvim setup)
  - `shell.nix` - Zsh shell configuration
  - `packages.nix` - CLI tools and packages
  - `home.nix` - Common home-manager settings
- `modules/home-manager/darwin-specific.nix` - macOS-specific settings
- `modules/home-manager/nixos-specific.nix` - Linux-specific settings
- `nixos/` - NixOS system configuration
- `deploy-nixos.sh` - Deployment script for remote servers

## Deployment

1. **Prepare hardware configuration**:
   ```bash
   # On the target NixOS server, generate hardware config
   nixos-generate-config --root /mnt
   # Copy the generated hardware-configuration.nix to nixos/hardware-configuration.nix
   ```

2. **Update configuration**:
   - Add your SSH public key to `nixos/configuration.nix`
   - Update hardware-configuration.nix with the actual hardware config
   - Adjust hostname in flake.nix if needed (currently `nixos-server`)

3. **Deploy**:
   ```bash
   ./deploy-nixos.sh [hostname]
   ```

## Features Included

- ✅ Neovim with full nixvim configuration
- ✅ Zsh with prezto and pure theme
- ✅ All CLI tools from the Darwin setup
- ✅ Git configuration
- ✅ SSH configuration
- ✅ Shared aliases and environment variables
- ✅ Docker support
- ✅ Minimal system packages

## Platform Differences

**Darwin (macOS)**:
- Includes macOS-specific packages (colima, mas)
- Darwin-specific aliases (open, cfgutil)
- Full desktop environment modules

**NixOS (Linux)**:
- Server-focused configuration
- Essential modules only (git, programs, ssh)
- Docker enabled
- SSH server configured

## Usage

After deployment, you can rebuild the system with:
```bash
# On the NixOS server
hs  # Shortcut for nixos-rebuild switch --flake
```

The configuration automatically sets up the same development environment you have on macOS, including your full Neovim setup and CLI tools.