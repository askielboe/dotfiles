return {
  "askielboe/statuscolumn.nvim",
  event = { "BufReadPre", "BufNewFile" },
  enabled = false,
  lazy = false,
  config = function()
    require("statuscolumn").setup({
      gradient_hl = "Special",
    })
  end,
}
