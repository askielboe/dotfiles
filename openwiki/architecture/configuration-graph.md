---
type: architecture
title: Configuration graph and package ownership
description: Flake composition, platform boundaries, and ownership of package sources across macOS and Linux.
tags: [nix, architecture, packages, platforms]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-3eda5d2b85501c78fc0ba02d
    resource: repo://flake.nix
  - id: openwiki-source-29a25ac8d23c4fcd1f8aeda4
    resource: repo://modules/darwin/settings/homebrew.nix
  - id: openwiki-source-a9d3413c890edec3ce3dc8ae
    resource: repo://modules/darwin/settings/nix-homebrew.nix
  - id: openwiki-source-f04a2ccece4ee0a4d9640d35
    resource: repo://modules/home-manager/settings/packages.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Configuration graph and package ownership

## Composition

`flake.nix` imports tracked, non-sensitive settings from `secrets/settings.nix` and derives configuration names from `private.user.username`.

The macOS output targets `aarch64-darwin`. Its nix-darwin system embeds Home Manager, shares system packages, and imports the shared home configuration plus `darwin-specific.nix`.

Linux uses standalone Home Manager through `mkLinuxHome`. Architecture-suffixed outputs cover `aarch64-linux` and `x86_64-linux`; the unsuffixed username selects ARM Linux.

Both paths receive Pi, sops-nix, nix-index, and Catppuccin modules. `modules/home-manager/default.nix` imports shared settings; platform modules supply home directories and platform-specific behavior.

## Package sources

The main stable package input follows `nixpkgs-26.05-darwin`. Home Manager and nix-darwin use their 26.05 release branches. `flake.lock` fixes resolved revisions.

`mkPkgs` enables unfree packages and applies shared overlays on every platform. Its resticprofile override disables package checks, including on Linux.

`settings/packages.nix` owns shared CLI packages and local wrappers. Its conditional lists separate macOS-only tools from Linux packages, including different Codex distributions.

Selective imports from `nixpkgs-unstable` supply packages such as devenv and repomix. These imports retain the host system and enable unfree packages.

## macOS application ownership

`modules/darwin/settings/homebrew.nix` declares formulae, casks, App Store applications, and tap trust. Activation enables cleanup with `zap` and `--force-cleanup`.

`nix-homebrew.nix` manages Homebrew itself and pins three third-party taps through flake inputs. Core formulae and casks remain mutable through Homebrew's API.

The same third-party taps appear in two forms: short Brewfile names and on-disk repository names. Changes span both modules and the flake input declarations.

Tap trust is generated from the Brewfile tap list. Activation writes writable, user-owned copies for both sudo-driven activation and interactive Homebrew.

Removed pinned taps can leave root-owned directories. Installed formulae from removed taps can also make cleanup fail; these are activation risks, not automatic cleanup guarantees.

## Extension boundaries

Shared user settings enter through `modules/home-manager/default.nix`; macOS system settings enter through `modules/darwin/default.nix`.

Cross-platform package overrides belong to the flake's shared overlay list. Small wrappers belong to the package module that installs them.

The editor has a separate build graph described in [Standalone Neovim build](../integrations/neovim.md).

## Related pages

- [Deployment and store maintenance](../operations/deployment.md)
- [Secrets and mutable state](../security/secrets.md)
