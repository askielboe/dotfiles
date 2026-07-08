#!/bin/bash
# GPU utilization from the AGX driver's PerformanceStatistics dictionary
# (IOAccelerator); unlike powermetrics this needs no root.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

gpu="$(ioreg -r -d 1 -c IOAccelerator | sed -n 's/.*"Device Utilization %"=\([0-9]*\).*/\1/p' | head -1)"
[ -z "$gpu" ] && exit 0

color="$TEAL"
[ "$gpu" -ge 80 ] && color="$RED"

sketchybar --set "$NAME" icon.color="$color" label="${gpu}%"
