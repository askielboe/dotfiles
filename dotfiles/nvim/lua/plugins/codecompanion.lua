return {
  "olimorris/codecompanion.nvim",
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    {
      "stevearc/dressing.nvim",
      opts = {},
    },
  },
  opts = {
    adapters = {
      anthropic = function()
        return require("codecompanion.adapters").extend("anthropic", {
          env = {
            api_key = "***REMOVED-SECRET***",
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "anthropic",
      },
      inline = {
        adapter = "anthropic",
      },
      agent = {
        adapter = "anthropic",
      },
    },
  },
  keys = {
    { "<leader>a", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "Code Companion" },
  },
  config = true,
}
