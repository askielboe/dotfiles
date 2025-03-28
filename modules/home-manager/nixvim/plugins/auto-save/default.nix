{
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      trigger_events = {
        defer_save = [ ];
      };
      write_all_buffers = true;
    };
  };
}
