_: {
  power = {
    sleep.display = 15;
    sleep.computer = "never";
  };

  # nix-darwin's `power` options only cover idle-sleep timers. The settings below
  # have no nix-darwin equivalent, so we assert them with pmset on each rebuild.
  #
  # Goal: keep this Mac reachable on the tailnet while plugged in, so the k3s
  # gateway can reach the Bear MCP bridge (see tailscale.nix) even with the lid
  # shut. Everything is scoped to charger power (`-c`) so the battery still sleeps
  # normally. Several of these match current macOS defaults, but those defaults
  # are unmanaged — pinning them here makes them survive OS updates and
  # `pmset restoredefaults`.
  #
  # Flags (-c = charger/wall power; scope semantics verified against `man pmset`):
  #   womp          wake on network magic packet ("Wake for network access")
  #   powernap      background activity (incl. networking) during sleep
  #   tcpkeepalive  keep TCP connections alive across sleep
  #   disablesleep  do not sleep on lid close (clamshell) — the only lever for
  #                 lid-close sleep. Absent from `man pmset` but a real flag,
  #                 confirmed live via `pmset -g` (reports as SleepDisabled).
  #                 `-c` keeps it AC-only so the laptop still sleeps on battery.
  #
  # postActivation runs as root at the end of `darwin-rebuild switch` (`hs`).
  system.activationScripts.postActivation.text = ''
    echo "pmset: pinning AC power settings for tailnet reachability" >&2
    /usr/bin/pmset -c womp 1
    /usr/bin/pmset -c powernap 1
    /usr/bin/pmset -c tcpkeepalive 1
    /usr/bin/pmset -c disablesleep 1
  '';
}
