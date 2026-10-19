---
type: security
title: Secrets and mutable state
description: Separation of evaluation settings, encrypted secrets, runtime keys, OAuth state, and staged secret scanning.
tags: [security, secrets, sops, credentials, state]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-bf5be0c9253ed1d07b502e10
    resource: repo://.githooks/pre-commit
  - id: openwiki-source-3eda5d2b85501c78fc0ba02d
    resource: repo://flake.nix
  - id: openwiki-source-c59fe4336a371ea1052a01dd
    resource: repo://justfile
  - id: openwiki-source-f04a2ccece4ee0a4d9640d35
    resource: repo://modules/home-manager/settings/packages.nix
  - id: openwiki-source-ccca7ec3ebe02eaba8e465f6
    resource: repo://modules/home-manager/settings/shell.nix
  - id: openwiki-source-2b29dad0f6bc13f0115cd11e
    resource: repo://modules/home-manager/settings/sops.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Secrets and mutable state

## Evaluation inputs

`flake.nix` imports `secrets/settings.nix` as `private`. This tracked plaintext file supplies non-sensitive configuration during evaluation.

Sensitive artifacts are declared in `settings/sops.nix` against the tracked, encrypted `secrets/secrets.yaml`.

The age key path is a runtime string beneath the user's home directory. It is not a Nix path literal that copies key material into the store.

The main deployment flake uses Git source filtering. A whole-repository `path:` reference can include ignored runtime files and bypass that protection.

## Decryption and consumers

sops-nix owns activation-time decryption and runtime secret paths. Evaluation does not supply decrypted values to the flake.

The secret declarations include a Todoist collector token, a private SSH fragment, AWS credentials, a 1Password account identifier, and ClickHouse connection references.

SSH and AWS artifacts have explicit destinations at `~/.ssh/config.d/private` and `~/.aws/credentials`.

The shell reads `OP_ACCOUNT` only when its decrypted file is readable. Missing decryption therefore omits the export rather than embedding a fallback secret.

The shell exports `SOPS_AGE_KEY_FILE` pointing to the runtime key location. A valid key and functioning runtime secret service remain deployment prerequisites.

## Mutable application state

Pi's Google OAuth secret is loaded from its runtime credentials directory. Tokens and session state remain outside generated Nix configuration.

The MCP adapter file is writable because the adapter also changes it. Activation merges Nix-owned fields while preserving unrelated object members.

The GYB wrapper creates a writable configuration directory under `XDG_CONFIG_HOME`, defaulting to `~/.config/gyb`.

An explicit later `--config-folder` argument can override that directory. This keeps GYB's default OAuth state away from the read-only package directory.

## Commit protection

`.githooks/pre-commit` scans staged changes with `gitleaks git --staged --redact`.

It uses an installed scanner when available, falls back to `nix-shell`, and fails when neither execution path exists.

`just install-hooks` detects GitButler's managed hook marker. It installs a chained `pre-commit-user` symlink in that case.

Otherwise, installation sets `core.hooksPath` to `.githooks`. `just scan-secrets` scans Git history rather than only staged changes.

A successful scan covers the selected scan input; it does not establish that every ignored runtime file is safe to copy into the store.

## Related pages

- [Pi configuration and Codex transport](../integrations/pi.md)
- [Deployment and store maintenance](../operations/deployment.md)
