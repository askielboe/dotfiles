---
type: operations
title: Bear bridge and tailnet exposure
description: macOS Bear MCP transport, application-level health checks, and persistent TCP forwarding through Tailscale.
tags: [bear, mcp, tailscale, launchd, monitoring]
verified:
  - by: openwiki/0.7.1
    at: 2026-10-07T18:36:55.541Z
sources:
  - id: openwiki-source-cddee7d0f177f57fd87941f4
    resource: repo://modules/darwin/settings/tailscale.nix
  - id: openwiki-source-3ea34fa0730088afacd514b5
    resource: repo://modules/home-manager/darwin-specific.nix
  - id: openwiki-source-f4e91311890dbccc39c580e0
    resource: repo://modules/home-manager/settings/pi.nix
generated: { by: "pi", at: "2026-10-07T18:36:55.541Z" }
---

# Bear bridge and tailnet exposure

## Transport and ownership

Home Manager's `darwin-specific.nix` owns a user LaunchAgent named `bear-mcp-bridge`.

The agent starts `mcp-proxy` through `uvx`, translating Bear's stdio MCP service into HTTP at `127.0.0.1:9099`.

The backend command is `/Applications/Bear.app/Contents/MacOS/bearcli mcp-server`. Availability therefore depends on the macOS application and logged-in user environment.

`uvx` resolves the proxy at runtime. The `mcp<2` constraint limits its MCP dependency because the configured proxy depends on the earlier SDK interface.

Launchd keeps the proxy alive and sets its soft file limit to `8192`. Process survival alone does not establish backend health.

## Health flow

The separate `bear-mcp-watchdog` runs at load and every `300` seconds.

Its probe initializes MCP, sends the initialized notification, and requests the tool list. A positive tool count is the success condition.

The probe accepts JSON or an SSE data frame. Every request has a `15`-second timeout.

A failed first probe receives a grace retry after `15` seconds. Continued failure triggers `launchctl kickstart -k` for the user bridge agent.

Sessions receive best-effort HTTP DELETE cleanup. This limits accumulated session state even when the health request fails.

## Tailnet forwarding

`modules/darwin/settings/tailscale.nix` owns the root `tailscaled` service and a forwarding setup daemon.

The setup waits up to `60` attempts, separated by two seconds, for the backend state to become `Running`.

It then accepts routes and asserts a background raw TCP forward from tailnet port `9099` to the loopback bridge.

A failed setup exits nonzero. Launchd retries failed exits with a `30`-second throttle; successful setup stops the job.

Tailscale authentication remains a prerequisite. Persistent forwarding state does not keep the Mac awake or make Bear available without its user service.

Pi's Bear connector is separate: it starts `bearcli` directly over stdio, not through this HTTP bridge.

## Logs

User logs live under `~/Library/Logs/`:

- `bear-mcp-bridge.out.log`
- `bear-mcp-bridge.err.log`
- `bear-mcp-watchdog.log`

Root service logs live under `/var/log/`:

- `tailscaled.out.log` and `tailscaled.err.log`
- `tailscale-serve-bear-bridge.out.log` and `tailscale-serve-bear-bridge.err.log`

A successful initialization with zero tools is degraded health, even when both launchd and Tailscale report live processes.

## Related pages

- [Pi configuration and Codex transport](../integrations/pi.md)
- [Deployment and store maintenance](deployment.md)
