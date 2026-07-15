#!/bin/bash
# Full-day "schedule strip" — a chevron-separated timeline of today's meetings:
#
#   09:00 Standup › 30m › 10:00 Design Review › 1h › 16:30 1:1 Bob
#
# Each SEGMENT is "start-time + calendar title"; the gaps between meetings
# appear as their own "30m" / "1h30m" break segments. Meetings that have already
# ended are dropped, so the strip shows only the current and upcoming ones: the
# segment covering *now* is highlighted with a live countdown, upcoming ones are
# normal. Because a single sketchybar label is one solid colour, the strip is
# drawn as a POOL of items (schedule.0 … schedule.N, registered in
# items/schedule.sh) painted by this one invisible controller — that's what lets
# each segment carry its own colour.
#
# Data comes from icalBuddy (brew: ical-buddy), same EventKit calendars as
# Calendar.app / the next_meeting item. EventKit is TCC-gated, so the sketchybar
# launchd agent needs Calendar access (already granted for next_meeting).
#
# OVERLAPS are rendered as an INTERRUPTION TIMELINE, not merged into one segment.
# A sweep line runs over every start/end boundary; in each interval the displayed
# event is the ongoing one with the LATEST start (ties -> earliest end). So a
# meeting starting inside another takes over, and the interrupted meeting RESUMES
# as a fresh segment when the interrupter ends — e.g. A 10:00–12:00 with a nested
# B 10:30–10:45 renders as:
#   10:00 A › 10:30 B › 10:45 A
# each showing its own take-over time. Adjacent intervals with the same active
# event are merged (so a non-active event ending never splits a segment); a
# stretch with nothing ongoing becomes a break segment.
#
# The core (icalBuddy lines + now -> per-segment specs) is factored into
# render_schedule so it can be unit-tested with fixtures (override summarize_title
# with a stub); main() only runs when executed, not sourced (guard at the bottom).

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

# Homebrew bin isn't on the agent PATH; /bin/date is BSD date (its -j -f parsing
# isn't in the GNU coreutils `date` nix may shadow it with). Same as meeting.sh.
ICALBUDDY="/opt/homebrew/bin/icalBuddy"

# Calendars to draw, as EXACT icalBuddy names (-ic is an exact, comma-separated
# match — not a substring, so "Andreas" never catches "Andreas Studievejledning").
# Their events are merged into ONE timeline: the strip makes no per-calendar
# distinction, so overlaps across calendars interleave like same-calendar ones.
# `icalBuddy calendars` lists the available names. Add more here, comma-joined.
SCHED_CALENDARS='Andreas,askielboe@hccreators.com'

# Number of display items registered in items/schedule.sh — KEEP IN SYNC.
SCHED_POOL=14

# When there are no current or upcoming meetings the strip celebrates instead of
# going blank: SCHED_FREE_MSG when the day has no meetings at all, SCHED_DONE_MSG
# once the day's meetings are all finished. Emoji render in colour in the label
# (Apple Color Emoji fallback) — edit the wording/emoji freely.
SCHED_DONE_MSG='🎉 Done for the day'
SCHED_FREE_MSG='🎉 No meetings today'

# Seconds -> compact duration: "1h" / "1h30m" / "45m" / "30s".
fmt_dur() {
  local s="$1" h m
  if [ "$s" -ge 3600 ]; then
    h=$((s / 3600))
    m=$(((s % 3600) / 60))
    if [ "$m" -eq 0 ]; then printf '%dh' "$h"; else printf '%dh%02dm' "$h" "$m"; fi
  elif [ "$s" -ge 60 ]; then
    printf '%dm' "$((s / 60))"
  else
    printf '%ds' "$s"
  fi
}

# Label for an event: currently the raw calendar title (the LLM title shortener
# was removed). Kept as a seam — render_schedule calls this rather than reading
# the title directly, so tests can stub it and a shortener can be dropped back in
# here later without touching the render logic.
summarize_title() {
  printf '%s' "$1"
}

# --- render state (globals; reset at the top of render_schedule) ---------------
# Parsed events, ascending by start (icalBuddy already sorts this way).
SCHED_TITLES=()
SCHED_STARTS=()
SCHED_ENDS=()
SCHED_SUMS=() # one label per event (an event may span >1 segment)
# Emitted segments, in strip order.
SCHED_SEGC=() # colour (0xAARRGGBB)
SCHED_SEGL=() # label
SCHED_SEGK=() # kind: event | break

# Append one segment for the sweep span [s_start, s_end). idx == -1 -> a break
# (nothing ongoing); else event `idx`: GREEN with a countdown if the span covers
# now, TEXT if still to come. (Already-ended events are filtered out before the
# sweep, so the `past`/dim branch is just a guard and normally never fires.)
_sched_emit_span() {
  local idx="$1" s_start="$2" s_end="$3" now="$4" color state hhmm label
  if [ "$idx" -eq -1 ]; then
    SCHED_SEGC+=("$SUBTEXT0")
    SCHED_SEGL+=("$(fmt_dur $((s_end - s_start)))")
    SCHED_SEGK+=("break")
    return
  fi
  hhmm="$(/bin/date -j -f %s "$s_start" '+%H:%M')"
  if ((s_end <= now)); then
    state=past
  elif ((s_start <= now)); then
    state=current # now within [s_start, s_end)
  else
    state=future
  fi
  case "$state" in
  past) color="$OVERLAY0" ;;
  current) color="$GREEN" ;;
  *) color="$TEXT" ;;
  esac
  label="$hhmm ${SCHED_SUMS[$idx]}"
  [ "$state" = current ] && label="$label · $(fmt_dur $((s_end - now)))"
  SCHED_SEGC+=("$color")
  SCHED_SEGL+=("$label")
  SCHED_SEGK+=("event")
}

# render_schedule NOW  (reads icalBuddy "<title>@@<HH:MM - HH:MM>" lines on stdin)
# Emits, in strip order:
#   seg<TAB><chev 0|1><TAB><color><TAB><label>     one per visible segment
#   ctrl<TAB><used_count><TAB><update_freq>
render_schedule() {
  local now="$1"
  SCHED_TITLES=()
  SCHED_STARTS=()
  SCHED_ENDS=()
  SCHED_SUMS=()
  SCHED_SEGC=()
  SCHED_SEGL=()
  SCHED_SEGK=()

  local line title dt times ntok shhmm ehhmm s e today first_title="" parsed=0
  today="$(/bin/date +%Y-%m-%d)"

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    title="${line%@@*}"
    dt="${line##*@@}"
    [ -n "$first_title" ] || first_title="$title"
    # HH:MM tokens: first = start, last = end (icalBuddy gives "HH:MM - HH:MM"
    # without -eed). The "YYYY-MM-DD" date prefix has no colon so never matches.
    times="$(printf '%s\n' "$dt" | grep -oE '[0-2][0-9]:[0-5][0-9]')"
    [ -n "$times" ] || continue
    ntok="$(printf '%s\n' "$times" | grep -c '.')"
    shhmm="$(printf '%s\n' "$times" | head -1)"
    ehhmm="$(printf '%s\n' "$times" | tail -1)"
    s="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$today $shhmm" +%s 2>/dev/null)"
    [ -n "$s" ] || continue
    e="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$today $ehhmm" +%s 2>/dev/null)"
    [ -n "$e" ] || e="$s"
    if [ "$ntok" -ge 2 ] && [ "$e" -le "$s" ]; then e=$((e + 86400)); fi # wraps past midnight
    parsed=$((parsed + 1))
    # Drop meetings that have already ended — the strip shows only the current
    # and upcoming ones. A still-ongoing meeting (end > now, started in the past)
    # is kept and rendered as the current segment.
    [ "$e" -gt "$now" ] || continue
    SCHED_TITLES+=("$title")
    SCHED_STARTS+=("$s")
    SCHED_ENDS+=("$e")
  done

  local n=${#SCHED_STARTS[@]}
  if [ "$n" -eq 0 ]; then
    # No current/upcoming meetings — draw a single segment (chevron-less slot 0)
    # rather than nothing. Three cases:
    #  parsed==0 & first_title -> icalBuddy returned lines but no times parsed
    #                             (format drift); show the first title raw.
    #  parsed>0                -> the day's meetings are all finished; celebrate.
    #  else                    -> no timed meetings today at all; celebrate free.
    if [ "$parsed" -eq 0 ] && [ -n "$first_title" ]; then
      printf 'seg\t0\t%s\t%s\n' "$TEXT" "$(printf '%s' "$first_title" | cut -c1-24)"
    elif [ "$parsed" -gt 0 ]; then
      printf 'seg\t0\t%s\t%s\n' "$GREEN" "$SCHED_DONE_MSG"
    else
      printf 'seg\t0\t%s\t%s\n' "$GREEN" "$SCHED_FREE_MSG"
    fi
    printf 'ctrl\t1\t300\n'
    return
  fi

  # One shortened label per event, reused if the event spans multiple segments
  # (an interrupted meeting appears once before and once after the interrupter).
  local i
  for ((i = 0; i < n; i++)); do
    SCHED_SUMS[$i]="$(summarize_title "${SCHED_TITLES[$i]}")"
  done

  # Sweep line over every start/end boundary (deduped, ascending). In each
  # elementary interval the active (displayed) event is the ongoing one with the
  # LATEST start, ties broken by earliest end — so a meeting starting inside
  # another takes over, and the interrupted one resumes when it ends. Adjacent
  # intervals with the same active event merge into a single segment; intervals
  # with nothing ongoing become breaks (their length is the free time).
  local bounds=()
  for ((i = 0; i < n; i++)); do
    bounds+=("${SCHED_STARTS[$i]}" "${SCHED_ENDS[$i]}")
  done
  # NB: macOS /bin/bash is 3.2 — no `mapfile`/`readarray`. Read the sorted-unique
  # boundary list with a while-read loop so the plugin runs under the system bash
  # the sketchybar agent invokes it with (not just a Homebrew bash 5).
  local BOUNDS=() _b
  while IFS= read -r _b; do BOUNDS+=("$_b"); done \
    < <(printf '%s\n' "${bounds[@]}" | sort -n -u)

  local nb=${#BOUNDS[@]} j left active bstart bend prev=-2 span_start=0
  for ((j = 0; j < nb - 1; j++)); do
    left=${BOUNDS[$j]}
    active=-1
    bstart=-1
    bend=0
    for ((i = 0; i < n; i++)); do
      if ((SCHED_STARTS[i] <= left && SCHED_ENDS[i] > left)); then
        if ((SCHED_STARTS[i] > bstart || (SCHED_STARTS[i] == bstart && (active == -1 || SCHED_ENDS[i] < bend)))); then
          active=$i
          bstart=${SCHED_STARTS[$i]}
          bend=${SCHED_ENDS[$i]}
        fi
      fi
    done
    if ((active != prev)); then
      ((prev != -2)) && _sched_emit_span "$prev" "$span_start" "$left" "$now"
      prev=$active
      span_start=$left
    fi
  done
  ((prev != -2)) && _sched_emit_span "$prev" "$span_start" "${BOUNDS[$((nb - 1))]}" "$now"

  # Cap to the pool; if it overflows, the last slot becomes a "+N" of the dropped
  # event segments (breaks don't count).
  local total=${#SCHED_SEGC[@]} k chev used dropped
  if [ "$total" -gt "$SCHED_POOL" ]; then
    used=$((SCHED_POOL - 1))
    dropped=0
    for ((k = used; k < total; k++)); do
      [ "${SCHED_SEGK[$k]}" = event ] && dropped=$((dropped + 1))
    done
    SCHED_SEGC[$used]="$OVERLAY0"
    SCHED_SEGL[$used]="+$dropped"
    total=$((used + 1))
  fi

  for ((k = 0; k < total; k++)); do
    chev=1
    [ "$k" -eq 0 ] && chev=0
    printf 'seg\t%d\t%s\t%s\n' "$chev" "${SCHED_SEGC[$k]}" "${SCHED_SEGL[$k]}"
  done

  # Adaptive cadence: seconds to the next boundary (next start or current end).
  local next=-1 t d mins freq en st
  for ((i = 0; i < n; i++)); do
    st=${SCHED_STARTS[$i]}
    en=${SCHED_ENDS[$i]}
    if [ "$st" -gt "$now" ]; then
      t=$st
    elif [ "$en" -gt "$now" ]; then
      t=$en
    else
      continue
    fi
    if [ "$next" -lt 0 ] || [ "$t" -lt "$next" ]; then next=$t; fi
  done
  if [ "$next" -lt 0 ]; then
    freq=300
  else
    d=$((next - now))
    mins=$(((d + 30) / 60))
    if [ "$mins" -le 15 ]; then
      freq=30
    elif [ "$mins" -le 60 ]; then
      freq=60
    else
      freq=300
    fi
  fi
  printf 'ctrl\t%d\t%d\n' "$total" "$freq"
}

# Apply a render_schedule block to the item pool in one sketchybar call.
apply_schedule() {
  local data="$1" tag chev color label idx=0 freq=300 icon k
  local args=()
  while IFS=$'\t' read -r tag chev color label; do
    case "$tag" in
    seg)
      icon=""
      [ "$chev" = 1 ] && icon="›" # chevron before every segment but the first (styled in items/schedule.sh)
      args+=(--set "schedule.$idx" drawing=on icon="$icon" label.color="$color" label="$label")
      idx=$((idx + 1))
      ;;
    ctrl)
      freq="$chev" # ctrl<TAB>used<TAB>freq -> freq lands in the 2nd field here
      ;;
    esac
  done < <(printf '%s\n' "$data")

  for ((k = idx; k < SCHED_POOL; k++)); do
    args+=(--set "schedule.$k" drawing=off)
  done
  args+=(--set schedule update_freq="$freq")
  sketchybar "${args[@]}"
}

main() {
  if [ ! -x "$ICALBUDDY" ]; then
    local k
    local args=(--set schedule update_freq=300)
    for ((k = 0; k < SCHED_POOL; k++)); do args+=(--set "schedule.$k" drawing=off); done
    sketchybar "${args[@]}"
    exit 0
  fi
  local now out
  now="$(/bin/date +%s)"
  # Fetch the WHOLE day, not just -n upcoming: a currently-ongoing meeting
  # started in the past, so we must see past-starting events too — render_schedule
  # keeps them by endtime and drops only the already-ended ones. -li 20 catches
  # overlaps; -ea skips all-day; -ic merges the SCHED_CALENDARS into one stream
  # (icalBuddy returns them sorted by start, which render_schedule then sweeps).
  out="$("$ICALBUDDY" -ic "$SCHED_CALENDARS" -ea -nc -npn -nrd -b '' -ps '|@@|' \
    -iep 'title,datetime' -df '%Y-%m-%d' -tf '%H:%M' -li 20 eventsToday \
    2>/dev/null | render_schedule "$now")"
  apply_schedule "$out"
}

# Only run when executed by sketchybar (script=); stay inert when sourced by tests.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main; fi
