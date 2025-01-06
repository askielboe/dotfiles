return {
  -- "leath-dub/snipe.nvim",
  "linkarzu/snipe.nvim", -- add keymap to close the buffer under the cursor
  enabled = false,
  config = function()
    local snipe = require("snipe")
    snipe.setup({
      ui = { position = "center" },
    })
    vim.keymap.set("n", "gb", snipe.create_buffer_menu_toggler())
  end,
}
