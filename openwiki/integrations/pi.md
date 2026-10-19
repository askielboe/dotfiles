---
type: integration
title: Pi configuration and Codex transport
description: Nix-owned Pi settings, mutable MCP adapter reconciliation, and session-correlated transport metadata and consent.
tags: [pi, mcp, codex, consent, oauth]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-f04a2ccece4ee0a4d9640d35
    resource: repo://modules/home-manager/settings/packages.nix
  - id: openwiki-source-f4e91311890dbccc39c580e0
    resource: repo://modules/home-manager/settings/pi.nix
  - id: openwiki-source-8187125b52d2fd069d078882
    resource: repo://modules/home-manager/settings/pi/codex-mcp-proxy.mjs
  - id: openwiki-source-1e469513a0e12406d59f5437
    resource: repo://modules/home-manager/settings/pi/codex-metadata.ts
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Pi configuration and Codex transport

## Configuration ownership

`settings/pi.nix` enables Pi through its Home Manager module. It declares model defaults, packages, MCP servers, agent instructions, and local extension deployment.

The package list includes MCP adaptation, web access, subagents, goals, OpenWiki, code intelligence, session search, and a footer extension.

The built-in MCP extension is excluded through `-builtin:mcp`. Adapter-specific configuration supplies fields that the native translation does not preserve.

The `openwiki` CLI wrapper executes the package installed under Pi's runtime npm directory. A missing package produces an error before execution.

## Adapter reconciliation

`home.activation.piMcpAdapter` runs after Home Manager's write boundary. It merges a generated patch into the mutable `~/.pi/agent/mcp-adapter.json`.

The existing input must be one JSON object, or absent. A successful merge replaces the file through a temporary file with mode `600`.

Invalid JSON leaves the previous file untouched and fails the activation step. Recursive merging preserves unrelated state rather than replacing the entire adapter file.

## OAuth and platform boundaries

Google connectors cover Gmail, Drive, and Chat for two declared accounts. Their scopes and login hints come from Nix.

The OAuth client secret is read at runtime with `jq` from `~/.pi/agent/credentials/google-workspace-oauth.json`. Its contents are not embedded in the generated patch.

Granola is configured through a remote endpoint. Bear, Enzyme, computer history, and the Codex execution services are Darwin-only integrations.

Codex execution depends on resources within `/Applications/ChatGPT.app` and mutable state within `~/.codex`. Their presence is separate from Nix evaluation success.

## Metadata flow

`codex-metadata.ts` attaches session, turn, call, and optional model identifiers to matching JavaScript calls.

The metadata travels in a base64-encoded code-comment prefix, preserving strict tool schemas. Both direct MCP tools and gateway argument shapes are recognized.

`codex-mcp-proxy.mjs` removes that prefix before execution and transfers metadata to `params._meta["x-codex-turn-metadata"]`.

The proxy runs a child MCP process over line-delimited JSON. Child stderr remains on stderr; transport writes respect stream backpressure.

## Consent boundary

The proxy remembers an explicit acceptance only for a recognized Computer Use application consent form with empty content.

Eligibility requires a correlated call, matching session, application identifier, expected display fields, session persistence, and an empty requested form schema.

Repeated eligible requests reuse acceptance for the same application and warning scope. That scope includes risk level, subtitle, and schema.

A session change clears approvals, pending requests, and tracked calls. Declines, cancellations, and elicitation errors do not grant reusable consent.

Audio recording, unrelated connectors, changed form content, and uncorrelated calls pass through. This mechanism is not general permission for application actions or email sending.

The Nix-generated agent instructions separately require review and approval of the exact email draft before sending.

## Related pages

- [Secrets and mutable state](../security/secrets.md)
- [Bear bridge and tailnet exposure](../operations/bear-bridge.md)
- [Evaluation and integration validation](../testing/validation.md)
