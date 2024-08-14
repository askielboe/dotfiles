return {
  "okuuva/auto-save.nvim",
  opts = {
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = {},
    },
    debounce_delay = 135,
    execution_message = {
      enabled = true,
    },
    noautocmd = false, -- Disables formatting on save
  },
}
