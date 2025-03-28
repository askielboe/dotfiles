{
  programs.nixvim = {
    enable = true;
  };
  imports = [
    ./plugins
    ./autocmd.nix
    ./keys.nix
    ./sets.nix
  ];
}
