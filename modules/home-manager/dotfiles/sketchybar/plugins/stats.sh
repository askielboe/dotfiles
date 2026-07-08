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
[ "$CPU_USAGE" -ge 80 ] && cpu_color="$RED"

disk_color="$YELLOW"
[ "$DISK_USAGE" -ge 95 ] && disk_color="$RED"

# The provider reports whole KB/s per watched interface; sum them (only the
# active uplink carries traffic) and scale to M past 1024.
read -r down up <<<"$(env | awk -F= '
  function fmt(kbs) { return kbs >= 1024 ? sprintf("%.1fM", kbs / 1024) : kbs "K" }
  /^NETWORK_RX_/ { rx += $2 }
  /^NETWORK_TX_/ { tx += $2 }
  END { print fmt(rx), fmt(tx) }')"

sketchybar --set cpu icon.color="$cpu_color" label="${CPU_USAGE}%" \
  --set disk icon.color="$disk_color" label="${DISK_USAGE}%" \
  --set network label="↓${down} ↑${up}"
