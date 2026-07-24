# shellcheck shell=bash
# Left: next_meeting. Sourced by ../sketchybarrc.
#
# Minimal MeetingBar showing the nearest calendar boundary via icalBuddy (see
# plugins/meeting.sh): an upcoming event with a live countdown to its start
# ("14:00 Standup · in 12m"), or the current event counting down to its end
# ("Standup · 12m") — whichever transition comes first. A "+N" suffix
# flags a double-booking. Sits just left of the clock. Hidden until the plugin
# paints an event; needs Calendar access granted to the sketchybar agent on first
# run (Privacy & Security ▸ Calendars). update_freq here is only the initial
# cadence — the plugin re-sets it adaptively (5 min when far, 30s in the final
# 15 min).
sketchybar --add item next_meeting left \
    --set next_meeting \
    icon=󰃭 \
    icon.color="$TEXT" \
    drawing=off \
    update_freq=60 \
    script="$PLUGIN_DIR/meeting.sh"
