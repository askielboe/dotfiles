#!/bin/bash
# Repaints every workspace item in a single sketchybar call.
# FOCUSED_WORKSPACE is set when triggered by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

set --
for ws in $("$AEROSPACE" list-workspaces --all); do
  if [ "$ws" = "$focused" ]; then
    set -- "$@" --set "space.$ws" drawing=on \
      background.drawing=on background.color="$MAUVE" label.color="$CRUST"
  else
    case "$nonempty" in
    *" $ws "*)
      set -- "$@" --set "space.$ws" drawing=on \
        background.drawing=off label.color="$SUBTEXT0"
      ;;
    *)
      set -- "$@" --set "space.$ws" drawing=off
      ;;
    esac
  fi
done

sketchybar "$@"
