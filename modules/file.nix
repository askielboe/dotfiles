{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/nvim/stylua.toml".source = ../dotfiles/nvim/stylua.toml;
    ".config/nvim/lua".source = ../dotfiles/nvim/lua;
    "rustic.toml".source = ../dotfiles/rustic/rustic.toml;
  };
}
