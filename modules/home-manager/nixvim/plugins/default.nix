{ lib, ... }:
let
  inherit (builtins) readDir;
  inherit (lib.attrsets) foldlAttrs;
  inherit (lib.lists) optional;
  by-name = ./.;
in
{
  imports = foldlAttrs (
    prev: name: type:
    prev ++ optional (type == "directory") (by-name + "/${name}")
  ) [ ] (readDir by-name);

  programs.nixvim.plugins = {
    alpha = {
      enable = true;
      theme = "dashboard";
    };
    grug-far.enable = true;
    lualine.enable = true;
    lz-n.enable = true;
    noice.enable = true;
    which-key.enable = true;
    quicker.enable = true;
  };
}
