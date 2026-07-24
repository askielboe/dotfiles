# shellcheck shell=bash
# Left: full-day schedule strip. Sourced by ../sketchybarrc.
#
# A chevron-separated timeline of today's meetings, e.g.
#   09:00 Standup › 30m › 10:00 Design Review › 1h › 16:30 1:1 Bob
# with break durations between meetings, already-ended meetings
# dropped, the current meeting highlighted, and overlapping meetings shown as an
# interruption timeline (the interrupted one resumes as a fresh segment). A live
# countdown to the next meeting is always shown: to the current meeting's end
# while you're in it, to the next meeting's start while you're between meetings.
# See plugins/schedule.sh for all the logic.
#
# Since a single sketchybar label is one solid colour, the strip is a POOL of
# items (schedule.0 … schedule.N) painted by one invisible controller item, so
# each segment can carry its own colour. Needs Calendar access on the sketchybar
# agent (already granted for next_meeting).

# Number of display slots — KEEP IN SYNC with SCHED_POOL in plugins/schedule.sh.
SCHED_POOL=14

# Invisible controller: owns the update timer + script and paints the pool. Like
# stats_controller, it never draws; it just ticks and re-sets the pool items.
sketchybar --add item schedule left \
    --set schedule drawing=off update_freq=60 script="$PLUGIN_DIR/schedule.sh"

# Display pool, no background box so segments read as one continuous strip. The
# leading chevron on every item but the first is that item's icon (glyph set at
# paint time in plugins/schedule.sh); its colour/size/spacing are constant and
# live here — a bright lavender at 16pt with even space on both sides, so it reads
# as an obvious separator ("A > B", not "A >B"). Icon colour is independent of the
# label colour, so the separator stays lavender whatever state the segment is.
for ((_si = 0; _si < SCHED_POOL; _si++)); do
    # Slot 0 has no chevron -> a small plain left pad. Every other slot leads with
    # the chevron: icon.padding_left is the gap BEFORE it (adds to the previous
    # label's right pad), icon.padding_right the gap AFTER it, before this label.
    if [ "$_si" -eq 0 ]; then
        _ipl=4
        _ipr=0
    else
        _ipl=3
        _ipr=6
    fi
    sketchybar --add item "schedule.$_si" left \
        --set "schedule.$_si" drawing=off \
        icon.font="Hack Nerd Font:Bold:16.0" \
        icon.color="$LAVENDER" \
        icon.padding_left="$_ipl" icon.padding_right="$_ipr" \
        label.padding_left=0 label.padding_right=3
done
unset _si _ipl _ipr
