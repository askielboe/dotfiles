# Nix Configuration

## Initial Setup

Before building, you must create your private configuration file:

```bash
cp secrets/private.example.nix secrets/private.nix
```

Then edit `secrets/private.nix` with your personal values:
- `user.name` - Your full name (for git commits)
- `user.email` - Your email address
- `user.username` - Your system username
- `user.homeDirectory` - Your home directory path
- `user.signingKey` - Your SSH signing key (optional)
- `accounts.opAccount` - Your 1Password account ID
- `accounts.awsProfiles` - Your AWS profile configurations
- `machine.computerName` - Your machine hostname
- `ssh.*` - Your SSH host configurations

This file is gitignored and contains your personal/sensitive information.

## macOS Setup

1. Clone this repo to `~/.config/nix`
2. Create private config (see above)
3. Install `nix`
4. Build and switch:
   ```bash
   ./build-and-switch-darwin.sh
   ```

Alternative manual steps:
```bash
nix --extra-experimental-features "nix-command flakes" build '.#darwinConfigurations.<username>.system'
./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix/'.#<username>'
```

## Ubuntu/Linux Setup

1. Clone this repo to `~/.config/nix`
2. Create private config (see above)
3. Install `nix`
4. Install `home-manager`
5. Build and switch:
   ```bash
   ./build-and-switch-linux.sh
   ```

Alternative manual steps:
```bash
nix --extra-experimental-features "nix-command flakes" build '.#homeConfigurations.<username>.activationPackage'
./result/activate
```

## Secrets (SOPS)

For runtime secrets (not nix eval-time), use sops:

```bash
cd modules/sops
sops secrets/restic.yaml
```

Based on https://github.com/lanjoni/snowflake.
