{ pkgs, ... }:
# Standalone nixvim module (built via makeNixvimWithModule in ../flake.nix, or
# by the parent's in-eval fallback). Options are nixvim's own tree, WITHOUT the
# programs.nixvim prefix — `enable` does not exist in standalone mode.
{
  extraPackages =
    with pkgs;
    [
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
    ]
    # Swift formatter is only wired up on macOS (Swift dev happens there).
    ++ lib.optionals stdenv.isDarwin [ swiftformat ];

  imports = [
    ./autocmd.nix
    ./filetypes.nix
    ./keys.nix
    ./plugins
    ./sets.nix
  ];
}
