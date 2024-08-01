local telescopeConfig = require("telescope.config")

-- Clone the default Telescope configuration
local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

-- I want to search in hidden/dot files.
table.insert(vimgrep_arguments, "--hidden")
-- I don't want to search in the `.git` directory.
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/.git/*")
-- Don't search in the `node_modules` directory
table.insert(vimgrep_arguments, "--glob")
table.insert(vimgrep_arguments, "!**/node_modules/*")

return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>-", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader><", LazyVim.pick("resume"), desc = "Resume" },
  },
  opts = {
    defaults = {
      -- `hidden = true` is not supported in text grep commands.
      vimgrep_arguments = vimgrep_arguments,
    },
    pickers = {
      find_files = {
        -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
        find_command = {
          "rg",
          "--files",
          "--hidden",
          "--glob",
          "!**/.git/*",
          "--glob",
          "!**/node_modules/*",
          "--no-ignore",
        },
      },
    },
  },
}
