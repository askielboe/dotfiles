return {
  "ibhagwan/fzf-lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader><", LazyVim.pick("resume"), desc = "Resume" },
    { "<leader>-", "<cmd>FzfLua live_grep<cr><C-g>", { desc = "Fzf Live Grep Fuzzy" } },
  },
  config = function()
    require("fzf-lua").setup({
      "telescope",
      files = {
        header = false,
      },
      grep = {
        header = false,
      },
    })
  end,
}
