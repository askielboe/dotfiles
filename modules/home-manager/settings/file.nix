{ ... }:

{
  home.file = {
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    ".prettierrc".source = ../dotfiles/prettierrc;
    ".sqlfluff".source = ../dotfiles/sqlfluff;
  };
}
