{ pkgs, ... }:
{
  programs.nixvim.extraPackages = with pkgs; [
    black
    fixjson
    nixfmt-rfc-style
    prettierd
    shfmt
    stylua
    yamlfmt
  ];
  programs.nixvim.plugins.conform-nvim = {
    enable = true;

    lazyLoad.settings = {
      cmd = [
        "ConformInfo"
      ];
      event = [ "BufWrite" ];
    };

    settings = {
      format_on_save = {
        lspFallback = true;
        timeoutMs = 500;
      };
      notify_on_error = true;

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
