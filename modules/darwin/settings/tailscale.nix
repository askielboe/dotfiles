{ config, pkgs, lib, ... }:
let
  tailscale = config.services.tailscale.package;

  # Once tailscaled is up and the node is logged in, expose the local Bear MCP
  # bridge (127.0.0.1:9099 — a user LaunchAgent, see home-manager
  # darwin-specific.nix `bear-mcp-bridge`) to tailnet peers as a raw TCP
  # forwarder on port 9099. The k3s cluster's Tailscale egress targets
  # swaggermis.<tailnet>.ts.net:9099 to reach Bear remotely.
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
        exec "$ts" serve --bg --tcp 9099 tcp://127.0.0.1:9099
      fi
      sleep 2
    done
    echo "tailscaled not Running after 120s; Bear bridge not exposed on the tailnet." >&2
    echo "Log in once with: sudo tailscale up" >&2
  '';
in
{
  # Runs the open-source tailscaled as a root launchd daemon (creates a utun,
  # so this Mac is a first-class tailnet node — no GUI app needed). Login is the
  # only manual step and is needed just once (tailscaled state persists):
  #   sudo tailscale up                          # interactive browser auth, or
  #   sudo tailscale up --authkey tskey-auth-...  # non-interactive (from admin console)
  services.tailscale.enable = true;

  launchd.daemons.tailscale-serve-bear-bridge = {
    command = "${serveBearBridge}";
    serviceConfig = {
      Label = "com.user.tailscale-serve-bear-bridge";
      RunAtLoad = true;
      StandardOutPath = "/var/log/tailscale-serve-bear-bridge.out.log";
      StandardErrorPath = "/var/log/tailscale-serve-bear-bridge.err.log";
    };
  };
}
