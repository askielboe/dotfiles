return {
	"joshuavial/aider.nvim",
	opts = {
		default_bindings = false,
	},
	keys = function()
		return {
			{
				"<leader>ao",
				":AiderOpen --no-git<CR>",
				desc = "Aider Open",
			},
		}
	end,
}
