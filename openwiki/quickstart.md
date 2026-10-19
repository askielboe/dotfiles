---
type: quickstart
title: Repository quickstart
description: Supported platforms, configuration ownership, validation entrypoints, and task-oriented routes through this Nix repository.
tags: [quickstart, nix, configuration, navigation]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-8037e2358a2c4f9b2c722a11
    resource: repo://AGENTS.md
  - id: openwiki-source-3eda5d2b85501c78fc0ba02d
    resource: repo://flake.nix
  - id: openwiki-source-c59fe4336a371ea1052a01dd
    resource: repo://justfile
  - id: openwiki-source-3ea34fa0730088afacd514b5
    resource: repo://modules/home-manager/darwin-specific.nix
  - id: openwiki-source-b48d470496f3a5c569de6ee4
    resource: repo://modules/home-manager/linux-specific.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Repository quickstart

## Repository purpose

This flake manages an Apple Silicon macOS system through nix-darwin and user environments through Home Manager.

Standalone Linux outputs cover ARM and x86_64. The unsuffixed username output defaults to ARM Linux.

Tracked Nix configuration owns package declarations and generated settings. Credentials, tokens, histories, and caches remain mutable runtime state.

## Task routes

| Task | Source owner | Wiki page |
| --- | --- | --- |
| Package or platform wiring | `flake.nix`, shared and platform modules | [Configuration graph](architecture/configuration-graph.md) |
| Build and deployment behavior | Platform `hs` functions and deployment scripts | [Deployment](operations/deployment.md) |
| Secrets and credential paths | `settings/sops.nix`, `settings/shell.nix` | [Secrets and mutable state](security/secrets.md) |
| Editor packages and build roots | `nvim/`, `settings/nvim.nix` | [Standalone Neovim](integrations/neovim.md) |
| Pi packages, MCP, and local transport | `settings/pi.nix`, `settings/pi/` | [Pi integration](integrations/pi.md) |
| Bear availability over HTTP or Tailscale | Darwin user agents and Tailscale module | [Bear bridge](operations/bear-bridge.md) |
| Evaluation or deployment regressions | `justfile`, `tests/`, CI, local Pi tests | [Validation](testing/validation.md) |

Paths prefixed with `settings/` in the table are relative to `modules/home-manager/`.

## Validation without activation

`nix flake check` checks flake validity. `just check-linux` dry-runs the ARM activation target; its architecture argument also supports `x86_64-linux`.

`nixfmt`, `statix check .`, and `deadnix .` cover formatting and static Nix checks.

The focused Pi suite runs with `node --experimental-strip-types --test modules/home-manager/settings/pi/*.test.mjs`.

Full Linux tests build and activate within disposable Ubuntu environments. They are distinct from non-activating evaluation checks.

## Deployment ownership

The user applies configuration with `hs`. Agent instructions prohibit running switch commands and Terraform commands during repository work.

The deployed macOS `hs` prebuilds the editor and uses `nh`; Linux `hs` selects the architecture-specific standalone Home Manager output.

`hu` updates both flake locks. `just build-nvim` rebuilds the standalone editor without performing a system switch.

## Evidence and limits

The wiki describes repository source, not the machine's active generation. A declared service or package does not establish that activation succeeded.

Source comments contain some legacy descriptions. The linked system pages distinguish executable behavior where those descriptions differ.
