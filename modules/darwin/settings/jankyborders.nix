_: {
  # https://github.com/FelixKratz/JankyBorders
  # Draws a colored border around the focused window. Runs as a launchd user
  # agent managed by nix-darwin.
  services.jankyborders = {
    enable = true;
    width = 5.0;
    hidpi = true;
    style = "round";
    # Catppuccin mocha: mauve for the focused window, transparent when unfocused.
    active_color = "0xffcba6f7";
    inactive_color = "0x00000000";
  };
}
