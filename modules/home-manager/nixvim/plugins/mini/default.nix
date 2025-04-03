{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./ai.nix
    ./starter.nix
    ./surround.nix
  ];

  programs.nixvim.plugins.mini = {
    enable = true;
    mockDevIcons = true;
    modules = {
      icons = { };
      indentscope = {
        symbol = "│";
      };
      jump = { };
      move = { };
      pairs = { };
      trailspace = { };
    };
  };
}
