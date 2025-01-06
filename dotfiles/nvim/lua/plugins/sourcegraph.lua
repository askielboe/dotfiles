return {
  {
    "sourcegraph/sg.nvim",
    enabled = false,
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    keys = { { "<leader>sg", ":Telescope sourcegraph", desc = "Sourcegraph" } },
    config = function()
      require("sg").setup({})
    end,
  },
}
