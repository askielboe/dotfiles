{
  programs.nixvim.config = {
    globals.mapleader = " ";

    keymaps = [
      # Map "-" to search function in normal mode
      {
        mode = "n";
        key = "-";
        action = "/";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Split navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options = {
          noremap = true;
          silent = true;
          desc = "Move to left split";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options = {
          noremap = true;
          silent = true;
          desc = "Move to below split";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options = {
          noremap = true;
          silent = true;
          desc = "Move to above split";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options = {
          noremap = true;
          silent = true;
          desc = "Move to right split";
        };
      }

      # Clear and replace word under cursor
      {
        mode = "n";
        key = "<C-c>";
        action = "ciw";
        options = {
          desc = "Clear and replace word under cursor";
        };
      }

      # # Navigate to previous item in quickfix list with Shift+Ctrl+k
      # {
      #   mode = "n";
      #   key = "<S-C-k>";
      #   action = "vim.cmd.cprev";
      #   options = {
      #     noremap = true;
      #     silent = true;
      #     desc = "Next Quickfix";
      #   };
      # }
      #
      # # Navigate to next item in quickfix list with Shift+Ctrl+j
      # {
      #   mode = "n";
      #   key = "<S-C-j>";
      #   action = "vim.cmd.cnext";
      #   options = {
      #     noremap = true;
      #     silent = true;
      #     desc = "Previous Quickfix";
      #   };
      # }

      # Alternative mapping: Navigate to previous item in quickfix list with Shift+Alt+k
      {
        mode = "n";
        key = "<S-M-k>";
        action = "<CMD>cprev<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Previous Quickfix";
        };
      }

      # Alternative mapping: Navigate to next item in quickfix list with Shift+Alt+j
      {
        mode = "n";
        key = "<S-M-j>";
        action = "<CMD>cnext<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Next Quickfix";
        };
      }

      # Duplicate current line with Ctrl+y in normal mode
      {
        mode = "n";
        key = "<C-y>";
        action = "<CMD>t.<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Duplicate line";
        };
      }

      # Save and quit using qq
      {
        mode = "n";
        key = "<leader>qq";
        action = "<CMD>wqa<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Write and quit";
        };
      }

      # Duplicate visual selection with Ctrl+y in visual mode
      {
        mode = "x";
        key = "<C-y>";
        action = "y'>o<Esc>p";
        options = {
          noremap = true;
          silent = true;
          desc = "Duplicate visual selection";
        };
      }

      # Delete current line with Ctrl+x in normal mode
      {
        mode = "n";
        key = "<c-x>";
        action = "dd";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Normal mode - move line down
      {
        mode = "n";
        key = "<M-j>";
        action = ":m .+1<CR>==";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Normal mode - move line up
      {
        mode = "n";
        key = "<M-k>";
        action = ":m .-2<CR>==";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Grug far
      {
        mode = "n";
        key = "<leader>sr";
        action = "<CMD>GrugFar<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
    ];
  };
}
