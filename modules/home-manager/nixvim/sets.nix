{
  programs.nixvim.config = {
    performance = {
      byteCompileLua = {
        enable = true;
        nvimRuntime = true;
        configs = true;
        plugins = true;
      };
    };

    # Share clipboard with system
    clipboard = {
      register = "unnamedplus";
    };

    diagnostic = {
      settings = {
        virtual_text = true;
      };
    };

    opts = {
      number = true;

      # Set tabs to 2 spaces
      tabstop = 2;
      softtabstop = 2;
      showtabline = 0;
      expandtab = true;

      # Enable auto indenting and set it to spaces
      smartindent = true;
      shiftwidth = 2;

      # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
      breakindent = true;

      # Enable ignorecase + smartcase for better searching
      ignorecase = true;
      smartcase = true; # Don't ignore case with capitals

      # Enable persistent undo history
      swapfile = false;
      autoread = true;
      backup = false;
      undofile = true;

      # Enable cursor line highlight
      cursorline = true; # Highlight the line where the cursor is located

      # Scrolling behavior - maintain context when navigating
      scrolloff = 8; # Keep 8 lines above/below cursor for context
      sidescrolloff = 8; # Keep 8 columns left/right of cursor for context

      # Set encoding type
      encoding = "utf-8";
      fileencoding = "utf-8";
    };
  };
}
