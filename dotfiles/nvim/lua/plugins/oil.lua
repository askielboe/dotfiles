return {
  "stevearc/oil.nvim",
  config = function()
    require("oil").setup({
      show_hidden = true,
    })
  end,
  keys = {
    { "<leader>o", ":Oil<CR>", { desc = "Open oil" } },
    { "-", "<CMD>Oil<CR>", { desc = "Open parent directory" } },
  },
}
