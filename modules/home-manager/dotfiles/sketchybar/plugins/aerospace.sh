#!/bin/bash
# Repaints the workspace items in a single sketchybar call. Each space.<ws>
# shows the workspace id; the focused one gets a mauve background pill with dark
# text, other non-empty ones are dimmed, and empty ones are hidden (there are
# ~30 persistent workspaces). FOCUSED_WORKSPACE is set when triggered by the
# AeroSpace exec-on-workspace-change callback; on other events, ask aerospace.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

set --

# Workspace items: id only. The focused one gets a mauve pill with dark text;
# other non-empty ones are dimmed with no pill (background.corner_radius/height
# come from the --default in sketchybarrc).
for ws in $("$AEROSPACE" list-workspaces --all); do
  if [ "$ws" = "$focused" ]; then
    set -- "$@" --set "space.$ws" drawing=on \
      icon.color="$CRUST" background.drawing=on background.color="$MAUVE"
  else
    case "$nonempty" in
    *" $ws "*) set -- "$@" --set "space.$ws" drawing=on \
      icon.color="$SUBTEXT0" background.drawing=off ;;
    *) set -- "$@" --set "space.$ws" drawing=off ;;
    esac
  fi
done

sketchybar "$@"
