return {
	{
		"LazyVim/LazyVim",
		opts = {
			-- colorscheme = "catppuccin",
			colorscheme = "kanagawa",
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
			table.insert(opts.sources, { name = "supermaven", group_index = 1 })
		end,
	},
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
