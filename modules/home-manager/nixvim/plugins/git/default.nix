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
    ];
  };
}
