# shellcheck shell=bash
# Left: the focused application (glyph + bold name). Sourced by ../sketchybarrc.

sketchybar --add item front_app left \
  --set front_app \
    icon.font="sketchybar-app-font:Regular:15.0" \
    label.font="Hack Nerd Font:Bold:13.0" \
    script="$PLUGIN_DIR/front_app.sh" \
  --subscribe front_app front_app_switched
