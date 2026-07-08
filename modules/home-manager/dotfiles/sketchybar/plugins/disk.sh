#!/bin/bash
# Internal SSD fill level. The APFS data volume shares free space with the
# whole container, so its capacity column tracks what Finder reports.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

pct="$(df -k /System/Volumes/Data | awk 'NR==2 {gsub(/%/, ""); print $5}')"
[ -z "$pct" ] && exit 0

color="$YELLOW"
[ "$pct" -ge 95 ] && color="$RED"

sketchybar --set "$NAME" icon.color="$color" label="${pct}%"
