{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;

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
  };
  imports = [
    ./autocmd.nix
    ./filetypes.nix
    ./keys.nix
    ./plugins
    ./sets.nix
  ];
}
