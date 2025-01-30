{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/nvim/stylua.toml".source = ../dotfiles/nvim/stylua.toml;
    ".config/nvim/lua".source = ../dotfiles/nvim/lua;
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    "rustic.toml".source = ../dotfiles/rustic/rustic.toml;
    ".prettierrc".source = ../dotfiles/prettierrc;
  };
}
