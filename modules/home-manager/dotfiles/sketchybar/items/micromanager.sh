# shellcheck shell=bash
# Focus HUD: Cold Turkey Micromanager focus-block timer + allowlisted-app glyphs.
# Sourced by ../sketchybarrc, right after pomodoro. Position "q" is sketchybar's
# native "left of the notch" slot, so the HUD clears the notch on the built-in
# display and collapses toward centre elsewhere (see pomodoro.sh / ../sketchybarrc).
# Hidden unless a block is active. State comes from the app's prefs plist (not
# nix-managed, no CLI/events)
# read via `defaults read com.getcoldturkey.micromanager-pro` — see
# plugins/micromanager.sh.
#
# Layout: an anchor item (shield icon + remaining-time label) followed by a
# fixed pool of app-font glyph slots. Only the anchor runs the plugin; it
# repaints the whole group in one chained --set (like the stats controller).
# The anchor polls every 5s while idle to notice a block starting, then the
# plugin bumps itself to 1s for a smooth countdown.

sketchybar --add item micromanager q \
  --set micromanager \
    icon=󰒃 \
    icon.color="$MAUVE" \
    label.font="Hack Nerd Font:Bold:13.0" \
    drawing=off \
    update_freq=5 \
    script="$PLUGIN_DIR/micromanager.sh" \
    click_script="open -b com.getcoldturkey.micromanager-pro"

# Glyph pool: the plugin fills the first N slots from the allowlist and hides
# the rest, re-reading the whitelist each tick so edits show up live.
for i in 1 2 3 4 5 6; do
  sketchybar --add item "micromanager.app.$i" q \
    --set "micromanager.app.$i" \
      icon.font="sketchybar-app-font:Regular:14.0" \
      icon.color="$TEXT" \
      icon.padding_left=3 \
      icon.padding_right=3 \
      label.drawing=off \
      drawing=off
done
