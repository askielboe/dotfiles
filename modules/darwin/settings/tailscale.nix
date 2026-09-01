{
  config,
  pkgs,
  lib,
  ...
}:
let
  tailscale = config.services.tailscale.package;

  # Once tailscaled is up and the node is logged in, expose the local Bear MCP
  # bridge (127.0.0.1:9099 — a user LaunchAgent, see home-manager
  # darwin-specific.nix `bear-mcp-bridge`) to tailnet peers as a raw TCP
  # forwarder on port 9099. The k3s cluster's Tailscale egress targets
  # <hostname>.<tailnet>.ts.net:9099 to reach Bear remotely.
  #
  # Raw `--tcp` (not `--https`) needs no cert: the bridge speaks plain HTTP.
  # `tailscale serve` config persists in tailscaled state, so re-asserting on
  # each boot is idempotent. We wait for BackendState=Running so this is a
  # no-op until the one-time `sudo tailscale up` login has happened.
  serveBearBridge = pkgs.writeShellScript "tailscale-serve-bear-bridge" ''
    set -eu
    ts=${lib.getExe' tailscale "tailscale"}
    jq=${lib.getExe pkgs.jq}
    for _ in $(seq 1 60); do
      state=$("$ts" status --json 2>/dev/null | "$jq" -r '.BackendState' 2>/dev/null || true)
      if [ "$state" = "Running" ]; then
        "$ts" set --accept-routes=true
        exec "$ts" serve --bg --tcp 9099 tcp://127.0.0.1:9099
      fi
      sleep 2
    done
    echo "tailscaled not Running after 120s; Bear bridge not exposed on the tailnet." >&2
    echo "Log in once with: sudo tailscale up" >&2
    # Exit non-zero so launchd (KeepAlive.SuccessfulExit = false, below) re-runs
    # us once tailscaled finally comes up, instead of giving up until the next
    # boot/switch. A successful `serve` exits 0 and we're left alone.
    exit 1
  '';
in
{
  # Runs the open-source tailscaled as a root launchd daemon (creates a utun,
  # so this Mac is a first-class tailnet node — no GUI app needed). Login is the
  # only manual step and is needed just once (tailscaled state persists):
  #   sudo tailscale up                          # interactive browser auth, or
  #   sudo tailscale up --authkey tskey-auth-...  # non-interactive (from admin console)
  services.tailscale.enable = true;

  # nix-darwin's services.tailscale ships a bare RunAtLoad-only daemon with no
  # KeepAlive and no logs. So a single tailscaled exit (crash, wake-from-sleep
  # network flap, OOM) drops this node off the tailnet until the next reboot —
  # nothing restarts it — which is exactly what silently killed the Bear bridge
  # (2026-07: tailscaled was dead, `tailscale status` couldn't reach the daemon,
  # the k3s egress to <hostname>.<tailnet>.ts.net:9099 was black-holed).
  # Merge (not replace) extra keys into the module's generated daemon:
  #   * KeepAlive = true  — matches upstream Tailscale's own launchd plist;
  #     launchd relaunches tailscaled on any exit.
  #   * log paths         — the stock daemon writes nowhere, so the outage left
  #     no trail to diagnose from. Never again.
  launchd.daemons.tailscaled.serviceConfig = {
    KeepAlive = true;
    StandardOutPath = "/var/log/tailscaled.out.log";
    StandardErrorPath = "/var/log/tailscaled.err.log";
  };

  launchd.daemons.tailscale-serve-bear-bridge = {
    command = "${serveBearBridge}";
    serviceConfig = {
      Label = "com.user.tailscale-serve-bear-bridge";
      RunAtLoad = true;
      # Assert-once-then-stop: launchd re-runs this job only when it exits
      # non-zero (SuccessfulExit = false). A successful `tailscale serve` exits 0
      # and we stay quiet; if we started before tailscaled was Running and gave
      # up (exit 1), launchd retries every ThrottleInterval until it sticks — so
      # the serve config self-heals after a tailscaled restart instead of
      # requiring a reboot.
      KeepAlive = {
        SuccessfulExit = false;
      };
      ThrottleInterval = 30;
      StandardOutPath = "/var/log/tailscale-serve-bear-bridge.out.log";
      StandardErrorPath = "/var/log/tailscale-serve-bear-bridge.err.log";
    };
  };
}
