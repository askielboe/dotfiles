#!/bin/bash
# Shows the focused application with its sketchybar-app-font glyph.
# $INFO carries the app name on front_app_switched events.

[ -z "$INFO" ] && exit 0

# icon_map.sh comes from pkgs.sketchybar-app-font (services.sketchybar.extraPackages
# puts it on the agent's PATH). It defines __icon_map, which sets $icon_result.
icon=":default:"
map="$(command -v icon_map.sh)"
if [ -n "$map" ]; then
  # shellcheck disable=SC1090 # resolved from PATH at runtime
  source "$map"
  __icon_map "$INFO"
  # shellcheck disable=SC2154 # icon_result is set by __icon_map
  icon="$icon_result"
fi

sketchybar --set "$NAME" icon="$icon" label="$INFO"
