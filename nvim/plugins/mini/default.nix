{
  imports = [
    ./ai.nix
    ./starter.nix
    ./surround.nix
  ];

  plugins.mini = {
    enable = true;
    mockDevIcons = true;
    modules = {
      icons = { };
      indentscope = {
        symbol = "│";
      };
      jump = { };
      move = { };
      pairs = { };
      pick = { };
      trailspace = { };
      visits = { };
    };
  };
}
