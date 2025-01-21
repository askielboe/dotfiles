return {
  "vuki656/package-info.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  keys = {
    {
      "<leader>ns",
      function()
        require("package-info").show()
      end,
      { desc = "Show dependency versions", silent = true, noremap = true },
    },
    {
      "<leader>nc",
      function()
        require("package-info").hide()
      end,
      { desc = "Hide dependency versions", silent = true, noremap = true },
    },
    {
      "<leader>nt",
      function()
        require("package-info").toggle()
      end,
      { desc = "Toggle dependency versions", silent = true, noremap = true },
    },
    {
      "<leader>nu",
      function()
        require("package-info").update()
      end,
      { desc = "Update dependency on line", silent = true, noremap = true },
    },
    {
      "<leader>nd",
      function()
        require("package-info").delete()
      end,
      { desc = "Delete dependency on line", silent = true, noremap = true },
    },
    {
      "<leader>ni",
      function()
        require("package-info").install()
      end,
      { desc = "Install new dependency", silent = true, noremap = true },
    },
    {
      "<leader>np",
      function()
        require("package-info").change_version()
      end,
      { desc = "Change dependency version", silent = true, noremap = true },
    },
  },
}
