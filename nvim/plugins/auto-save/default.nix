{
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      trigger_events = {
        immediate_save = [
          "BufLeave"
          "FocusLost"
        ];
        # Put events here to override plugin defaults (which include InsertLeave)
        defer_save = [
          "FocusLost"
        ];
      };
      debounce_delay = 1000;
      write_all_buffers = true;
      # Ensure autocommands fire so BufWritePre triggers formatting
      noautocmd = false;
    };
  };
}
