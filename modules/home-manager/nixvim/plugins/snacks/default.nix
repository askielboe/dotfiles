{
  programs.nixvim.plugins.snacks = {
    enable = true;
    settings = {
      picker = {
        hidden = true; # Show dotfiles in explorer
        sources.files.hidden = true; # Show dotfiles in picker
      };
    };
  };
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<CMD>lua Snacks.explorer()<CR>";
      options = {
        desc = "Open Explorer";
      };
    }
    {
      mode = "n";
      key = "<leader>gg";
      action = "<CMD>lua Snacks.lazygit.open()<CR>";
      options = {
        desc = "Open LazyGit";
      };
    }
    {
      mode = "n";
      key = "<leader><leader>";
      action = "<CMD>lua Snacks.picker.files()<CR>";
      options = {
        desc = "Open Files";
      };
    }
    {
      mode = "n";
      key = "<leader>-";
      action = "<CMD>lua Snacks.picker.grep()<CR>";
      options = {
        desc = "Open Grep";
      };
    }
    {
      mode = "n";
      key = "<leader><";
      action = "<CMD>lua Snacks.picker.resume()<CR>";
      options = {
        desc = "Open Resume";
      };
    }
    {
      mode = "n";
      key = "<leader>r";
      action = "<CMD>lua Snacks.picker.recent()<CR>";
      options = {
        desc = "Open Recent";
      };
    }
  ];
}
