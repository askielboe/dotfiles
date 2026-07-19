{ pkgs, ... }:
{
  imports = [
    ./settings/activitywatch.nix
    ./settings/autostart.nix
    ./settings/environment.nix
    ./settings/firewall-prune.nix
    ./settings/homebrew.nix
    ./settings/jankyborders.nix
    ./settings/networking.nix
    ./settings/nix-homebrew.nix
    ./settings/pi-mlx-python.nix
    ./settings/power.nix
    ./settings/resticprofile.nix
    ./settings/security.nix
    ./settings/sketchybar.nix
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
    # Preserve the old nix.optimise.automatic (hardlink dedup on each store add).
    auto-optimise-store = true;
  };

  # Fix the nixbld group ID due to changes in MacOS 15
  # https://github.com/LnL7/nix-darwin/issues/1346
  ids.gids.nixbld = 350;
}
