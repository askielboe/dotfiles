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

      # Sort in block
      {
        mode = "n";
        key = "<leader>sib";
        action = "Vi[:sort<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Toggle diagnostics float with C-S-k
      {
        mode = "n";
        key = "<C-S-k>";
        action = "<CMD>lua vim.diagnostic.open_float()<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # Clear search highlighting with Esc and close quickfix
      {
        mode = "n";
        key = "<Esc>";
        action = "<Esc>:noh<CR>:cclose<CR>";
        options = {
          silent = true;
          desc = "Clear search highlighting and close quickfix";
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

      # Navigate to previous item in quickfix list with Shift+Alt+k
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

      # Navigate to next item in quickfix list with Shift+Alt+j
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

      # Global write and quit with Ctrl+Q (normal mode)
      {
        mode = "n";
        key = "<C-q>";
        action = "<CMD>wqa<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Write all and quit";
        };
      }

      # Global write and quit with Ctrl+Q (insert mode)
      {
        mode = "i";
        key = "<C-q>";
        action = "<Esc><CMD>wqa<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Write all and quit";
        };
      }

      # Duplicate visual selection with Ctrl+y in visual mode
      {
        mode = "x";
        key = "<C-y>";
        action = "y'>p";
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

      # Trouble diagnostics
      {
        mode = "n";
        key = "<leader>xx";
        action = "<CMD>Trouble diagnostics toggle<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Toggle diagnostics";
        };
      }

      # Mini picker visits
      {
        mode = "n";
        key = "<leader>v";
        action = "<CMD>lua require('mini.visits').select_path()<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Select visited path";
        };
      }

      # Multicursors
      {
        mode = [
          "n"
          "v"
        ];
        key = "<c-a>";
        action = "<CMD>MCstart<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Multicursors: Select word under cursor";
        };
      }
      {
        mode = "n";
        key = "<c-M-a>";
        action = "<CMD>MCpattern<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Multicursors: Select pattern";
        };
      }
      {
        mode = "v";
        key = "<c-a>";
        action = "<CMD>MCvisual<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Multicursors: Select visual selection";
        };
      }
    ];
  };
}
