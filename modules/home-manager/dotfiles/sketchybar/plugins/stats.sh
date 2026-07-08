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
# active uplink carries traffic) and scale to M past 1024.
read -r down up <<<"$(env | awk -F= '
  function fmt(kbs) { return kbs >= 1024 ? sprintf("%.1fM", kbs / 1024) : kbs "K" }
  /^NETWORK_RX_/ { rx += $2 }
  /^NETWORK_TX_/ { tx += $2 }
  END { print fmt(rx), fmt(tx) }')"

sketchybar --set cpu graph.color="$cpu_color" \
    graph.fill_color="$cpu_fill" icon.color="$cpu_color" \
  --push cpu "$cpu_frac" \
  --set disk icon.color="$disk_color" label="${DISK_USAGE}%" \
  --set network label="↓${down} ↑${up}"
