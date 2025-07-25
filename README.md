# How to

## macOS Setup

0. Clone this repo to `/Users/askielboe/.config/nix`
1. Install `nix`
2. Build derivation
   `nix --extra-experimental-features "nix-command flakes" build '.#darwinConfigurations.swaggermis.system'`
3. Switch
   `./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix/'.#swaggermis'`

## Ubuntu/Linux Setup

0. Clone this repo to `/home/askielboe/.config/nix`
1. Install `nix` 
2. Install `home-manager`
3. Build and switch using the provided script:
   `./build-and-switch-home.sh`

Alternative manual steps:
2. Build derivation
   `nix --extra-experimental-features "nix-command flakes" build '.#homeConfigurations.askielboe.activationPackage'`
3. Switch
   `./result/activate`

Based on https://github.com/lanjoni/snowflake.

## Secrets

Create or edit secrets using sops

```bash
cd modules/sops
sops secrets/restic.yaml
```
