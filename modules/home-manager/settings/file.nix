{ ... }:

{
  home.file = {
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    ".config/worktrunk/config.toml".source = ../dotfiles/worktrunk/config.toml;
    ".prettierrc".source = ../dotfiles/prettierrc;
    ".sqlfluff".source = ../dotfiles/sqlfluff;
  };
}
