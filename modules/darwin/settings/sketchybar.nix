{ pkgs, ... }:
{
  # https://felixkratz.github.io/SketchyBar/
  # Status bar replacing the macOS menu bar, showing AeroSpace workspaces.
  # Runs as a launchd user agent managed by nix-darwin. With `config` left
  # unset, the agent reads the standard ~/.config/sketchybar/sketchybarrc,
  # which home-manager symlinks from modules/home-manager/dotfiles/sketchybar.
  # AeroSpace pushes workspace changes to the bar via exec-on-workspace-change
  # in aerospace.toml.
  services.sketchybar = {
    enable = true;
    # icon_map.sh (app name -> app-font glyph, used by the front_app plugin)
    # must be on the agent's PATH, which plugin scripts inherit.
    extraPackages = [ pkgs.sketchybar-app-font ];
  };

  # The font those glyphs render in.
  fonts.packages = [ pkgs.sketchybar-app-font ];

  # Auto-hide the macOS menu bar so sketchybar owns the top edge. Hovering at
  # the top still reveals it (Stats, MeetingBar etc. stay reachable).
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
}
