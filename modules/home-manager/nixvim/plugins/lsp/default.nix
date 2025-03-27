{
  programs.nixvim.plugins = {
    lsp-format = { enable = true; };
    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        bashls.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        erlangls.enable = true;
        eslint.enable = true;
        lua_ls.enable = true;
        nginx_language_server.enable = true;
        postgres_lsp.enable = true;
        pyright.enable = true;
        ruby_lsp.enable = true;
        shopify_theme_ls.enable = true;
        tflint.enable = true;
        ts_ls.enable = true;
        yamlls.enable = true;
      };
      keymaps = {
        silent = true;
        lspBuf = {
          gd = {
            action = "definition";
            desc = "Goto Definition";
          };
          gr = {
            action = "references";
            desc = "Goto References";
          };
          gD = {
            action = "declaration";
            desc = "Goto Declaration";
          };
          gI = {
            action = "implementation";
            desc = "Goto Implementation";
          };
          gT = {
            action = "type_definition";
            desc = "Type Definition";
          };
          "<leader>cr" = {
            action = "rename";
            desc = "Rename";
          };
        };
      };
    };
  };
}
