{ pkgs, ... }:
{
  programs.nixvim.extraPackages = with pkgs; [
    black
    fixjson
    nixfmt-rfc-style
    prettierd
    shfmt
    stylua
    swiftformat
    yamlfmt
  ];
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    lazyLoad.settings = {
      cmd = [ "ConformInfo" ];
      event = [ "BufWrite" ];
    };

    settings = {
      default_format_opts = {
        lsp_format = "fallback";
      };

      format_on_save = {
        timeout_ms = 500;
      };

      formatters_by_ft = {
        python = [ "black" ];
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
