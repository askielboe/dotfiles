---
type: testing
title: Evaluation and integration validation
description: Linux evaluation guards, throwaway Ubuntu activation tests, local Pi transport tests, and the limits of each validation layer.
tags: [testing, validation, linux, ci, pi]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-9018197b476ad6518f304934
    resource: repo://.github/workflows/linux-e2e.yml
  - id: openwiki-source-c59fe4336a371ea1052a01dd
    resource: repo://justfile
  - id: openwiki-source-da2ff6beea1a3b952ed60116
    resource: repo://modules/home-manager/settings/pi/codex-mcp-proxy.test.mjs
  - id: openwiki-source-ea80893d290c8d86e2ca2e9d
    resource: repo://modules/home-manager/settings/pi/codex-metadata.test.mjs
  - id: openwiki-source-917280e7a6a5f421c7c603b3
    resource: repo://tests/linux-e2e.sh
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Evaluation and integration validation

## Validation layers

The repository contains both deployment smoke tests and focused JavaScript tests. The statement in `AGENTS.md` that no test suite exists omits these executable checks.

| Check | Scope | Boundary |
| --- | --- | --- |
| `nix flake check` | Flake validity | Does not prove application integrations work |
| `just check-linux` | ARM Linux activation target evaluation | Dry run; no activation |
| `just check-linux x86_64-linux` | Intel Linux target evaluation | Dry run; no activation |
| `just test-linux` | Ubuntu container build, activation, and smoke checks | Changes only a throwaway environment |
| `just test-linux-x86` | Same container path under x86_64 emulation | Requires Docker and emulation |
| Local Pi tests | Metadata and consent proxy contracts | Synthetic backend, not live application permissions |

`nixfmt`, `statix`, and `deadnix` provide formatting and static checks. They do not replace platform evaluation.

## Linux end-to-end flow

`tests/linux-e2e.sh` routes behavior by user ID. Root installs prerequisites, creates a throwaway user, stages the repository, and re-executes as that user.

The build user stages the repository under `~/.config/nix` when necessary and changes the staged settings username to match the runtime account.

Nix installation occurs only when missing. The script starts a daemon when needed and waits for store connectivity before deployment.

`build-and-switch-linux.sh` builds and activates the matching architecture output. The smoke phase checks `zsh`, `nvim`, `tmux`, `rg`, `fd`, and `git`.

It also starts an interactive zsh configuration and runs headless Neovim with a `180`-second timeout. Any missing binary or failed startup makes the test fail.

This test provisions accounts and activates configuration. Its intended boundary is a disposable container or CI runner, not the user's workstation.

## Continuous integration

`.github/workflows/linux-e2e.yml` runs on main-branch pushes, pull requests, and manual dispatch.

It uses an ARM Ubuntu runner with a `60`-minute timeout. Concurrent runs for the same Git reference cancel earlier runs.

The workflow executes the end-to-end script with sudo. The executable script uses tracked settings, despite workflow comments mentioning a private-file fixture.

## Pi transport tests

`codex-metadata.test.mjs` covers direct tools, namespace proxies, and gateway calls. It verifies prefix contents, unchanged unrelated tools, and turn changes within one session.

`codex-mcp-proxy.test.mjs` launches the real proxy against a synthetic line-delimited MCP backend.

Its cases cover repeated acceptance, changed apps and warnings, session changes, declined requests, malformed scopes, unrelated forms, and missing correlation.

The focused invocation is `node --experimental-strip-types --test modules/home-manager/settings/pi/*.test.mjs` on a Node runtime supporting TypeScript stripping.

## Coverage limits

Linux smoke checks do not exercise macOS launchd, Homebrew cleanup, or actual secret decryption. Pi transport tests do not establish live Chrome or native-app connectivity.

The end-to-end script treats the throwaway environment's missing age key as separate from shell and editor smoke coverage.

## Related pages

- [Deployment and store maintenance](../operations/deployment.md)
- [Pi configuration and Codex transport](../integrations/pi.md)
- [Standalone Neovim build](../integrations/neovim.md)
