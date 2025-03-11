return {
  "f-person/git-blame.nvim",
  config = function()
    vim.g.gitblame_message_template = "    \u{e0a0} <author>, <date>, <summary>"
    vim.g.gitblame_date_format = "%r" -- relative date
    vim.keymap.set("n", "<leader>tb", ":GitBlameToggle<CR>", { desc = "Toggle GitBlame" })
    vim.keymap.set("n", "<leader>go", ":GitBlameOpenCommitURL<CR>", { desc = "Open commit URL" })
  end,
}
