return {
  "stevearc/oil.nvim",
  config = function()
    require("oil").setup({
      view_options = {
        show_hidden = true,
      },
    })
  end,
  keys = {
    { "<leader>o", ":Oil<CR>", { desc = "Open oil" } },
    { "-", "<CMD>Oil<CR>", { desc = "Open parent directory" } },
  },
}
