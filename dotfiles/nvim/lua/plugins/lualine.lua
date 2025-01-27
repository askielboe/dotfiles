return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    -- Cache for TimeWarrior results
    local timew_cache = {
      result = "",
      last_check = 0,
    }

    -- Get the current TimeWarrior tracking info
    local function get_timew()
      local current_time = os.time()
      -- Only update every 30 seconds
      if current_time - timew_cache.last_check < 1 then
        return timew_cache.result
      end

      local handle = io.popen("timew")
      if handle == nil then
        -- vim.notify("TimeWarrior: Failed to open handle", vim.log.levels.ERROR)
        return ""
      end
      local result = handle:read("*a")
      handle:close()

      -- Debug output
      -- vim.notify("TimeWarrior raw output: " .. result, vim.log.levels.DEBUG)

      -- If tracking something
      if result:match("Tracking") then
        -- Extract project name and duration
        local project = result:match("Tracking%s+([^\n]+)")
        local duration = result:match("Total%s+([^\n]+)")

        -- vim.notify("TimeWarrior matched project: " .. (project or "nil"), vim.log.levels.DEBUG)
        -- vim.notify("TimeWarrior matched duration: " .. (duration or "nil"), vim.log.levels.DEBUG)

        if project and duration then
          timew_cache.result = string.format("%s (%s)", project, duration)
        else
          timew_cache.result = ""
        end
      else
        timew_cache.result = ""
      end
      timew_cache.last_check = current_time
      return timew_cache.result
    end

    return {
      options = {
        theme = "auto",
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = " ",
              warn = " ",
              info = " ",
              hint = " ",
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
        },
        lualine_x = {
          -- TimeWarrior component
          {
            get_timew,
            color = { fg = "#ff9e64" },
          },
          -- Rest of the default components
          { "encoding" },
          { "fileformat" },
          {
            "diff",
            symbols = {
              added = " ",
              modified = " ",
              removed = " ",
            },
          },
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = {
          function()
            return " " .. os.date("%R")
          end,
        },
      },
    }
  end,
}
