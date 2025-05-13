{
  programs.nixvim = {
    enable = true;
  };
  imports = [
    ./autocmd.nix
    ./filetypes.nix
    ./keys.nix
    ./plugins
    ./sets.nix
  ];
}
