---
type: integration
title: Standalone Neovim build
description: Independent nixvim evaluation, platform-specific build roots, hash guards, and the parent configuration fallback.
tags: [neovim, nixvim, build, caching]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-e6b0a9eee1c616e97ca20291
    resource: repo://build-and-switch-linux.sh
  - id: openwiki-source-3ea34fa0730088afacd514b5
    resource: repo://modules/home-manager/darwin-specific.nix
  - id: openwiki-source-fb5e0da87e5353466bb46333
    resource: repo://modules/home-manager/settings/nvim.nix
  - id: openwiki-source-f67bf2b038f9586d95c32c69
    resource: repo://nvim/default.nix
  - id: openwiki-source-46e9e27676635d43fda701f5
    resource: repo://nvim/flake.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Standalone Neovim build

## Build ownership

`nvim/flake.nix` exposes the same editor module on Apple Silicon macOS, ARM Linux, and x86_64 Linux.

Its own `flake.lock` pins nixpkgs and nixvim separately from the parent flake. The default package is the generated Neovim distribution.

`nvim/default.nix` imports editor settings, keybindings, filetype rules, autocommands, and plugins. Extra packages supply language servers, formatters, and linters; Swift formatting is Darwin-only.

## macOS prebuild flow

The macOS `hs` function hashes the `nvim/` directory before rebuilding the system.

A missing root or mismatched hash triggers `nix build` against the child `path:` reference. Success refreshes the root and its hash stamp.

The root is `.gc-roots/nvim-aarch64-darwin`. The hash stamp uses the same path with `.hash` appended.

A failed hash or editor build returns before system activation. The root existence check follows its symlink, so a dangling root triggers another build.

`just build-nvim` implements the same platform-specific root convention for all three systems. The standalone deployment scripts prebuild the editor but omit the hash stamp.

## Parent selection and fallback

`settings/nvim.nix` searches an environment-derived home path, then known macOS and Linux home paths, for the host's editor root.

A candidate qualifies only when `bin/nvim` exists through the root. This avoids selecting a dangling symlink solely because the symlink exists.

A qualifying candidate is converted with `builtins.storePath`. Otherwise, the parent evaluates the editor module through its own nixvim input and package set.

The child and fallback share module source, but their independently pinned inputs can differ. Identical source does not imply identical package closures.

## Evaluation boundary

The parent deployment commands omit `--impure`. Under pure evaluation, `builtins.getEnv "HOME"` supplies no environment-derived candidate.

Comments in `settings/nvim.nix` describe impure entrypoints, but the executable deployment commands do not request that mode.

Successful child prebuilding alone does not prove that the parent selected the root. Root visibility and `builtins.storePath` remain evaluation constraints.

## Lock lifecycle

`hu` updates both parent and child locks. `just update-nvim` updates the child lock and rebuilds its package.

## Related pages

- [Deployment and store maintenance](../operations/deployment.md)
- [Evaluation and integration validation](../testing/validation.md)
