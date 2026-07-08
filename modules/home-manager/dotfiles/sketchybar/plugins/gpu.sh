#!/bin/bash
# GPU utilization from the AGX driver's PerformanceStatistics dictionary
# (IOAccelerator); unlike powermetrics this needs no root.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

gpu="$(ioreg -r -d 1 -c IOAccelerator | sed -n 's/.*"Device Utilization %"=\([0-9]*\).*/\1/p' | head -1)"
[ -z "$gpu" ] && exit 0

# Mirror the cpu graph: teal trace, red past 80% (see items/stats.sh).
color="$TEAL"
fill=0x3094e2d5
if [ "$gpu" -ge 80 ]; then
  color="$RED"
  fill=0x30f38ba8
fi

# Normalise the whole-percent utilisation to the 0–1 range the graph plots.
frac="$(awk "BEGIN { printf \"%.3f\", $gpu / 100 }")"

sketchybar --set "$NAME" graph.color="$color" graph.fill_color="$fill" icon.color="$color" \
  --push "$NAME" "$frac"
