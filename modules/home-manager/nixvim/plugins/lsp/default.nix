{ pkgs, ... }:

let
  apex-jorje-lsp = import ./apex-jorje.nix { inherit pkgs; };
in
{
  programs.nixvim.plugins = {
    lsp-format = {
      enable = true;
    };
    none-ls = {
      enable = true;
      sources.formatting.d2_fmt.enable = true;
    };
    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        apex_ls = {
          enable = true;
          package = null;
          settings = {
            apex_jar_path = "${apex-jorje-lsp}";
            apex_enable_semantic_errors = false;
            apex_enable_completion_statistics = false;
          };
        };
        bashls.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        erlangls.enable = true;
        eslint.enable = true;
        lua_ls.enable = true;
        nginx_language_server.enable = true;
        phpactor.enable = true;
        postgres_lsp.enable = true;
        pylsp = {
          enable = true;
          settings = {
            plugins.ruff.enabled = true;
          };
        };
        ruby_lsp.enable = true;
        shopify_theme_ls.enable = true;
        swift_mesonls.enable = true;
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
          "<leader>ca" = {
            action = "code_action";
            desc = "Code action";
          };
        };
      };
    };
  };
}
