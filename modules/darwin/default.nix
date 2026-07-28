{ pkgs, ... }:
{
  imports = [
    ./settings/autostart.nix
    ./settings/environment.nix
    ./settings/firewall-prune.nix
    ./settings/gchat.nix
    ./settings/homebrew.nix
    ./settings/jankyborders.nix
    ./settings/networking.nix
    ./settings/nix-homebrew.nix
    ./settings/power.nix
    ./settings/resticprofile.nix
    ./settings/security.nix
    ./settings/spotlight.nix
    ./settings/system.nix
    ./settings/tailscale.nix
  ];

  users.users.askielboe = {
    home = "/Users/askielboe";
  };

  # Nix itself is managed by Determinate (see the `determinate` input + module in
  # flake.nix), NOT nix-darwin. `determinateNix.enable` disables nix-darwin's Nix
  # management; settings below are written to /etc/nix/nix.custom.conf.
  determinateNix.enable = true;
  determinateNix.customSettings = {
    # The point of the migration: parallel evaluation across all 10 cores.
    # 0 = all cores. (Determinate 3.16+ already defaults to unlimited; explicit.)
    eval-cores = 0;
    # Deliberately NOT `auto-optimise-store`: that hard-links store paths inline
    # on every store write, i.e. it puts dedup on the interactive `hs` path. It
    # is NOT the old `nix.optimise.automatic` (that was a weekly, off-path launchd
    # job). Enabling it against a store with a link backlog turned one `hs` into a
    # ~6-min inline `nix store optimise`. Store dedup is background maintenance —
    # see launchd.daemons.nix-optimise below, which runs it weekly, off the path.
    # Catppuccin builds its own `whiskers` (a Rust binary, ~10 min from source)
    # which isn't on cache.nixos.org. It's a build-only tool with no runtime GC
    # root, so Determinate's disk-pressure GC evicts it between switches — pull
    # it from the project's Cachix instead of recompiling every `hs`.
    extra-substituters = [ "https://catppuccin.cachix.org" ];
    extra-trusted-public-keys = [
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };

  # Disable Determinate Nixd's free-space-triggered automatic GC. This disk
  # lives at ~95% full, so the trigger is permanently armed: measured 2026-07-27,
  # it fired a GC pass on essentially every daemon build request (26 passes in
  # one afternoon), each deleting almost nothing but holding the store lock
  # through a full "deleting unused links" scan of the 45G store — every
  # `nix build` stalled ~5 min at 0% CPU in buildPathsWithResults, and `hs`
  # ballooned to ~9 min. GC is background maintenance, not a per-build tax:
  # the weekly launchd job below (nix-gc, Sundays 02:45, before nix-optimise
  # at 03:15) restores the old nix-darwin `nix.gc.automatic` policy instead.
  determinateNix.determinateNixd.garbageCollector.strategy = "disabled";

  # Fix the nixbld group ID due to changes in MacOS 15
  # https://github.com/LnL7/nix-darwin/issues/1346
  ids.gids.nixbld = 350;

  # Weekly store optimise, OFF the interactive `hs` path. This restores the old
  # `nix.optimise.automatic` behaviour (a weekly, off-path launchd job), which
  # determinateNix.enable disables. Hard-linking duplicate store files is
  # background maintenance — keeping it here means `hs` never pays for it (see
  # the auto-optimise-store note above). Sundays 03:15; RunAtLoad off so it can
  # never fire during a switch. Uses the stable profile symlink so it survives
  # Determinate upgrades.
  launchd.daemons.nix-optimise.serviceConfig = {
    ProgramArguments = [
      "/nix/var/nix/profiles/default/bin/nix"
      "store"
      "optimise"
    ];
    StartCalendarInterval = [
      {
        Weekday = 0;
        Hour = 3;
        Minute = 15;
      }
    ];
    RunAtLoad = false;
    StandardOutPath = "/var/log/nix-optimise.log";
    StandardErrorPath = "/var/log/nix-optimise.log";
  };

  # Weekly GC, OFF the interactive `hs` path — replaces Determinate Nixd's
  # disabled automatic GC (see determinateNixd.garbageCollector.strategy above)
  # with the old nix-darwin `nix.gc.automatic` + `--delete-older-than 7d`
  # policy. Sundays 02:45, deliberately BEFORE nix-optimise at 03:15: delete
  # first, then hard-link what remains. RunAtLoad off so it can never fire
  # during a switch.
  launchd.daemons.nix-gc.serviceConfig = {
    ProgramArguments = [
      "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
      "--delete-older-than"
      "7d"
    ];
    StartCalendarInterval = [
      {
        Weekday = 0;
        Hour = 2;
        Minute = 45;
      }
    ];
    RunAtLoad = false;
    StandardOutPath = "/var/log/nix-gc.log";
    StandardErrorPath = "/var/log/nix-gc.log";
  };
}
