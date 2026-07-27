# Nix Configuration

## Initial Setup

Configuration values are split by sensitivity, and both halves are tracked —
the flake evaluates fully pure (no `--impure` anywhere):

- `secrets/settings.nix` — non-sensitive eval-time values (user identity, AWS
  regions). Committed in plaintext; edit directly.
- `secrets/secrets.yaml` — everything sensitive (ssh host blocks, 1Password
  account/item refs, ClickHouse endpoint, sqlit connections). Committed
  [sops](https://github.com/getsops/sops)-encrypted; decrypted at activation
  by [sops-nix](https://github.com/Mic92/sops-nix). Edit with:

  ```bash
  sops secrets/secrets.yaml
  ```

Bootstrapping a new machine needs the age key BEFORE the first switch: copy it
(from a machine that has it, or your password manager) to
`~/.config/nix/modules/sops/age/keys.txt` with mode `0600`. The key is
gitignored and must never be committed. Without it the build still succeeds —
the decrypted files just don't materialize.

The machine name is also not nix-managed (kept out of the public repo); set it
once per machine:

```bash
sudo scutil --set ComputerName <name> && sudo scutil --set HostName <name> && sudo scutil --set LocalHostName <name>
```

## macOS Setup

1. Clone this repo to `~/.config/nix`
2. Install the age key (see above)
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
2. Install the age key (see above)
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

## Secret scanning

Sensitive values (hostnames, 1Password refs, etc.) only ever land in the repo
sops-encrypted inside `secrets/secrets.yaml` (safe to publish; only the key
labels are visible). As a backstop, a tracked pre-commit hook scans staged
changes with [gitleaks](https://github.com/gitleaks/gitleaks) and blocks any
commit that would introduce a plaintext credential.

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
