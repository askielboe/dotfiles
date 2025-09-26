{
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      trigger_events = {
        immediate_save = [
          "BufLeave"
          "FocusLost"
        ];
        cancel_deferred_save = [
          "InsertLeave"
        ];
      };
      write_all_buffers = true;
    };
  };
}
