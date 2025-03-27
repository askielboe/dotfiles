{
  programs.nixvim.plugins.mini = {
    enable = true;
    mockDevIcons = true;
    modules.icons = { };
  };

  imports = [
    ./ai.nix
    ./diff.nix
  ];
}
