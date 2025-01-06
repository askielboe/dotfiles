return {
  "askielboe/statuscolumn.nvim",
  enabled = false,
  event = { "BufReadPre", "BufNewFile" },
  lazy = false,
  config = function()
    require("statuscolumn").setup({
      gradient_hl = "Special",
    })
  end,
}
