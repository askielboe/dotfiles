#!/bin/bash
# Battery percentage with a level-tinted icon; hides itself on desktop Macs.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

batt="$(pmset -g batt)"
case "$batt" in
*InternalBattery*) ;;
*)
  sketchybar --set "$NAME" drawing=off
  exit 0
  ;;
esac

pct="$(printf '%s' "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$pct" ] && exit 0

color="$GREEN"
if [ "$pct" -le 20 ]; then
  color="$RED"
elif [ "$pct" -le 40 ]; then
  color="$PEACH"
fi

case "$batt" in
*'AC Power'*) icon=󰂄 color="$YELLOW" ;;
*)
  if [ "$pct" -ge 90 ]; then
    icon=󰁹
  elif [ "$pct" -ge 70 ]; then
    icon=󰂁
  elif [ "$pct" -ge 50 ]; then
    icon=󰁾
  elif [ "$pct" -ge 30 ]; then
    icon=󰁼
  else
    icon=󰁺
  fi
  ;;
esac

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$color" label="${pct}%"
