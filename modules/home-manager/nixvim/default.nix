{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;

    extraPackages = with pkgs; [
      # Formatting
      fixjson
      nixfmt-rfc-style
      prettierd
      python313Packages.sqlfmt
      ruff
      shfmt
      stylua
      swiftformat
      yamlfmt

      # Linting
      checkmake
      deadnix
      eslint_d
      hadolint
      luaPackages.luacheck
      markdownlint-cli
      nodePackages.htmlhint
      nodePackages.jsonlint
      shellcheck
      statix
      stylelint
      yamllint

      # Other
      gh # blink
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
