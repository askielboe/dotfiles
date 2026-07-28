{ lib, ... }:
{
  # The macOS Application Layer Firewall (socketfilterfw) keys its per-app "allow
  # incoming connections" exceptions by ABSOLUTE binary path, and re-runs an
  # expensive code-signature assessment whenever it meets a path it has no cached
  # verdict for. Nix store paths are content-addressed, so every rebuild or
  # version bump moves a binary to a brand-new /nix/store/<hash>/... path, and
  # `nix.gc` (weekly, see ../default.nix) deletes the old one. The firewall never
  # cleans up after itself, so its exception list fills with dead /nix paths while
  # the live daemons (colima/lima) — which are ad-hoc-signed and open listening
  # sockets constantly — get re-assessed from scratch on every launch.
  # Net effect: socketfilterfw burns CPU walking a half-dead list and re-verifying
  # binaries whose verdict it can never cache across the path churn.
  #
  # Fix: after each `darwin-rebuild switch`, drop every exception whose /nix path
  # no longer exists. Scoped to /nix ONLY — a content-addressed store path that's
  # been GC'd is gone forever (its hash is unique), so removing it is always safe
  # and correct. Non-nix dead entries (e.g. an app on a temporarily-unmounted
  # volume) are deliberately left alone; prune those by hand if they accumulate.
  #
  # postActivation runs as root at the end of `hs`. mkAfter so this concatenates
  # with the postActivation.text in spotlight.nix / power.nix (the option is
  # types.lines).
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "firewall: pruning dead /nix exceptions from the application firewall" >&2
    fw=/usr/libexec/ApplicationFirewall/socketfilterfw
    pruned=0
    if [ -x "$fw" ]; then
      # Parse `N : /path ` lines, keep only /nix entries, strip the trailing space.
      for p in $("$fw" --listapps 2>/dev/null \
        | /usr/bin/sed -n 's/^[0-9][0-9]* : \(\/nix\/[^ ]*\)[[:space:]]*$/\1/p'); do
        if [ ! -e "$p" ]; then
          echo "firewall:   removing dead exception $p" >&2
          "$fw" --remove "$p" >/dev/null 2>&1 && pruned=$((pruned + 1))
        fi
      done
      [ "$pruned" -gt 0 ] && echo "firewall: pruned $pruned dead /nix exception(s)" >&2 || true
    fi
  '';
}
