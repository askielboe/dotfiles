return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },
  {
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        pyright = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
    {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      table.insert(opts.sources, { name = "lazydev", group_index = 0 })
      table.insert(opts.sources, { name = "orgmode", group_index = 1 })
    end,
  },
  -- NeoTree experimental symbold support (can't figure out how to unfold, so not rellay usable)
  -- will use Outline instead.
  -- {
  --   "nvim-neo-tree/neo-tree.nvim",
  --   opts = function(_, opts)
  --     opts.sources = opts.sources or {}
  --     table.insert(opts.sources, "document_symbols")
  --
  --     opts.source_selector = opts.source_selector or {}
  --     opts.source_selector.sources = opts.source_selector.sources or {}
  --     table.insert(opts.source_selector.sources, {
  --       source = "document_symbols",
  --       display_name = " 󰘦 Symbols",
  --     })
  --   end,
  -- },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "cypher-language-server",
      },
    },
  },
}
