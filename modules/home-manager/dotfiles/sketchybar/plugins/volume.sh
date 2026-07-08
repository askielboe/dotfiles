#!/bin/bash
# Output volume. $INFO carries the new volume (0-100, 0 when muted) on
# volume_change events; on startup, ask CoreAudio via osascript.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

vol="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

# Some output devices (e.g. an external USB sound card / DAC) expose no
# software volume control, so CoreAudio reports "missing value". Show a
# greyed-out 100% rather than a bogus "missing value%".
if ! [[ "$vol" =~ ^[0-9]+$ ]]; then
  sketchybar --set "$NAME" \
    icon=󰕾 icon.color="$OVERLAY0" \
    label="100%" label.color="$OVERLAY0"
  exit 0
fi

if [ "$vol" -eq 0 ]; then
  icon=󰝟
elif [ "$vol" -lt 33 ]; then
  icon=󰕿
elif [ "$vol" -lt 66 ]; then
  icon=󰖀
else
  icon=󰕾
fi

sketchybar --set "$NAME" \
  icon="$icon" icon.color="$BLUE" \
  label="${vol}%" label.color="$TEXT"
