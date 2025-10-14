{
  programs.nixvim.plugins = {
    lint = {
      enable = true;

      lazyLoad.settings.event = "DeferredUIEnter";

      lintersByFt = {
        css = [ "stylelint" ];
        dockerfile = [ "hadolint" ];
        fish = [ "fish" ];
        go = [ "golangcilint" ];
        html = [ "htmlhint" ];
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
        json = [ "jsonlint" ];
        lua = [ "luacheck" ];
        makefile = [ "checkmake" ];
        nix = [
          "deadnix"
          "nix"
          "statix"
        ];
        python = [ "ruff" ];
        typescript = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
      };
    };
  };
}
