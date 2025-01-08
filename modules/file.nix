{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/nvim/lua".source = ../dotfiles/nvim/lua;
    "rustic.toml".source = ../dotfiles/rustic/rustic.toml;
  };
}
