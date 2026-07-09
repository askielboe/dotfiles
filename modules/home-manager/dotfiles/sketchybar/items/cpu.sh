# shellcheck shell=bash
# Right: cpu load percentage — passive, repainted by the stats controller
# (items/stats_controller.sh + ../plugins/stats.sh). Sourced by ../sketchybarrc.
#
# plugins/stats.sh sets the current whole-percent load as this item's label per
# system_stats event and recolours the icon red past 80% (same treatment as the
# disk item in that plugin). An icon sits to the left of the number.
sketchybar --add item cpu right \
  --set cpu \
    icon=󰻠 \
    icon.color="$PEACH"
