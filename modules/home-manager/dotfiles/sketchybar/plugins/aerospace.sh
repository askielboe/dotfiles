#!/bin/bash
# Repaints the workspace items in a single sketchybar call. Each space.<ws>
# shows the workspace id; the focused one is accent-coloured, other non-empty
# ones are dimmed, and empty ones are hidden (there are ~30 persistent
# workspaces). FOCUSED_WORKSPACE is set when triggered by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

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

sketchybar "$@"
