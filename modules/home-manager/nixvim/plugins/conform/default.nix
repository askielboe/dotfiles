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
        sql = [ "sqlfmt" ];
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
