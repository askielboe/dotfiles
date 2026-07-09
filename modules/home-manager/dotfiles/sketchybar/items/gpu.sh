# shellcheck shell=bash
# Right: gpu utilisation percentage. Sourced by ../sketchybarrc.
#
# The stats provider has no GPU stat; this item self-polls ioreg on its own timer
# via ../plugins/gpu.sh (unlike the cpu item, which the stats controller feeds).
# Same treatment as the cpu item (items/cpu.sh): icon to the left of the number;
# gpu.sh sets each utilisation reading as this item's label.
sketchybar --add item gpu right \
  --set gpu \
    icon=󰢮 \
    icon.color="$TEAL" \
    update_freq=5 \
    script="$PLUGIN_DIR/gpu.sh"
