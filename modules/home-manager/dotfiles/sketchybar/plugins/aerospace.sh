#!/bin/bash
# Repaints the single workspace pill: the focused AeroSpace workspace id (icon)
# plus the focused app's glyph (label, sketchybar-app-font). Runs on workspace
# switch (aerospace_workspace_change, which carries FOCUSED_WORKSPACE from the
# AeroSpace exec-on-workspace-change callback) and on app switch
# (front_app_switched, which carries the app name in $INFO). On either event the
# half not supplied by the event env is queried from aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

ws="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
app="${INFO:-$("$AEROSPACE" list-windows --focused --format '%{app-name}')}"

# Map the app name to a glyph. icon_map.sh comes from pkgs.sketchybar-app-font
# (services.sketchybar.extraPackages puts it on the agent PATH); it defines
# __icon_map, an in-shell function that sets $icon_result (no subprocess). Empty
# glyph when no app is focused (e.g. an empty workspace).
glyph=""
if [ -n "$app" ]; then
  glyph=":default:"
  map="$(command -v icon_map.sh)"
  if [ -n "$map" ]; then
    # shellcheck disable=SC1090 # resolved from PATH at runtime
    source "$map"
    __icon_map "$app"
    # shellcheck disable=SC2154 # icon_result is set by __icon_map
    glyph="$icon_result"
  fi
fi

sketchybar --set space icon="$ws" label="$glyph"
