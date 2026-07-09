#!/bin/bash
# Repaints the cpu, disk and network items from one system_stats event,
# pushed every 5s over mach messages by stats_provider (brew:
# joncrangle/tap/sketchybar-system-stats), run as the sketchybar-stats-provider
# launchd agent (modules/darwin/settings/sketchybar.nix).
# One script call per event instead of three polled plugins. GPU is not
# covered by the provider and stays in gpu.sh.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

[ -z "$CPU_USAGE" ] && exit 0

cpu_color="$PEACH"
cpu_fill=0x30fab387
if [ "$CPU_USAGE" -ge 80 ]; then
  cpu_color="$RED"
  cpu_fill=0x30f38ba8
fi

# Normalise the whole-percent load to the 0–1 range the graph plots.
cpu_frac="$(awk "BEGIN { printf \"%.3f\", $CPU_USAGE / 100 }")"

disk_color="$YELLOW"
[ "$DISK_USAGE" -ge 95 ] && disk_color="$RED"

# The provider reports whole KB/s per watched interface; sum them (only the
# active uplink carries traffic). Keep the raw KB sums so the same numbers feed
# both the live readout and the wired peak tracker below.
read -r rx tx <<<"$(env | awk -F= '
  /^NETWORK_RX_/ { rx += $2 }
  /^NETWORK_TX_/ { tx += $2 }
  END { printf "%d %d", rx, tx }')"

# Live rate → compact bytes label: whole K under 1 MB/s, one decimal M past it.
fmt_kbs() { awk -v k="$1" 'BEGIN { if (k >= 1024) printf "%.1fM", k / 1024; else printf "%dK", k }'; }
# Peak rate → floored bit rate (Kbit/Mbit/Gbit, decimal): peaks are shown in bits
# so they read against the negotiated wired link speed, floored to whole units.
fmt_bits() { awk -v k="$1" 'BEGIN {
  b = k * 8
  if (b >= 1000000) printf "%dG", int(b / 1000000)
  else if (b >= 1000) printf "%dM", int(b / 1000)
  else printf "%dK", int(b)
}'; }
down="$(fmt_kbs "$rx")"
up="$(fmt_kbs "$tx")"

# Throughput peak (floored, in bits) shown in parentheses beside each live rate.
# Fold the current rates into the running max(rx)/max(tx); network_link.sh zeroes
# net_peak whenever the connection changes, so this is the peak since the network
# last connected. Offline the rates are ~0, so the peak just holds until reset.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar"
mkdir -p "$STATE_DIR"
read -r pk_rx pk_tx <<<"$(cat "$STATE_DIR/net_peak" 2>/dev/null)"
pk_rx=${pk_rx:-0}
pk_tx=${pk_tx:-0}
[ "$rx" -gt "$pk_rx" ] && pk_rx=$rx
[ "$tx" -gt "$pk_tx" ] && pk_tx=$tx
printf '%s %s\n' "$pk_rx" "$pk_tx" >"$STATE_DIR/net_peak"
peak_down="$(fmt_bits "$pk_rx")"
peak_up="$(fmt_bits "$pk_tx")"

# Feed the single-line network items (see items/network.sh): live "up/down" in
# network (bright), peak-since-connect "up/down" in netpeak (dimmed), each as one
# label with a slash between the two rates.
sketchybar --set cpu graph.color="$cpu_color" \
    graph.fill_color="$cpu_fill" icon.color="$cpu_color" \
  --push cpu "$cpu_frac" \
  --set disk icon.color="$disk_color" label="${DISK_USAGE}%" \
  --set network label="${up}/${down}" \
  --set netpeak label="${peak_up}/${peak_down}"
