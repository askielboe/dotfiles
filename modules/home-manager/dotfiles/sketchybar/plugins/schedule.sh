#!/bin/bash
# Full-day "schedule strip" — a chevron-separated timeline of today's meetings:
#
#   09:00 Standup › 30m › 10:00 Design Review › 1h › 16:30 1:1 Bob
#
# Each SEGMENT is "start-time + calendar title"; the gaps between meetings
# appear as their own "30m" / "1h30m" break segments. Meetings that have already
# ended are dropped, so the strip shows only the current and upcoming ones. A
# live countdown to the next meeting is ALWAYS present: the segment covering
# *now* is highlighted and counts down to its END ("09:00 Standup · 12m"); when
# no meeting is on, the leading (next) segment counts down to its START instead
# ("14:00 Standup · in 25m"). Because a single sketchybar label is one solid colour, the strip is
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
# `icalBuddy calendars` lists the available names.
#
# The list contains a work email, so it's machine-specific and NOT stored in the
# repo: home-manager writes it from secrets/private.nix (see darwin-specific.nix,
# ~/.local/state/sketchybar/calendars.env). Edit that private value to add
# calendars. The fallback keeps the strip from erroring on an unprovisioned box.
CAL_ENV="${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar/calendars.env"
# shellcheck source=/dev/null
[ -r "$CAL_ENV" ] && source "$CAL_ENV"
: "${SCHED_CALENDARS:=Calendar}"

# Number of display items registered in items/schedule.sh — KEEP IN SYNC.
SCHED_POOL=14

# --- responsive width fitting -------------------------------------------------
# The strip is left-anchored and grows rightward; on a narrow display it would
# otherwise run under the notch (or into the right-hand stats cluster / centre
# focus HUD). compute_avail_px measures, from sketchybar's live per-display
# bounding_rects, how many pixels the strip actually has, and render_schedule
# then drops trailing segments into the existing "+N" slot so it always fits.
#
# Font metrics measured from the live bar (Hack Nerd Font: label Regular 13,
# chevron Bold 16): ~7.85 px/char, ~7 px slot-0 padding, ~16 px chevron-slot
# overhead. Rounded UP so estimates never under-shoot (better to keep the strip
# a touch short than to overflow behind the notch).
SCHED_CHAR_T=79    # px×10 per label char (7.9)
SCHED_OH_FIRST=7   # slot 0 (no chevron) fixed padding
SCHED_OH_CHEV=16   # chevron slot fixed overhead (paddings + glyph)
SCHED_PLUSN_W=44   # px reserved for the trailing "+N" overflow slot

# Half the bar's notch_width (KEEP IN SYNC with notch_width in ../sketchybarrc)
# plus a little clearance. On the notched built-in display this keeps the strip
# clear of the camera housing; on external displays it doubles as a centre
# keep-out so the strip never collides with the centred pomodoro/micromanager/
# gchat HUD. sketchybar doesn't report notch_width back, so it's mirrored here.
SCHED_NOTCH_MARGIN=110
SCHED_END_GAP=12          # breathing room before the computed limit
SCHED_START_FALLBACK=104  # strip left edge to assume if schedule.0 isn't drawn yet

# The strip is bounded on the right by whichever cluster is nearest.
# compute_avail_px queries these by name (one blob each, for bash-3.2 simplicity):
#   right cluster  — leftmost visible member is the obstacle: claude_usage is
#                    leftmost, cpu/clock are always-on fallbacks;
#   centre cluster — the focus HUD (pomodoro/micromanager) + gchat pills by the
#                    notch.

# Floored origin.x of item-JSON $1 on display key $2, or empty when the item is
# not drawn there (hidden items park at x=-9999).
_sched_origin_x() {
  [ -n "$1" ] || return 0
  printf '%s' "$1" | jq -r --arg d "$2" '
    (.bounding_rects[$d].origin[0] // -9999) | floor
    | if . > 0 then . else empty end' 2>/dev/null
}

# Smallest of the (possibly empty) integer args; empty if all are empty.
_sched_min() {
  local m="" v
  for v in "$@"; do
    [ -n "$v" ] || continue
    { [ -z "$m" ] || [ "$v" -lt "$m" ]; } && m="$v"
  done
  printf '%s' "$m"
}

# Pixel budget available to the strip = min over active displays of
#   (nearest right-obstacle x)  −  (strip start x)  −  gap
# where the right-obstacle is the closest of {notch/centre keep-out, right stats
# cluster, centre HUD}. Prints an integer; prints nothing (→ no width cap) if
# sketchybar can't be queried, so the plugin degrades to pool-only truncation.
compute_avail_px() {
  local displays
  displays="$(sketchybar --query displays 2>/dev/null)" || return 0
  [ -n "$displays" ] || return 0

  # Query each reference item once; extract per-display origins from the blobs.
  local j_sched0 j_usage j_cpu j_clock j_pomo j_mm j_ga j_gb
  j_sched0="$(sketchybar --query schedule.0 2>/dev/null)"
  j_usage="$(sketchybar --query claude_usage 2>/dev/null)"
  j_cpu="$(sketchybar --query cpu 2>/dev/null)"
  j_clock="$(sketchybar --query clock 2>/dev/null)"
  j_pomo="$(sketchybar --query pomodoro 2>/dev/null)"
  j_mm="$(sketchybar --query micromanager 2>/dev/null)"
  j_ga="$(sketchybar --query gchat.work-a 2>/dev/null)"
  j_gb="$(sketchybar --query gchat.work-b 2>/dev/null)"

  local best="" id dkey w center start rx cx limit budget
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    dkey="display-$id"
    w="$(printf '%s' "$displays" | jq -r --argjson id "$id" \
      '.[] | select(.["arrangement-id"] == $id) | .frame.w | floor')"
    [ -n "$w" ] || continue
    center=$((w / 2))

    start="$(_sched_origin_x "$j_sched0" "$dkey")"
    [ -n "$start" ] || start=$SCHED_START_FALLBACK
    rx="$(_sched_min "$(_sched_origin_x "$j_usage" "$dkey")" \
      "$(_sched_origin_x "$j_cpu" "$dkey")" "$(_sched_origin_x "$j_clock" "$dkey")")"
    cx="$(_sched_min "$(_sched_origin_x "$j_pomo" "$dkey")" \
      "$(_sched_origin_x "$j_mm" "$dkey")" "$(_sched_origin_x "$j_ga" "$dkey")" \
      "$(_sched_origin_x "$j_gb" "$dkey")")"

    limit=$((center - SCHED_NOTCH_MARGIN))
    [ -n "$rx" ] && [ "$rx" -lt "$limit" ] && limit=$rx
    [ -n "$cx" ] && [ "$cx" -lt "$limit" ] && limit=$cx

    budget=$((limit - start - SCHED_END_GAP))
    [ "$budget" -lt 0 ] && budget=0
    { [ -z "$best" ] || [ "$budget" -lt "$best" ]; } && best=$budget
  done <<EOF
$(printf '%s' "$displays" | jq -r '.[] | .["arrangement-id"]')
EOF

  printf '%s' "$best"
}

# Estimated rendered width (px) of segment index $1 (reads SCHED_SEGL). Every
# segment but index 0 carries a leading chevron.
_sched_seg_px() {
  local i="$1" len oh
  len=${#SCHED_SEGL[$i]}
  if [ "$i" -eq 0 ]; then oh=$SCHED_OH_FIRST; else oh=$SCHED_OH_CHEV; fi
  printf '%s' "$((oh + (len * SCHED_CHAR_T + 9) / 10))"
}

# How many leading segments fit in $1 px, reserving room for a "+N" slot when it
# must truncate. Always keeps at least 1. Reads SCHED_SEGL.
_sched_fit_count() {
  local avail="$1" total=${#SCHED_SEGL[@]} acc=0 i w keep=0
  for ((i = 0; i < total; i++)); do
    w="$(_sched_seg_px "$i")"
    [ "$((acc + w))" -gt "$avail" ] && break
    acc=$((acc + w))
    keep=$((keep + 1))
  done
  if [ "$keep" -lt "$total" ]; then
    while [ "$keep" -gt 1 ] && [ "$((acc + SCHED_PLUSN_W))" -gt "$avail" ]; do
      keep=$((keep - 1))
      acc=$((acc - $(_sched_seg_px "$keep")))
    done
  fi
  [ "$keep" -lt 1 ] && keep=1
  printf '%s' "$keep"
}

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
SCHED_FIRST_SEG=1 # 1 until the first segment is emitted (marks the leading meeting)

# Append one segment for the sweep span [s_start, s_end). idx == -1 -> a break
# (nothing ongoing); else event `idx`: GREEN with a countdown if the span covers
# now, TEXT if still to come. (Already-ended events are filtered out before the
# sweep, so the `past`/dim branch is just a guard and normally never fires.)
_sched_emit_span() {
  local idx="$1" s_start="$2" s_end="$3" now="$4" color state hhmm label
  # Is this the strip's leading segment? Consume the flag up front (breaks never
  # lead, but mark it seen regardless so only the true first event can be tagged).
  local is_first="$SCHED_FIRST_SEG"
  SCHED_FIRST_SEG=0
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
  if [ "$state" = current ]; then
    # Ongoing meeting: count down to its END.
    label="$label · $(fmt_dur $((s_end - now)))"
  elif [ "$state" = future ] && [ "$is_first" -eq 1 ]; then
    # Idle before the next meeting: the leading segment IS that meeting, so tag
    # it with a live countdown to its START. Together with the current-meeting
    # branch above this guarantees the strip always shows a countdown to the next
    # meeting — to the current one's end while you're in it, to the next one's
    # start while you're between meetings. Only the leading segment is tagged;
    # later meetings keep just their start clock time (their distance is
    # derivable and a countdown on every segment would clutter the strip).
    label="$label · in $(fmt_dur $((s_start - now)))"
  fi
  SCHED_SEGC+=("$color")
  SCHED_SEGL+=("$label")
  SCHED_SEGK+=("event")
}

# render_schedule NOW [AVAIL_PX]  (reads icalBuddy "<title>@@<HH:MM - HH:MM>"
# lines on stdin). AVAIL_PX (optional) is the pixel budget from compute_avail_px;
# when >0 the strip is truncated to fit it, else it falls back to the pool cap
# only (which also keeps this testable with fixtures — pass no AVAIL_PX).
# Emits, in strip order:
#   seg<TAB><chev 0|1><TAB><color><TAB><label>     one per visible segment
#   ctrl<TAB><used_count><TAB><update_freq>
render_schedule() {
  local now="$1" avail_px="${2:-}"
  SCHED_TITLES=()
  SCHED_STARTS=()
  SCHED_ENDS=()
  SCHED_SUMS=()
  SCHED_SEGC=()
  SCHED_SEGL=()
  SCHED_SEGK=()
  SCHED_FIRST_SEG=1

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

  # Truncate to (a) the pixel budget of the narrowest active display and (b) the
  # pool. Keep the leading segments that fit; collapse the rest into a "+N" slot
  # counting the dropped EVENT segments (breaks don't count). "+0" is never shown
  # — if only trailing breaks fall off, they're simply dropped.
  local total=${#SCHED_SEGC[@]} k chev keep dropped
  keep=$total
  if [ -n "$avail_px" ] && [ "$avail_px" -gt 0 ] 2>/dev/null; then
    keep="$(_sched_fit_count "$avail_px")"
  fi
  [ "$keep" -gt "$SCHED_POOL" ] && keep=$SCHED_POOL

  if [ "$keep" -lt "$total" ]; then
    # Truncated — reserve a slot for "+N" inside the pool, then collapse.
    [ "$keep" -ge "$SCHED_POOL" ] && keep=$((SCHED_POOL - 1))
    dropped=0
    for ((k = keep; k < total; k++)); do
      [ "${SCHED_SEGK[$k]}" = event ] && dropped=$((dropped + 1))
    done
    if [ "$dropped" -gt 0 ]; then
      SCHED_SEGC[$keep]="$OVERLAY0"
      SCHED_SEGL[$keep]="+$dropped"
      SCHED_SEGK[$keep]="more"
      total=$((keep + 1))
    else
      total=$keep # only trailing breaks fell off — no "+N" needed
    fi
  else
    # Everything fits — just don't dangle a trailing break segment.
    while [ "$total" -gt 1 ] && [ "${SCHED_SEGK[$((total - 1))]}" = break ]; do
      total=$((total - 1))
    done
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
  local now out avail
  now="$(/bin/date +%s)"
  # Live pixel budget for the strip (min across active displays); empty on query
  # failure, in which case render_schedule falls back to the pool cap only.
  avail="$(compute_avail_px)"
  # Fetch the WHOLE day, not just -n upcoming: a currently-ongoing meeting
  # started in the past, so we must see past-starting events too — render_schedule
  # keeps them by endtime and drops only the already-ended ones. -li 20 catches
  # overlaps; -ea skips all-day; -ic merges the SCHED_CALENDARS into one stream
  # (icalBuddy returns them sorted by start, which render_schedule then sweeps).
  out="$("$ICALBUDDY" -ic "$SCHED_CALENDARS" -ea -nc -npn -nrd -b '' -ps '|@@|' \
    -iep 'title,datetime' -df '%Y-%m-%d' -tf '%H:%M' -li 20 eventsToday \
    2>/dev/null | render_schedule "$now" "$avail")"
  apply_schedule "$out"
}

# Only run when executed by sketchybar (script=); stay inert when sourced by tests.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main; fi
