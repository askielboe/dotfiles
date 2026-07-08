# shellcheck shell=bash
# Right: clock. Sourced by ../sketchybarrc.

sketchybar --add item clock right \
  --set clock \
    icon=󰃰 \
    icon.color="$MAUVE" \
    update_freq=30 \
    script="$PLUGIN_DIR/clock.sh"
