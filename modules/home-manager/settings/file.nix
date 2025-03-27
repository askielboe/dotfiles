{ ... }:

{
  home.file = {
    ".config/ghostty/config".source = ../dotfiles/ghostty/config;
    ".config/pueue/pueue.yml".source = ../dotfiles/pueue/pueue.yml;
    ".prettierrc".source = ../dotfiles/prettierrc;
    "rustic.toml".source = ../dotfiles/rustic/rustic.toml;
    ".config/restic/exclude-home.ini".source = ../dotfiles/restic/exclude-home.ini;
    ".config/restic/exclude-apple.ini".source = ../dotfiles/restic/exclude-apple.ini;
    ".config/restic/exclude-data.ini".source = ../dotfiles/restic/exclude-data.ini;
    ".config/restic/exclude-media.ini".source = ../dotfiles/restic/exclude-media.ini;
  };
}
