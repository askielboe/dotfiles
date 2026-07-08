# shellcheck shell=bash
# Right: productive time today from ActivityWatch. Sourced by ../sketchybarrc.
#
# Two items painted by ../plugins/productive.sh in one pass: `productive` (the
# active one — owns the timer, icon and goal-ramped colour) shows today's
# active time categorised under the "Work" tree; `productive_unc` is a passive,
# dim companion showing today's Uncategorized time. Added unc-first so that in
# the right region (first added = rightmost) it sits just right of the main
# figure, reading "󰔟 4h 13m ·1h 0m". Both start hidden; the plugin reveals them
# once it has data (and hides them again if aw-server is unreachable). Click
# opens the AW dashboard. jq/curl come from services.sketchybar.extraPackages.

sketchybar --add item productive_unc right \
  --set productive_unc \
    icon.drawing=off \
    label.color="$OVERLAY0" \
    label.padding_left=2 \
    drawing=off \
    click_script="open http://localhost:5600"

sketchybar --add item productive right \
  --set productive \
    icon=󰔟 \
    icon.color="$LAVENDER" \
    label.padding_right=4 \
    drawing=off \
    update_freq=60 \
    click_script="open http://localhost:5600" \
    script="$PLUGIN_DIR/productive.sh"
