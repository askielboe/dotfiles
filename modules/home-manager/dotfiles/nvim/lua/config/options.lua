-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Avoid changing root in monorepos
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

-- No backups
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- List chars
vim.opt.list = false
vim.opt.listchars = { eol = "↲", space = "·", tab = "▸ " }

-- Cursorline
vim.opt.cursorline = true

-- Disable scroll animation
vim.g.snacks_animate_scroll = false
