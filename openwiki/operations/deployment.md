---
type: operations
title: Deployment and store maintenance
description: macOS and Linux activation entrypoints, prebuild ordering, failure boundaries, and scheduled Nix store maintenance.
tags: [deployment, activation, nix, maintenance]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-c8d455969fcf25b782150744
    resource: repo://build-and-switch-darwin.sh
  - id: openwiki-source-e6b0a9eee1c616e97ca20291
    resource: repo://build-and-switch-linux.sh
  - id: openwiki-source-fa6d72dd1035b0e78fcb5a78
    resource: repo://modules/darwin/default.nix
  - id: openwiki-source-3ea34fa0730088afacd514b5
    resource: repo://modules/home-manager/darwin-specific.nix
  - id: openwiki-source-b48d470496f3a5c569de6ee4
    resource: repo://modules/home-manager/linux-specific.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Deployment and store maintenance

## macOS entrypoint

The deployed macOS `hs` is a zsh function from `modules/home-manager/darwin-specific.nix`, not a plain `darwin-rebuild` alias.

Its ordered flow is:

1. Hash calculation for the standalone editor source.
2. Editor rebuilding when the root or hash requires it.
3. System building and activation through `nh darwin switch`, with the configured username.

Hash and editor failures return before the system switch. Extra arguments pass through to `nh`.

The main flake reference is a bare repository path, preserving Git source filtering. The child editor uses a scoped `path:` reference.

`build-and-switch-darwin.sh` is a separate deployment script. It hardcodes the user output and removes `/etc/bashrc` and `/etc/zshrc` before switching.

That script differs from the deployed `hs` function and is not its implementation.

## Linux entrypoints

Linux `hs` detects ARM or x86_64 and switches the corresponding standalone Home Manager output. Unsupported architectures fail before activation.

After a successful switch, the function replaces the shell with `exec $SHELL`. This function does not perform the standalone editor prebuild.

`build-and-switch-linux.sh` accepts a configuration username, defaulting to the runtime user. It detects architecture and constructs the suffixed activation target.

The script prebuilds Neovim, builds the activation package with a restricted environment, and executes `./result/activate`.

`set -euo pipefail` stops the sequence on command failure. A successful build alone does not imply successful activation.

Linux activation attempts to register and select the profile's zsh login shell. Passwordless sudo is preferred; interactive `chsh` requires a terminal.

Without either condition, activation reports that the login shell remains unchanged. This prevents unattended activation from waiting for a password prompt.

## Store maintenance

The Darwin module enables Determinate Nix and configures its evaluator with `eval-cores = 0`.

Determinate's disk-pressure garbage collector is disabled. Separate launchd jobs perform maintenance outside the interactive switch path.

Sunday scheduling places garbage collection at `02:45`, followed by store optimization at `03:15`.

Garbage collection uses `--delete-older-than 7d`. Both jobs disable `RunAtLoad` and write logs under `/var/log/`.

The Catppuccin Cachix substituter and signing key are declared in Determinate's custom settings.

## Operational boundaries

Configuration deployment is a user-run action under the repository's agent instructions. Wiki generation and evaluation do not authorize activation.

Activation includes more than symlink generation: Homebrew cleanup, secret services, shell changes, and user service management can fail independently.

## Related pages

- [Standalone Neovim build](../integrations/neovim.md)
- [Secrets and mutable state](../security/secrets.md)
- [Evaluation and integration validation](../testing/validation.md)
