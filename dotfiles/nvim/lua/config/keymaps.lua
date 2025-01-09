-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Key remaps
map({ "n" }, "-", "/", { noremap = true, silent = true })
map({ "n", "v", "s" }, "æ", "0", { noremap = true, silent = true })
map({ "n", "v", "s" }, "ø", "$", { noremap = true, silent = true })

-- Quickfix
map("n", "<S-C-k>", vim.cmd.cprev, { noremap = true, silent = true, desc = "Next Quickfix" })
map("n", "<S-C-j>", vim.cmd.cnext, { noremap = true, silent = true, desc = "Previous Quickfix" })

-- Toggle whitespace characters
map("n", "<leader>tw", ":set list!<CR>", { desc = "Toggle whitespace characters" })

-- Uppercase navigation
map("n", "∑", "/\\u\\C<CR>", { noremap = true, silent = true })
map("n", "∫", "?\\u\\C<CR>", { noremap = true, silent = true })

-- Window resize
map("n", "<C-<Right>>", ":res +1<CR>", { noremap = true, silent = true })
map("n", "<C-<Left>>", ":res -1<CR>", { noremap = true, silent = true })
map("n", "<C-<Up>>", ":vertical res +1<CR>", { noremap = true, silent = true })
map("n", "<C-<Down>>", ":vertical res -1<CR>", { noremap = true, silent = true })

-- Duplicate line
map("n", "<C-y>", ":t.<CR>", { noremap = true, silent = true, desc = "Duplicate line" })
-- Duplicate visual selection
map("x", "<C-y>", "y'>o<Esc>p", { noremap = true, silent = true, desc = "Duplicate visual selection" })
-- Delete line
map("n", "<c-x>", "dd", { noremap = true, silent = true })
-- Replace word under cursor (case preserving)
map("n", "<leader>r", ":%S/<C-r><C-w>//g<Left><Left>", { noremap = true, desc = "Replace word under cursor globally" })

-- Fzf
map("n", "<leader><", LazyVim.pick("resume"), { desc = "Resume" })
map("n", "<leader>-", LazyVim.pick("live_grep", { root = false }), { desc = "Grep (cwd)" })

-- Toggle between start of line and first non-blank character
vim.keymap.set("n", "0", function()
  local col = vim.fn.col(".")
  local first_non_blank = vim.fn.match(vim.fn.getline("."), "\\S") + 1
  return (col == first_non_blank and "0" or "^")
end, { expr = true, desc = "Toggle between start of line and first non-blank character" })

-- Search replace word under cursor in current file
vim.keymap.set({ "n", "v" }, "<leader>rw", function()
  require("grug-far").open({
    transient = true,
    startCursorRow = 3,
    prefills = {
      search = vim.fn.expand("<cword>"),
      replacement = vim.fn.expand("<cword>"),
      paths = vim.fn.expand("%"),
    },
  })
end, { noremap = true, desc = "Search replace word under cursor in current file" })
