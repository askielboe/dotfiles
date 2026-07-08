#!/bin/bash
# CPU usage (user + system). iostat's first line is the since-boot average,
# so take a second 1-second sample; -n0 suppresses the disk columns.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

cpu="$(iostat -n0 -w1 -c2 | tail -1 | awk '{printf "%.0f", $1 + $2}')"
[ -z "$cpu" ] && exit 0

color="$PEACH"
[ "$cpu" -ge 80 ] && color="$RED"

sketchybar --set "$NAME" icon.color="$color" label="${cpu}%"
