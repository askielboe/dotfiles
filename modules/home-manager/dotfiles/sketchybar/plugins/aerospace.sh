#!/bin/bash
# Repaints the workspace items in a single sketchybar call. Each space.<ws> shows
# its id (icon) plus a glyph per app in it (label, sketchybar-app-font) — like the
# SketchyBar example. The focused one gets a mauve pill with dark text, other
# non-empty ones a subtle surface pill, and empty ones are hidden (there are ~30
# persistent workspaces). FOCUSED_WORKSPACE is set by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

# All windows once, as "workspace|app-name" lines. icon_map.sh from
# pkgs.sketchybar-app-font (on the agent PATH) defines __icon_map, which maps an
# app name to a glyph in $icon_result. One aerospace query + in-shell lookups keep
# a repaint to a single aerospace call and a single sketchybar call.
windows="$("$AEROSPACE" list-windows --all --format '%{workspace}|%{app-name}')"
map="$(command -v icon_map.sh)"
# shellcheck disable=SC1090 # resolved from PATH at runtime
[ -n "$map" ] && source "$map"

# Glyph string for one workspace: its deduped app names mapped to glyphs,
# space-separated. Empty output for an empty workspace.
glyphs_for() {
  ws="$1"
  out=""
  apps="$(printf '%s\n' "$windows" | awk -F'|' -v w="$ws" '$1==w && $2!="" && !seen[$2]++ {print $2}')"
  [ -z "$apps" ] && return 0
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    if [ -n "$map" ]; then
      __icon_map "$app"
      # shellcheck disable=SC2154 # icon_result is set by __icon_map
      out="$out$icon_result "
    else
      out="$out:default: "
    fi
  done <<EOF
$apps
EOF
  printf '%s' "$out"
}

set --

for ws in $("$AEROSPACE" list-workspaces --all); do
  g="$(glyphs_for "$ws")"
  if [ "$ws" = "$focused" ]; then
    set -- "$@" --set "space.$ws" drawing=on \
      label="$g" label.drawing=on label.color="$CRUST" \
      icon.color="$CRUST" background.drawing=on background.color="$MAUVE"
  else
    case "$nonempty" in
    *" $ws "*) set -- "$@" --set "space.$ws" drawing=on \
      label="$g" label.drawing=on label.color="$TEXT" \
      icon.color="$SUBTEXT0" background.drawing=on background.color="$SURFACE0" ;;
    *) set -- "$@" --set "space.$ws" drawing=off ;;
    esac
  fi
done

sketchybar "$@"
