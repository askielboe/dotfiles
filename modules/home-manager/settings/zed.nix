{ ... }:
{
  # Zed editor configuration, managed declaratively via home-manager.
  #
  # Zed itself is installed via the Homebrew cask (modules/darwin/settings/homebrew.nix),
  # so `package = null` makes home-manager manage ONLY the config files and not install
  # the Nix build of Zed (GUI apps go via brew on macOS — Nix store symlinks aren't
  # Spotlight/Launchpad-indexed). Files are written under ~/.config/zed/.
  #
  # NOTE: the `theme` key is intentionally NOT set here. catppuccin.zed (on by default
  # via the global catppuccin.enable in default.nix) owns the theme and pins it to
  # Catppuccin Mocha — always, regardless of macOS light/dark appearance.
  programs.zed-editor = {
    enable = true;
    package = null;

    # settings.json keeps the default mutableUserSettings = true: Zed writes to it at
    # runtime (font-size bumps, UI toggles) and home-manager merges our declared keys
    # on top (nix wins on conflicts, Zed-only keys are preserved).
    #
    # keymap.json, by contrast, is never written by Zed itself, so manage it as a
    # purely-declarative read-only store symlink.
    mutableUserKeymaps = false;

    userSettings = {
      vim_mode = true;

      project_panel.dock = "left";
      outline_panel.dock = "left";
      collaboration_panel.dock = "left";
      git_panel.dock = "left";

      agent = {
        dock = "right";
        always_allow_tool_actions = true;
        version = "2";
        inline_assistant_model = {
          provider = "anthropic";
          model = "claude-sonnet-4-latest";
        };
        default_model = {
          provider = "anthropic";
          model = "claude-sonnet-4-latest";
        };
      };

      ui_font_size = 16;
      ui_font_family = "Hack Nerd Font Mono";
      buffer_font_size = 15;
      buffer_font_weight = 500;
      buffer_line_height = "standard";
      buffer_font_family = "Hack Nerd Font Mono";

      gutter.folds = false;
      tabs.git_status = true;
      autosave = "on_focus_change";
    };

    # nvim-style: option+j/k move the current line (normal) or selection (visual) up
    # and down. Zed's vim mode has no default for this — `gj`/`gk` are display-line
    # *motions*, not line moves — so it's a genuine gap worth binding.
    #
    # Most other nvim verbs are already built into Zed's vim mode and need no config:
    # case toggle `~`, the `gu`/`gU`/`g~` case operators, motions, text objects,
    # marks, macros and registers all work out of the box.
    userKeymaps = [
      {
        context = "Editor && vim_mode == normal";
        bindings = {
          "alt-j" = "editor::MoveLineDown";
          "alt-k" = "editor::MoveLineUp";
        };
      }
      {
        context = "Editor && vim_mode == visual";
        bindings = {
          "alt-j" = "editor::MoveLineDown";
          "alt-k" = "editor::MoveLineUp";
        };
      }
    ];
  };
}
