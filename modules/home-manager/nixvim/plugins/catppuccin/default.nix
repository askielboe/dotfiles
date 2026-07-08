{
  programs.nixvim.colorschemes.catppuccin = {
    enable = true;
    settings = {
      default_integrations = true;
      dim_inactive = {
        enabled = false;
        percentage = 0.25;
      };

      flavour = "mocha";

      # Delta-style diff rendering: faint red/green line tints, saturated
      # word-level highlights, dim filler — instead of the stock blue-on-blue
      # with underlines.
      custom_highlights = {
        __raw = ''
          function(colors)
            local u = require("catppuccin.utils.colors")
            return {
              DiffAdd = { bg = u.darken(colors.green, 0.18, colors.base) },
              DiffDelete = { fg = colors.surface0, bg = u.darken(colors.red, 0.10, colors.base) },
              DiffChange = { bg = u.darken(colors.blue, 0.10, colors.base) },
              DiffText = { bg = u.darken(colors.blue, 0.40, colors.base), style = {} },
              DiffTextAdd = { bg = u.darken(colors.green, 0.40, colors.base), style = {} },
            }
          end
        '';
      };

      integrations = {
        aerial = true;
        blink_cmp = true;
        dap = {
          enabled = true;
          enable_ui = true;
        };
        indent_blankline = {
          enabled = true;
          colored_indent_levels = true;
        };
        lsp_trouble = true;
        markdown = true;
        mason = true;
        mini.enabled = true;

        native_lsp = {
          enabled = true;
          virtual_text = {
            errors = [ "italic" ];
            hints = [ "italic" ];
            warnings = [ "italic" ];
            information = [ "italic" ];
          };
          underlines = {
            errors = [ "underline" ];
            hints = [ "underline" ];
            warnings = [ "underline" ];
            information = [ "underline" ];
          };
          inlay_hints = {
            background = true;
          };
        };
        noice = true;
        notify = true;
        symbols_outline = true;
        snacks = true;
        treesitter = true;
      };

      show_end_of_buffer = true;
      term_colors = true;
      transparent_background = true;
    };
  };
}
