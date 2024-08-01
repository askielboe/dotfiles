return {
  "okuuva/auto-save.nvim",
  opts = {
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = { "InsertLeave", "TextChanged" },
      cancel_defered_save = { "InsertEnter" },
    },
    debounce_delay = 5000,
    execution_message = {
      enabled = true,
    },
    noautocmd = false, -- Disables formatting on save
  },
}
