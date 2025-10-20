{
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      trigger_events = {
        immediate_save = [
          "FocusLost"
        ];
        defer_save = [
          "InsertLeave"
        ];
      };
      debounce_delay = 1000;
      write_all_buffers = true;
    };
  };
}
