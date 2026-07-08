#!/bin/bash
# Battery temperature as an ambient-heat gauge — answers "should I move into the
# shade?". The battery is a large thermal mass that tracks the enclosure and the
# surrounding air, so it climbs with sun/ambient heat rather than with CPU load
# (which the SoC die temp tracks instead) — making it the right signal for "the
# environment is cooking the laptop", not "the chip is busy".
#
# AppleSmartBattery's "Temperature" is centi-°C and readable without root via
# ioreg — the same non-root path as gpu.sh. Hides itself on batteryless desktop
# Macs (like battery.sh).
#
# Colour tiers are keyed to Apple's thermal limits (rated ambient max 35°C;
# charging pauses as the battery warms; sustained heat degrades cell capacity):
#   green  < 35°C   A-OK, within the comfortable operating range
#   yellow 35–42°C  consider cooling down / heading for shade (charging may pause)
#   red    ≥ 43°C   not great for the hardware — move now (throttle + battery wear)

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

raw="$(ioreg -r -c AppleSmartBattery | sed -n 's/.*"Temperature" *= *\([0-9]*\).*/\1/p' | head -1)"
if [ -z "$raw" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# centi-°C (e.g. 3122) → whole °C.
deg="$(awk "BEGIN { printf \"%.0f\", $raw / 100 }")"

color="$GREEN"
if [ "$deg" -ge 43 ]; then
  color="$RED"
elif [ "$deg" -ge 35 ]; then
  color="$YELLOW"
fi

sketchybar --set "$NAME" drawing=on icon.color="$color" label="${deg}°"
