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

      # Split navigation, with seamless fall-through to herdr panes.
      # Move within nvim splits; if already at the edge and running inside a
      # herdr pane (HERDR_ENV=1), hand off to herdr to focus the pane in that
      # direction. herdr deliberately does NOT bind ctrl+hjkl (it has no
      # vim-aware passthrough), so nvim drives navigation and only delegates at
      # the boundary -- the vim-tmux-navigator pattern over herdr's pane CLI.
      {
        mode = "n";
        key = "<C-h>";
        action.__raw = ''
          function()
            local w = vim.api.nvim_get_current_win()
            vim.cmd.wincmd("h")
            if w == vim.api.nvim_get_current_win() and vim.env.HERDR_ENV == "1" then
              vim.fn.jobstart({ "herdr", "pane", "focus", "--direction", "left", "--current" })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Move to left split or herdr pane";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action.__raw = ''
          function()
            local w = vim.api.nvim_get_current_win()
            vim.cmd.wincmd("j")
            if w == vim.api.nvim_get_current_win() and vim.env.HERDR_ENV == "1" then
              vim.fn.jobstart({ "herdr", "pane", "focus", "--direction", "down", "--current" })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Move to below split or herdr pane";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action.__raw = ''
          function()
            local w = vim.api.nvim_get_current_win()
            vim.cmd.wincmd("k")
            if w == vim.api.nvim_get_current_win() and vim.env.HERDR_ENV == "1" then
              vim.fn.jobstart({ "herdr", "pane", "focus", "--direction", "up", "--current" })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Move to above split or herdr pane";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action.__raw = ''
          function()
            local w = vim.api.nvim_get_current_win()
            vim.cmd.wincmd("l")
            if w == vim.api.nvim_get_current_win() and vim.env.HERDR_ENV == "1" then
              vim.fn.jobstart({ "herdr", "pane", "focus", "--direction", "right", "--current" })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Move to right split or herdr pane";
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

      # Write all buffers with Ctrl+S
      {
        mode = "n";
        key = "<C-s>";
        action = "<CMD>wa<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Write all buffers";
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

      # Search and replace word under cursor in current file
      {
        mode = "n";
        key = "<leader>rw";
        action = ":%s/<C-r><C-w>//gc<Left><Left><Left>";
        options = {
          noremap = true;
          desc = "Replace word under cursor in file";
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

      # Oil
      {
        mode = "n";
        key = "<leader>o";
        action = "<CMD>Oil<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Oil: Open parent directory";
        };
      }

      # Buffer navigation
      {
        mode = "n";
        key = "<D-S-o>";
        action = "<CMD>bprevious<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Previous buffer";
        };
      }
      {
        mode = "n";
        key = "<D-S-i>";
        action = "<CMD>bnext<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Next buffer";
        };
      }
    ];
  };
}
