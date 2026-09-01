{ pkgs, ... }:

{
  plugins = {
    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        bashls.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        eslint.enable = true;
        jinja_lsp = {
          enable = true;
          package = pkgs.jinja-lsp;
        };
        lua_ls.enable = true;
        nginx_language_server.enable = true;
        phpactor.enable = true;
        ty = {
          enable = true;
          settings = {
            inlayHints = {
              variableTypes = false;
            };
          };
        };
        ruby_lsp.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        shopify_theme_ls.enable = true;
        # Swift LSP toolchain lives on macOS only.
        swift_mesonls.enable = pkgs.stdenv.isDarwin;
        tflint.enable = true;
        ts_ls.enable = true;
        yamlls = {
          enable = true;
          settings = {
            yaml = {
              schemas = {
                "https://raw.githubusercontent.com/lightdash/lightdash/main/packages/common/src/schemas/json/lightdash-dbt-2.0.json" =
                  [
                    "**/models/**/*.yml"
                    "**/models/**/*.yaml"
                  ];
                "https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/latest/dbt_project-latest.json" =
                  [
                    "dbt_project.yml"
                  ];
                "https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/latest/packages-latest.json" =
                  [
                    "packages.yml"
                  ];
              };
            };
          };
        };
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
