#!/bin/bash
# AeroSpace workspace history navigation — browser-/nvim-jumplist-style back &
# forward through the workspaces you've visited.
#
# AeroSpace has no native "history" navigation: `workspace-back-and-forth` only
# toggles the two most recent, and `workspace next|prev` walk workspaces in NAME
# order, not visit order. This script maintains the missing visit stack so that
# alt-shift-o (back) / alt-shift-i (forward) behave like nvim's <C-o>/<C-i>.
#
# Wiring (see ../aerospace.toml):
#   exec-on-workspace-change → this script `record "$AEROSPACE_FOCUSED_WORKSPACE"`
#   alt-shift-o              → this script `back`
#   alt-shift-i              → this script `forward`
#
# Model (browser semantics): `record` appends each newly-focused workspace to a
# stack and keeps a pointer at the current position. `back`/`forward` move the
# pointer and switch to that workspace. Focusing a NEW workspace while the
# pointer sits in the middle of the stack truncates the forward entries (you've
# branched), exactly like a web browser's history.
#
# The subtlety: `back`/`forward` switch workspaces, which fires
# exec-on-workspace-change → `record` again. Those self-induced records must NOT
# be treated as new branches. We can't infer that from the workspace id alone
# (rapid presses reorder the async callbacks), so each programmatic switch bumps
# a `pending` counter that `record` decrements-and-ignores. The count matches the
# number of switches regardless of callback ordering. Because consecutive stack
# entries always differ, every back/forward causes a real change → exactly one
# callback → the counter never leaks.
#
# Concurrency: the async record callback and a back/forward keypress can run at
# once, so all state mutations are serialised by an mkdir mutex (macOS has no
# flock). Writes are atomic (temp + mv). Two *manual* jumps fired within a few ms
# could still have their callbacks land out of order — worst case the recorded
# order is briefly wrong and self-heals on the next jump. Acceptable at human
# keypress rates.

AEROSPACE="/opt/homebrew/bin/aerospace"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/aerospace/wsnav"
HIST_FILE="$STATE_DIR/history"   # one workspace id per line — the visit stack
IDX_FILE="$STATE_DIR/index"      # 0-based pointer into history = current position
PENDING_FILE="$STATE_DIR/pending" # # of programmatic switches record must ignore
LOCK_DIR="$STATE_DIR/lock"       # mkdir-based mutex (atomic on macOS; no flock)
MAX=50                           # cap on retained history entries

mkdir -p "$STATE_DIR"

# --- mkdir mutex -----------------------------------------------------------
# mkdir is atomic, so a directory doubles as a lock. The holder stamps its
# acquire time inside the dir; a lock older than 5s is assumed orphaned (owner
# killed) and reclaimed — done via a timestamp file, NOT stat(1), because a GNU
# vs BSD stat on PATH would break `-f %m`. Contention is sub-millisecond, so the
# spin almost never loops; the 100-iteration cap is a last-resort backstop that
# proceeds best-effort rather than hanging a keypress.
lock() {
  local i=0 ts
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    ts=0
    [ -f "$LOCK_DIR/ts" ] && ts=$(cat "$LOCK_DIR/ts" 2>/dev/null || echo 0)
    case "$ts" in '' | *[!0-9]*) ts=0 ;; esac
    if [ $(($(date +%s) - ts)) -gt 5 ]; then
      rm -rf "$LOCK_DIR"
      continue
    fi
    i=$((i + 1))
    [ "$i" -gt 100 ] && return 0
    sleep 0.02
  done
  date +%s >"$LOCK_DIR/ts" 2>/dev/null || true
  return 0
}
unlock() { rm -rf "$LOCK_DIR"; }
# Safety net so a mid-script error never leaves a lock wedged (which would add a
# 5s stall to the next keypress). Explicit unlock() calls still release promptly.
trap 'rm -rf "$LOCK_DIR"' EXIT

# --- state I/O -------------------------------------------------------------
# Populates the `hist` array and `idx` from disk, clamping idx into range.
# Written for bash 3.2 (the /bin/bash AeroSpace invokes): no mapfile, no
# associative arrays, index loops only.
read_state() {
  hist=()
  if [ -f "$HIST_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      hist[${#hist[@]}]="$line"
    done <"$HIST_FILE"
  fi
  idx=-1
  [ -f "$IDX_FILE" ] && idx=$(cat "$IDX_FILE" 2>/dev/null || echo -1)
  case "$idx" in '' | *[!0-9-]*) idx=-1 ;; esac
  local n=${#hist[@]}
  if [ "$n" -eq 0 ]; then
    idx=-1
  elif [ "$idx" -lt 0 ]; then
    idx=0
  elif [ "$idx" -ge "$n" ]; then
    idx=$((n - 1))
  fi
}

# Atomically persists `hist` and `idx`.
write_state() {
  local tmp="$STATE_DIR/.hist.$$" n=${#hist[@]} i=0
  : >"$tmp"
  while [ "$i" -lt "$n" ]; do
    printf '%s\n' "${hist[$i]}" >>"$tmp"
    i=$((i + 1))
  done
  mv -f "$tmp" "$HIST_FILE"
  printf '%s\n' "$idx" >"$IDX_FILE"
}

read_pending() {
  pending=0
  [ -f "$PENDING_FILE" ] && pending=$(cat "$PENDING_FILE" 2>/dev/null || echo 0)
  case "$pending" in '' | *[!0-9]*) pending=0 ;; esac
}

# --- commands --------------------------------------------------------------
cmd_record() {
  local ws="$1"
  [ -z "$ws" ] && return 0
  lock
  read_pending
  # This change was our own back/forward — consume a token, leave history alone.
  if [ "$pending" -gt 0 ]; then
    printf '%s\n' "$((pending - 1))" >"$PENDING_FILE"
    unlock
    return 0
  fi
  read_state
  # Already sitting here (e.g. re-focus of the same workspace) — nothing to do.
  if [ "$idx" -ge 0 ] && [ "${hist[$idx]}" = "$ws" ]; then
    unlock
    return 0
  fi
  # Branch: keep 0..idx (drop any forward entries), then append ws as new head.
  local new=() i=0
  while [ "$i" -le "$idx" ] && [ "$i" -lt "${#hist[@]}" ]; do
    new[${#new[@]}]="${hist[$i]}"
    i=$((i + 1))
  done
  new[${#new[@]}]="$ws"
  hist=(${new[@]+"${new[@]}"})
  idx=$((${#hist[@]} - 1))
  # Cap length, trimming from the front and shifting idx to match.
  local n=${#hist[@]}
  if [ "$n" -gt "$MAX" ]; then
    local drop=$((n - MAX)) trimmed=()
    i=$drop
    while [ "$i" -lt "$n" ]; do
      trimmed[${#trimmed[@]}]="${hist[$i]}"
      i=$((i + 1))
    done
    hist=(${trimmed[@]+"${trimmed[@]}"})
    idx=$((idx - drop))
  fi
  write_state
  unlock
}

# Shared move: $1 = -1 for back, +1 for forward.
nav() {
  local dir="$1" target
  lock
  read_state
  local n=${#hist[@]} new=$((idx + dir))
  if [ "$new" -lt 0 ] || [ "$new" -ge "$n" ]; then
    unlock
    return 0 # nothing older/newer
  fi
  idx=$new
  target="${hist[$idx]}"
  # Tell `record` to ignore the switch we're about to cause.
  read_pending
  printf '%s\n' "$((pending + 1))" >"$PENDING_FILE"
  # Persist the moved pointer BEFORE switching so the async callback reads it.
  printf '%s\n' "$idx" >"$IDX_FILE"
  unlock
  "$AEROSPACE" workspace "$target"
}

case "${1:-}" in
record) cmd_record "${2:-}" ;;
back) nav -1 ;;
forward) nav 1 ;;
reset) rm -rf "$STATE_DIR" ;; # clear history (handy while tuning)
*)
  echo "usage: ${0##*/} {record <workspace>|back|forward|reset}" >&2
  exit 2
  ;;
esac
