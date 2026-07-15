#!/bin/bash
# Right-side "next meeting" item — a minimal MeetingBar that shows whichever
# calendar boundary is nearest in time:
#   • an UPCOMING event   -> "<start time> · <title>"   (e.g. "14:00 · Standup")
#   • the CURRENT event   -> "<title> · <time left>"    (e.g. "Standup · 12m")
# whichever transition (next event's START or current event's END) comes first.
# So while you're in a meeting it counts down to its end, but if the next meeting
# is about to start it surfaces that instead — the item always answers "what's
# the next change on my calendar?".
#
# Overlaps: when several events are live/imminent we fetch a handful (-li 5,
# icalBuddy sorts by start ascending so ongoing events lead) and pick the soonest
# boundary. When two or more events cover *now* (a genuine double-booking) the
# label gets a "+N" suffix counting the OTHER concurrent events (e.g. "Sync · 8m +1").
#
# Data comes from icalBuddy (brew: ical-buddy), which reads the same EventKit
# calendars MeetingBar / Calendar.app use. EventKit is gated by TCC, so the
# process that runs icalBuddy — here the sketchybar launchd agent — must be
# granted Calendar access the first time (System Settings ▸ Privacy & Security ▸
# Calendars). Until it is, icalBuddy returns nothing and this item stays hidden.
#
# Polling is adaptive (see the freq flips in render_decision): icalBuddy is only
# spawned every 5 min when the next boundary is far off, ramping to every 30s in
# the final quarter-hour — the same "tick only when it matters" idea as pomodoro.
#
# The core (parse lines + now -> decision) is factored into render_decision so it
# can be unit-tested with fixtures; main() is only run when the file is executed
# (not sourced) via the guard at the bottom.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

# Homebrew bin isn't on the agent's PATH (like aerospace/stats_provider), so use
# the absolute path. /bin/date is the BSD date — its -j -f parsing is not in the
# GNU coreutils `date` that nix may shadow it with on the agent's PATH.
ICALBUDDY="/opt/homebrew/bin/icalBuddy"

# Seconds -> compact duration: "1h05m" / "42m" / "30s" (matches micromanager).
fmt_remaining() {
  local s="$1"
  if [ "$s" -ge 3600 ]; then
    printf '%dh%02dm' "$((s / 3600))" "$(((s % 3600) / 60))"
  elif [ "$s" -ge 60 ]; then
    printf '%dm' "$((s / 60))"
  else
    printf '%ds' "$s"
  fi
}

# render_decision NOW  (reads icalBuddy "<title>@@<datetime>" lines on stdin)
# Prints ONE decision line for main() to act on:
#   hide
#   raw<TAB><title>                        (all datetimes unparseable — show title)
#   show<TAB><color><TAB><freq><TAB><label>
render_decision() {
  local now="$1"
  local titles=() starts=() ends=()
  local first_title="" line title dt times ntok shhmm ehhmm s e
  local today
  today="$(/bin/date +%Y-%m-%d)"

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    title="${line%@@*}"
    dt="${line##*@@}"
    [ -n "$first_title" ] || first_title="$title"

    # Pull the HH:MM tokens out of the datetime field. Without -eed the field is
    # "HH:MM - HH:MM"; take first as start, last as end. Robust to any
    # "YYYY-MM-DD at …" prefix icalBuddy prepends for multi-day events (the date
    # has no colon, so it never matches).
    times="$(printf '%s\n' "$dt" | grep -oE '[0-2][0-9]:[0-5][0-9]')"
    [ -n "$times" ] || continue
    ntok="$(printf '%s\n' "$times" | grep -c '.')"
    shhmm="$(printf '%s\n' "$times" | head -1)"
    ehhmm="$(printf '%s\n' "$times" | tail -1)"

    s="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$today $shhmm" +%s 2>/dev/null)"
    [ -n "$s" ] || continue
    e="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$today $ehhmm" +%s 2>/dev/null)"
    [ -n "$e" ] || e="$s"
    # Genuine end present and it wraps past midnight -> it's tomorrow.
    if [ "$ntok" -ge 2 ] && [ "$e" -le "$s" ]; then e=$((e + 86400)); fi

    titles+=("$title")
    starts+=("$s")
    ends+=("$e")
  done

  local n=${#starts[@]}
  if [ "$n" -eq 0 ]; then
    # We saw lines but none parsed — don't blank a real meeting, show it raw.
    if [ -n "$first_title" ]; then printf 'raw\t%s\n' "$first_title"; else echo "hide"; fi
    return
  fi

  # Nearest-boundary selection. For each event the "next transition" is its start
  # (upcoming) or its end (ongoing); pick the soonest. Tie-break: when an ongoing
  # end coincides with an upcoming start (back-to-back), prefer the ongoing end.
  local i best=-1 best_t=0 best_ong=0 ongoing_count=0
  local st en trans is_ong take
  for ((i = 0; i < n; i++)); do
    st=${starts[$i]}
    en=${ends[$i]}
    if [ "$st" -gt "$now" ]; then
      trans=$st
      is_ong=0
    elif [ "$en" -gt "$now" ]; then
      trans=$en
      is_ong=1
      ongoing_count=$((ongoing_count + 1))
    else
      continue # already ended (guard) — ignore
    fi

    take=0
    if [ "$best" -lt 0 ]; then
      take=1
    elif [ "$trans" -lt "$best_t" ]; then
      take=1
    elif [ "$trans" -eq "$best_t" ] && [ "$is_ong" -eq 1 ] && [ "$best_ong" -eq 0 ]; then
      take=1
    fi
    if [ "$take" -eq 1 ]; then
      best=$i
      best_t=$trans
      best_ong=$is_ong
    fi
  done

  # Everything today has already ended.
  if [ "$best" -lt 0 ]; then echo "hide"; return; fi

  local btitle=${titles[$best]} bstart=${starts[$best]} bend=${ends[$best]} secs label
  # Truncate long titles so the item can't shove the rest of the bar around.
  local max=24
  [ "${#btitle}" -gt "$max" ] && btitle="${btitle:0:$((max - 1))}…"

  if [ "$best_ong" -eq 1 ]; then
    secs=$((bend - now))
    label="$btitle · $(fmt_remaining "$secs")"
  else
    secs=$((bstart - now))
    label="$(/bin/date -j -f %s "$bstart" '+%H:%M') · $btitle"
  fi
  # Flag a genuine double-booking (2+ events covering now) with the count of the
  # other concurrent events. ASCII "+N" renders in any font (Hack Nerd Font can
  # silently fall back to tofu on glyphs it lacks).
  [ "$ongoing_count" -ge 2 ] && label="$label +$((ongoing_count - 1))"

  # Urgency colour + poll cadence both ramp as the nearest boundary approaches.
  local mins=$(((secs + 30) / 60)) color freq
  if [ "$mins" -le 5 ]; then
    color="$RED" freq=30
  elif [ "$mins" -le 15 ]; then
    color="$PEACH" freq=30
  elif [ "$mins" -le 60 ]; then
    color="$TEXT" freq=60
  else
    color="$TEXT" freq=300
  fi

  printf 'show\t%s\t%s\t%s\n' "$color" "$freq" "$label"
}

main() {
  # Nothing to query with (e.g. before `hs` installs the formula) -> stay hidden.
  [ -x "$ICALBUDDY" ] || { sketchybar --set "$NAME" drawing=off update_freq=300; exit 0; }

  # Next timed events starting from now (incl. ongoing, since -n keeps not-yet-
  # ended events), each as one machine-readable line "<title>@@<HH:MM - HH:MM>".
  # -ic restricts to just the mo2tion Google calendar (primary calendar "Andreas").
  # -n from now on · -ea skip all-day · -li 5 covers nested/overlapping events.
  local now decision
  now="$(/bin/date +%s)"
  decision="$("$ICALBUDDY" -ic 'Andreas' -n -ea -nc -npn -nrd -b '' -ps '|@@|' \
    -iep 'title,datetime' -df '%Y-%m-%d' -tf '%H:%M' -li 5 eventsToday \
    2>/dev/null | render_decision "$now")"

  case "$decision" in
  show*)
    local _tag color freq label
    IFS=$'\t' read -r _tag color freq label <<<"$decision"
    sketchybar --set "$NAME" drawing=on update_freq="$freq" icon.color="$color" label="$label"
    ;;
  raw*)
    local title="${decision#raw$'\t'}"
    sketchybar --set "$NAME" drawing=on icon.color="$TEXT" label="$title" update_freq=300
    ;;
  *) # hide / empty
    sketchybar --set "$NAME" drawing=off update_freq=300
    ;;
  esac
}

# Only run when executed by sketchybar (script=); stay inert when sourced by tests.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main; fi
