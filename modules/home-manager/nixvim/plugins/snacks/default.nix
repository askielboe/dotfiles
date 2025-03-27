{ inputs, pkgs, ... }:
{
  programs.nixvim.plugins.snacks = {
    enable = true;
  };
  imports = [
    ./explorer.nix
    ./picker.nix
  ];
}
