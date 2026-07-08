#!/bin/bash
# Repaints the workspace items and the focused workspace's window glyphs in a
# single sketchybar call.
#   - Each space.<ws> shows the workspace id; the focused one is accent-coloured
#     (no full-row highlight).
#   - win.1..N show one sketchybar-app-font glyph per window in the FOCUSED
#     workspace (its accordion / tiled stack). Only the focused window's glyph
#     gets a highlight pill. The pool is moved to sit right after the focused
#     workspace, and unused pool items are hidden.
# FOCUSED_WORKSPACE is set when triggered by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"
MAX_WIN=16

# icon_map.sh (pkgs.sketchybar-app-font, on the agent PATH) defines __icon_map,
# which maps an app name to a glyph in $icon_result.
map="$(command -v icon_map.sh)"
# shellcheck disable=SC1090 # resolved from PATH at runtime
[ -n "$map" ] && source "$map"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "
focused_win="$("$AEROSPACE" list-windows --focused --format '%{window-id}' 2>/dev/null)"

set --

# Workspace items: id only, focused one accent-coloured.
for ws in $("$AEROSPACE" list-workspaces --all); do
  if [ "$ws" = "$focused" ]; then
    set -- "$@" --set "space.$ws" drawing=on icon.color="$MAUVE"
  else
    case "$nonempty" in
    *" $ws "*) set -- "$@" --set "space.$ws" drawing=on icon.color="$SUBTEXT0" ;;
    *) set -- "$@" --set "space.$ws" drawing=off ;;
    esac
  fi
done

# One window glyph per window in the focused workspace; highlight the focused
# window. Duplicates are kept (two Ghostty windows -> two glyphs), so the
# accordion's depth stays visible.
i=0
if [ -n "$map" ]; then
  while IFS='|' read -r wid app; do
    [ -z "$wid" ] && continue
    i=$((i + 1))
    [ "$i" -gt "$MAX_WIN" ] && break
    __icon_map "$app"
    # shellcheck disable=SC2154 # icon_result is set by __icon_map
    if [ "$wid" = "$focused_win" ]; then
      set -- "$@" --set "win.$i" drawing=on icon="$icon_result" \
        icon.color="$CRUST" background.drawing=on background.color="$MAUVE"
    else
      set -- "$@" --set "win.$i" drawing=on icon="$icon_result" \
        icon.color="$TEXT" background.drawing=off
    fi
  done < <("$AEROSPACE" list-windows --workspace "$focused" --format '%{window-id}|%{app-name}')
fi

# Hide the unused tail of the pool.
j=$((i + 1))
while [ "$j" -le "$MAX_WIN" ]; do
  set -- "$@" --set "win.$j" drawing=off
  j=$((j + 1))
done

# Slide the visible glyphs to sit right after the focused workspace. Moving
# them after the same reference in reverse leaves them in order win.1..win.i.
k="$i"
while [ "$k" -ge 1 ]; do
  set -- "$@" --move "win.$k" after "space.$focused"
  k=$((k - 1))
done

sketchybar "$@"
