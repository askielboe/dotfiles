# shellcheck shell=bash
# Right: disk usage — passive, repainted by the stats controller
# (items/stats_controller.sh + ../plugins/stats.sh). Sourced by ../sketchybarrc.

sketchybar --add item disk right \
  --set disk \
    icon=󰋊 \
    icon.color="$YELLOW"
