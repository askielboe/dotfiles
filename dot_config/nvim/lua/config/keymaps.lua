-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Key remaps
map({ "n" }, "-", "/", { noremap = true, silent = true })
map({ "n", "v", "s" }, "æ", "0", { noremap = true, silent = true })
map({ "n", "v", "s" }, "ø", "$", { noremap = true, silent = true })

-- Uppercase navigation
map("n", "∑", "/\\u\\C<CR>", { noremap = true, silent = true })
map("n", "∫", "?\\u\\C<CR>", { noremap = true, silent = true })

-- Duplicate line
map("n", "<C-y>", ":t.<CR>", { noremap = true, silent = true })
-- Duplicate visual selection
map("x", "<C-y>", "<S-v>y`>p", { noremap = true, silent = true })
-- Delete line
map("n", "<c-x>", "dd", { noremap = true, silent = true })
-- Move line up
map("n", "<C-S-k>", ":m .-2<CR>==", { noremap = true, silent = true })
-- Move line down
map("n", "<C-S-j>", ":m .+1<CR>==", { noremap = true, silent = true })
-- Move visual selection up
map("v", "<C-S-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
-- Move visual selection down
map("v", "<C-S-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
-- Replace word under cursor (case preserving)
map("n", "<leader>r", ":%S/<C-r><C-w>//g<Left><Left>", { noremap = true, desc = "Replace word under cursor globally" })
