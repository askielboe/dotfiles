# Suggested Commands

## Build and Apply Configuration

### macOS (Darwin)
```bash
# Using the alias (recommended)
hs

# Or using darwin-rebuild directly
sudo -E darwin-rebuild switch --flake ~/.config/nix#askielboe

# Or using the build script
./build-and-switch-darwin.sh
```

### Linux
```bash
./build-and-switch-linux.sh
```

## Development Commands

### Update Flake Inputs
```bash
nix flake update
# Or use alias
hu
```

### Check Flake
```bash
nix flake check
nix flake show
```

### Build Without Switching (dry-run)
```bash
nix build '.#darwinConfigurations.askielboe.system'
```

## Secrets Management
```bash
cd modules/sops
sops secrets/restic.yaml
```

## Utilities (Darwin/macOS)
- `fd` instead of `find`
- `rg` instead of `grep`
- `bat` as pager
- `lazygit` (alias: `lg`) for git operations
- `nvim` as editor

## Important Aliases
- `hs` - darwin-rebuild switch
- `he` - edit nix config in nvim
- `hu` - update flake inputs
- `lg` - lazygit
