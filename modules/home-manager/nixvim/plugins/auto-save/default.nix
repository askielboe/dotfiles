{
  programs.nixvim.plugins.auto-save = {
    enable = true;
    settings = {
      immediate_save = [
        "BufLeave"
        "FocusLost"
      ];
      debounce_delay = 135;
    };
  };
}
