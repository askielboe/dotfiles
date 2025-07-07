{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    ".prettierrc".source = ../dotfiles/prettierrc;
  };
}
