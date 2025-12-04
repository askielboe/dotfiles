{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    lazyLoad.settings = {
      cmd = [ "ConformInfo" ];
      event = [
        "BufWrite"
        "User AutoSaveWritePre"
      ];
    };

    settings = {
      default_format_opts = {
        lsp_format = "fallback";
      };

      format_after_save = {
        async = true;
        on_enter = false;
      };

      formatters.sqlfluff = {
        # Use project-local sqlfluff via uv because sqlfluff-templater-dbt
        # is not available in nixpkgs. Projects using dbt need the templater
        # to format SQL files with dbt jinja syntax.
        command = "sh";
        args = [
          "-c"
          "uv run --quiet sqlfluff format --dialect postgres -"
        ];
      };

      formatters_by_ft = {
        python = [
          "ruff_format"
          "ruff_organize_imports"
        ];
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        markdown = [ "prettierd" ];
        yaml = [ "yamlfmt" ];
        bash = [ "shfmt" ];
        javascript = [ "prettierd" ];
        javascriptreact = [ "prettierd" ];
        typescript = [ "prettierd" ];
        typescriptreact = [ "prettierd" ];
        vue = [ "prettierd" ];
        css = [ "prettierd" ];
        scss = [ "prettierd" ];
        sql = [ "sqlfluff" ];
        swift = [ "swiftformat" ];
        html = [ "prettierd" ];
        less = [ "prettierd" ];
        jsonc = [ "prettierd" ];
        json = [
          "fixjson"
          "prettierd"
        ];
      };
    };
  };
}
