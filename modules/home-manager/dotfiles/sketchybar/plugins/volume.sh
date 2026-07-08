#!/bin/bash
# Output volume. $INFO carries the new volume (0-100, 0 when muted) on
# volume_change events; on startup, ask CoreAudio via osascript.

vol="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

if [ "$vol" -eq 0 ]; then
  icon=󰝟
elif [ "$vol" -lt 33 ]; then
  icon=󰕿
elif [ "$vol" -lt 66 ]; then
  icon=󰖀
else
  icon=󰕾
fi

sketchybar --set "$NAME" icon="$icon" label="${vol}%"
