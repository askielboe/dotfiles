#!/bin/bash
# Repaints every workspace item in a single sketchybar call.
# The item's icon is the workspace id; the focused workspace's label also shows
# a glyph per window (its accordion / tiled stack), so you can see everything
# stacked in an accordion without cycling through it. Other non-empty
# workspaces show only their id.
# FOCUSED_WORKSPACE is set when triggered by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

# icon_map.sh (pkgs.sketchybar-app-font, on the agent PATH) defines __icon_map,
# which maps an app name to a glyph in $icon_result.
map="$(command -v icon_map.sh)"
# shellcheck disable=SC1090 # resolved from PATH at runtime
[ -n "$map" ] && source "$map"

# One glyph per window in a workspace (not deduplicated: two Ghostty windows
# render two glyphs, so the accordion's depth is visible).
workspace_glyphs() {
  [ -n "$map" ] || return
  local glyphs="" app
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    __icon_map "$app"
    # shellcheck disable=SC2154 # icon_result is set by __icon_map
    glyphs+="$icon_result "
  done < <("$AEROSPACE" list-windows --workspace "$1" --format '%{app-name}')
  printf '%s' "${glyphs% }"
}

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

set --
for ws in $("$AEROSPACE" list-workspaces --all); do
  if [ "$ws" = "$focused" ]; then
    glyphs="$(workspace_glyphs "$ws")"
    ldraw=off
    [ -n "$glyphs" ] && ldraw=on
    set -- "$@" --set "space.$ws" drawing=on \
      background.drawing=on background.color="$MAUVE" \
      icon.color="$CRUST" \
      label="$glyphs" label.color="$CRUST" label.drawing="$ldraw"
  else
    case "$nonempty" in
    *" $ws "*)
      set -- "$@" --set "space.$ws" drawing=on \
        background.drawing=off icon.color="$SUBTEXT0" label.drawing=off
      ;;
    *)
      set -- "$@" --set "space.$ws" drawing=off
      ;;
    esac
  fi
done

sketchybar "$@"
