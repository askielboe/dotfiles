{
  programs.nixvim.plugins.gitsigns = {
    enable = true;
  };
  programs.nixvim.plugins.gitblame = {
    enable = true;
    settings = {
      date_format = "%r"; # relative date
    };
  };
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>go";
      action = "<CMD>GitBlameOpenCommitURL<CR>";
      options = {
        desc = "Open commit URL";
      };
    }
  ];
}
