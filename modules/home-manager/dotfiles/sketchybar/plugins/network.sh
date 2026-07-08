#!/bin/bash
# Up/down throughput on the default-route interface, from link-level byte
# counter deltas between runs (state file keyed by interface, so switching
# between Wi-Fi and Ethernet just resets the sample).

iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
if [ -z "$iface" ]; then
  sketchybar --set "$NAME" label="offline"
  exit 0
fi

read -r rx tx <<<"$(netstat -ibn -I "$iface" | awk '/<Link#/{print $7, $10; exit}')"
now="$(date +%s)"

state="${TMPDIR:-/tmp}/sketchybar_net_${iface}"
prev_t=0 prev_rx=0 prev_tx=0
[ -f "$state" ] && read -r prev_t prev_rx prev_tx <"$state"
printf '%s %s %s\n' "$now" "$rx" "$tx" >"$state"

dt=$((now - prev_t))
# No usable previous sample (first run, counter reset, clock jump): skip once.
if [ "$prev_t" -eq 0 ] || [ "$dt" -le 0 ] || [ "$rx" -lt "$prev_rx" ] || [ "$tx" -lt "$prev_tx" ]; then
  sketchybar --set "$NAME" label="↓ -- ↑ --"
  exit 0
fi

fmt() {
  awk -v b="$1" 'BEGIN {
    if (b >= 1048576) printf "%.1fM", b / 1048576
    else if (b >= 1024) printf "%.0fK", b / 1024
    else printf "%dB", b
  }'
}

down="$(fmt $(((rx - prev_rx) / dt)))"
up="$(fmt $(((tx - prev_tx) / dt)))"

sketchybar --set "$NAME" label="↓${down} ↑${up}"
