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

## Secret scanning

Nix eval-time secrets and machine-specific values (tokens, hostnames, a work
email, etc.) live in `secrets/private.nix`, which is gitignored and never
committed. As a backstop, a tracked pre-commit hook scans staged changes with
[gitleaks](https://github.com/gitleaks/gitleaks) and blocks any commit that would
introduce a credential (including an accidental `git add -f secrets/private.nix`).

Enable it once per clone:

```bash
just install-hooks
```

It's GitButler-aware: under a GitButler workspace it installs as `pre-commit-user`
so it chains beneath GitButler's own hook; otherwise it sets `core.hooksPath`.
Note that GitButler's `but commit` does not run git hooks by default, so the hook
primarily guards raw `git commit`. To audit the full history at any time:

```bash
just scan-secrets
```
