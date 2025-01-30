{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/nvim/lua".source = ../dotfiles/nvim/lua;
    ".config/nvim/stylua.toml".source = ../dotfiles/nvim/stylua.toml;
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    ".prettierrc".source = ../dotfiles/prettierrc;
    "rustic.toml".source = ../dotfiles/rustic/rustic.toml;
  };
}
