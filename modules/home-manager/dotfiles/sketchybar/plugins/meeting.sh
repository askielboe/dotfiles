#!/bin/bash
# Right-side "next meeting" item — a minimal MeetingBar: just the next upcoming
# timed calendar event as "<countdown> · <title>". No dropdown, no join button.
#
# Data comes from icalBuddy (brew: ical-buddy), which reads the same EventKit
# calendars MeetingBar / Calendar.app use. EventKit is gated by TCC, so the
# process that runs icalBuddy — here the sketchybar launchd agent — must be
# granted Calendar access the first time (System Settings ▸ Privacy & Security ▸
# Calendars). Until it is, icalBuddy returns nothing and this item stays hidden.
#
# Polling is adaptive (see the freq flips below): icalBuddy is only spawned every
# 5 min when the next meeting is far off, ramping to every 30s in the final
# quarter-hour — the same "tick only when it matters" idea as the pomodoro item.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

# Homebrew bin isn't on the agent's PATH (like aerospace/stats_provider), so use
# the absolute path. /bin/date is the BSD date — its -j -f parsing is not in the
# GNU coreutils `date` that nix may shadow it with on the agent's PATH.
ICALBUDDY="/opt/homebrew/bin/icalBuddy"

hide() { sketchybar --set "$NAME" drawing=off update_freq="${1:-300}"; exit 0; }

# Nothing to query with (e.g. before `hs` installs the formula) -> stay hidden.
[ -x "$ICALBUDDY" ] || hide

# Next timed event starting from now, as one machine-readable line:
#   "<title>@@<YYYY-MM-DD at HH:MM>"
# -ic restricts to just the mo2tion Google calendar (its primary calendar is
# named "Andreas"), so personal/other calendars never surface here.
# -n from now on · -ea skip all-day · -eed start only · -li 1 just the next one.
line="$("$ICALBUDDY" -ic 'Andreas' -n -ea -nc -npn -nrd -eed -b '' -ps '|@@|' \
  -iep 'title,datetime' -df '%Y-%m-%d' -tf '%H:%M' -li 1 eventsToday+1 \
  2>/dev/null | head -1)"

# No upcoming meeting today or tomorrow — hide, re-check in 5 min.
[ -n "$line" ] || hide

title="${line%@@*}"
dt="${line##*@@}"

start=$(/bin/date -j -f '%Y-%m-%d at %H:%M' "$dt" +%s 2>/dev/null)
if [ -z "$start" ]; then
  # Unparseable datetime (locale/format drift) — don't hide it, show title raw.
  sketchybar --set "$NAME" drawing=on icon.color="$TEXT" label="$title" update_freq=300
  exit 0
fi
now=$(/bin/date +%s)
mins=$(((start - now + 30) / 60)) # round to nearest minute

# Countdown text: <1h in minutes, <10h as HhMm, else weekday + clock (tomorrow).
if [ "$mins" -lt 1 ]; then
  cd="now"
elif [ "$mins" -lt 60 ]; then
  cd="${mins}m"
elif [ "$mins" -lt 600 ]; then
  cd="$((mins / 60))h$((mins % 60))m"
else
  cd="$(/bin/date -j -f %s "$start" '+%a %H:%M')"
fi

# Urgency colour + poll cadence both ramp as the meeting approaches.
if [ "$mins" -le 5 ]; then
  color="$RED" freq=30
elif [ "$mins" -le 15 ]; then
  color="$PEACH" freq=30
elif [ "$mins" -le 60 ]; then
  color="$TEXT" freq=60
else
  color="$TEXT" freq=300
fi

# Truncate long titles so the item can't shove the rest of the bar around.
max=24
[ "${#title}" -gt "$max" ] && title="${title:0:$((max - 1))}…"

sketchybar --set "$NAME" \
  drawing=on \
  update_freq="$freq" \
  icon.color="$color" \
  label="$cd · $title"
