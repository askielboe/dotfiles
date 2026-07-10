# shellcheck shell=bash
# Launch wrapper for the sketchybar system-stats provider (see sketchybar.nix).
# No shebang/`set` line — writeShellApplication prepends both and lints the
# assembled script with shellcheck at build time (as with claude-usage-login.sh).
#
# stats_provider takes a fixed list of network interface names and ABORTS
# (exit 1) if any one of them doesn't exist. Hardcoding names is a trap on
# macOS: USB/dock Ethernet adapters re-enumerate to a fresh enN number after
# OS updates, NVRAM resets, or plugging a different adapter. When en17 (the old
# dock LAN) vanished, the provider died on startup and took the cpu/disk/network
# readouts with it (they're all fed by one system_stats event — see stats.sh).
#
# Instead of naming interfaces, discover every Ethernet-class interface (enN)
# that currently exists and hand the whole list to the provider. en0 (Wi-Fi) is
# always present, so the list is never empty. stats.sh sums NETWORK_RX_/TX_
# across whatever is passed and only the active uplink carries traffic, so idle
# adapters contribute 0 — passing extras is harmless and makes the readout
# follow the dock automatically. Re-resolved on every launchd (re)start.
#
# Absolute paths only: launchd agents get a minimal PATH.

ifaces=()
for ifc in $(/sbin/ifconfig -l); do
  case "$ifc" in
  en*) ifaces+=("$ifc") ;;
  esac
done

exec /opt/homebrew/bin/stats_provider \
  --cpu usage \
  --disk usage \
  --network "${ifaces[@]}" \
  --no-units
