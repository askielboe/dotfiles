{ pkgs, ... }:
{
  imports = [
    ../sops
    ./settings/autostart.nix
    ./settings/environment.nix
    ./settings/homebrew.nix
    ./settings/networking.nix
    ./settings/power.nix
    ./settings/security.nix
    ./settings/system.nix
  ];

  users.users.askielboe = {
    home = "/Users/askielboe";
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Fix the nixbld group ID due to changes in MacOS 15
  # https://github.com/LnL7/nix-darwin/issues/1346
  ids.gids.nixbld = 350;
}
