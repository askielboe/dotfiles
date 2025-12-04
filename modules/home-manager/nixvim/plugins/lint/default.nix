{
  programs.nixvim.plugins = {
    lint = {
      enable = true;

      lazyLoad.settings.event = "DeferredUIEnter";

      linters.sqlfluff = {
        # Use project-local sqlfluff via uv because sqlfluff-templater-dbt
        # is not available in nixpkgs. Projects using dbt need the templater
        # to lint SQL files with dbt jinja syntax.
        cmd = "sh";
        args = [
          "-c"
          "uv run --quiet sqlfluff lint --dialect postgres --format json '$FILENAME'"
        ];
      };

      lintersByFt = {
        css = [ "stylelint" ];
        dockerfile = [ "hadolint" ];
        fish = [ "fish" ];
        go = [ "golangcilint" ];
        html = [ "htmlhint" ];
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
        lua = [ "luacheck" ];
        makefile = [ "checkmake" ];
        nix = [
          "deadnix"
          "nix"
          "statix"
        ];
        python = [ "ruff" ];
        sql = [ "sqlfluff" ];
        typescript = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
      };
    };
  };
}
