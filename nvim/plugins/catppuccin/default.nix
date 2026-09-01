{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
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
        lsp_trouble = true;
        noice = true;
        snacks = true;
      };

      term_colors = true;
      transparent_background = true;
    };
  };
}
