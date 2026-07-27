{
  programs.nixvim = {
    plugins = {
      gitsigns.enable = true;
      gitblame = {
        enable = true;
        settings = {
          date_format = "%r"; # relative date
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>go";
        action = "<CMD>GitBlameOpenCommitURL<CR>";
        options = {
          desc = "Open commit URL";
        };
      }
      {
        mode = "n";
        key = "<leader>gd";
        action = "<CMD>Gitsigns diffthis main<CR>";
        options = {
          desc = "Diff file against main";
        };
      }
      {
        mode = "n";
        key = "<leader>gD";
        action = "<CMD>Gitsigns diffthis<CR>";
        options = {
          desc = "Diff file against index";
        };
      }
    ];
  };
}
