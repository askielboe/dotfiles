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

  plugins = {
    grug-far.enable = true; # Search replace
    lualine.enable = true; # Status line
    lz-n.enable = true; # Lazy loading
    multicursors.enable = true;
    noice.enable = true; # Notifications
    oil.enable = true;
    quicker.enable = true; # Quick select
    trouble.enable = true; # Diagnostics
    which-key.enable = true; # Keymaps pop-over
  };
  editorconfig.enable = true;
  extraConfigLua = ''
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅚",
          [vim.diagnostic.severity.WARN] = "󰀦",
          [vim.diagnostic.severity.INFO] = "󰋼",
          [vim.diagnostic.severity.HINT] = "󰌵",
        }
      }
    })
  '';
}
