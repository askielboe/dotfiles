return {
  "joshuavial/aider.nvim",
  opts = {
    default_bindings = false,
  },
  keys = function()
    return {
      {
        "<leader>ao",
        ":AiderOpen<CR>",
        desc = "Aider Open",
      },
      {
        "<leader>aO",
        ":AiderOpen --no-git<CR>",
        desc = "Aider Open No Git",
      },
    }
  end,
}
