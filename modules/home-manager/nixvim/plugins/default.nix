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

  programs.nixvim = {
    plugins = {
      grug-far.enable = true;
      lualine.enable = true;
      lz-n.enable = true;
      noice.enable = true;
      quicker.enable = true;
      trouble.enable = true;
      which-key.enable = true;
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
  };
  home.file.".editorconfig" = {
    text = ''
      root = true

      [*]
      charset = utf-8
      trim_trailing_whitespace = true

      [*.{sh,bash,zsh}]
      indent_style = space
      indent_size = 4

      [Dockerfile*]
      indent_style = space
      indent_size = 4
    '';
  };
}
