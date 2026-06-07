{ pkgs, ... }:
{
  imports = [
    ./settings/activitywatch.nix
    ./settings/autostart.nix
    ./settings/environment.nix
    ./settings/hammerspoon.nix
    ./settings/homebrew.nix
    ./settings/networking.nix
    ./settings/power.nix
    ./settings/resticprofile.nix
    ./settings/security.nix
    ./settings/system.nix
    ./settings/tailscale.nix
  ];

  users.users.askielboe = {
    home = "/Users/askielboe";
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
    };
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # Fix the nixbld group ID due to changes in MacOS 15
  # https://github.com/LnL7/nix-darwin/issues/1346
  ids.gids.nixbld = 350;
}
