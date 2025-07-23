{
  programs.nixvim = {
    enable = true;
  };
  imports = [
    ../../home-manager/nixvim/autocmd.nix
    ../../home-manager/nixvim/filetypes.nix
    ../../home-manager/nixvim/keys.nix
    ../../home-manager/nixvim/plugins
    ../../home-manager/nixvim/sets.nix
  ];
}