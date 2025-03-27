{
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<CMD>lua Snacks.explorer()<CR>";
      options = {
        desc = "Open Explorer";
      };
    }
  ];
}
