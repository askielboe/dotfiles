{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;

    extraPackages = with pkgs; [
      # Language servers
      nil
      nixd

      # Formatting
      fixjson
      nixfmt
      prettierd
      sqlfluff
      ruff
      shfmt
      stylua
      swiftformat

      # Linting
      checkmake
      deadnix
      eslint_d
      hadolint
      luaPackages.luacheck
      markdownlint-cli
      htmlhint
      shellcheck
      statix
      stylelint
      yamllint
    ];
  };
  imports = [
    ./autocmd.nix
    ./filetypes.nix
    ./keys.nix
    ./plugins
    ./sets.nix
  ];
}
