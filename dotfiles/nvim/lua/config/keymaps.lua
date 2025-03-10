-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Key remaps
map({ "n" }, "-", "/", { noremap = true, silent = true })
map({ "n", "v", "s" }, "æ", "0", { noremap = true, silent = true })
map({ "n", "v", "s" }, "ø", "$", { noremap = true, silent = true })

-- Sorting
map({ "n" }, "<leader>bs", ":normal! viB<CR>:sort<CR>", { noremap = true, silent = true })

-- Quit
map({ "n" }, "qq", ":wqa<CR>", { noremap = true, silent = true })

-- Git browse permalink
map({ "n", "x" }, "<leader>gP", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg(
        "+",
        url:match("github%.com/%w+/(.+)") -- Rmove the github.com/username/ part
      )
    end,
    what = "permalink",
    notify = false,
  })
end, { desc = "Git Browse (copy)" })

-- Quickfix
map("n", "<S-C-k>", vim.cmd.cprev, { noremap = true, silent = true, desc = "Next Quickfix" })
map("n", "<S-C-j>", vim.cmd.cnext, { noremap = true, silent = true, desc = "Previous Quickfix" })

map("n", "<S-M-k>", vim.cmd.cprev, { noremap = true, silent = true, desc = "Next Quickfix" })
map("n", "<S-M-j>", vim.cmd.cnext, { noremap = true, silent = true, desc = "Previous Quickfix" })

-- Toggle whitespace characters
map("n", "<leader>tw", ":set list!<CR>", { desc = "Toggle whitespace characters" })

-- Timewarrior tracking
map("n", "<leader>tws", ":!timew start<CR>", { desc = "Start timewarrior tracking" })
map("n", "<leader>twx", ":!timew stop<CR>", { desc = "Stop timewarrior tracking" })
map("n", "<leader>twc", ":!timew continue<CR>", { desc = "Continue timewarrior tracking" })

-- Uppercase navigation
map("n", "<M-w>", "/\\u\\C<CR>", { noremap = true, silent = true, desc = "Camel case forward" })
map("n", "<M-b>", "?\\u\\C<CR>", { noremap = true, silent = true, desc = "Camel case backward" })

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

-- Git
map("n", "gp", ":Git pull<CR>", { noremap = true, silent = true, desc = "Git pull" })

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
