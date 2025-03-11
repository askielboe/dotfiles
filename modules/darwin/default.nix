{ pkgs, ... }: {
  # programs.zsh.enable = true;
  users.users.askielboe.home = "/Users/askielboe";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  imports = [
    ./settings/system.nix
    ./settings/homebrew.nix
  ];

  # Fix the nixbld group ID due to changes in MacOS 15
  # https://github.com/LnL7/nix-darwin/issues/1346
  ids.gids.nixbld = 350;
}
