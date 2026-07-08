#!/bin/bash
# Paints the wired + Wi-Fi link-info items: the negotiated Ethernet link speed
# and the Wi-Fi band + transmit (link) rate. Driven by the hidden network_link
# controller (items/stats.sh) on a 60s timer plus wifi_change/system_woke, since
# link speed and band change only on cable/roam/wake, not continuously.
#
# The SSID is deliberately not shown: macOS 26 redacts it to "<redacted>" for
# any process without Location Services authorisation, and a sketchybar plugin
# spawned by launchd has none. Band + rate carry no such gate.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

# Mb/s → compact label: 1000→1G, 2500→2.5G, 100→100M, 1200→1.2G.
fmt_mbit() {
  awk -v m="$1" 'BEGIN {
    if (m >= 1000) { v = m / 1000; printf (v == int(v) ? "%dG" : "%.1fG"), v }
    else printf "%dM", m
  }'
}

# ---- Ethernet: first active interface negotiating a wired media speed --------
# Wi-Fi reports `media: autoselect` with no baseT token; a wired link reports
# e.g. `media: autoselect (1000baseT <full-duplex>)`. The presence of a
# baseT/baseSX speed token is what tells wired apart from Wi-Fi, and its leading
# number is the negotiated Mb/s. Inactive adapters (no cable) are skipped.
eth_speed=""
for ifc in $(ifconfig -l); do
  case "$ifc" in en*) ;; *) continue ;; esac
  info="$(ifconfig "$ifc" 2>/dev/null)"
  [[ "$info" == *"status: active"* ]] || continue
  mbit="$(sed -n 's/.*media:.*(\([0-9]*\)base[A-Z].*/\1/p' <<<"$info" | head -1)"
  [ -n "$mbit" ] && { eth_speed="$mbit"; break; }
done

if [ -n "$eth_speed" ]; then
  sketchybar --set eth drawing=on label="$(fmt_mbit "$eth_speed")"
else
  sketchybar --set eth drawing=off
fi

# ---- Wi-Fi: band + transmit rate, only when associated -----------------------
# The `airport` CLI is gone in macOS 26 and wdutil/ipconfig need root for these
# fields, so system_profiler is the only non-root source — but it costs ~6s, so
# only pay it when the radio is actually up. Its output can hold two "Current
# Network Information" blocks; take the first (the associated network) and stop
# at Transmit Rate.
wifi_if="$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2; exit}')"
: "${wifi_if:=en0}"

if ifconfig "$wifi_if" 2>/dev/null | grep -q "status: active"; then
  air="$(system_profiler SPAirPortDataType 2>/dev/null \
    | awk '/Current Network Information:/{f=1} f; /Transmit Rate:/{if(f)exit}')"
  band="$(sed -n 's/.*Channel: [0-9]* (\([0-9.]*\)GHz.*/\1G/p' <<<"$air" | head -1)"
  rate="$(sed -n 's/.*Transmit Rate: \([0-9]*\).*/\1/p' <<<"$air" | head -1)"

  if [ -n "$band" ] || [ -n "$rate" ]; then
    label="$band"
    [ -n "$rate" ] && label="${label:+$label }$(fmt_mbit "$rate")"
    sketchybar --set wifi drawing=on label="$label"
  else
    sketchybar --set wifi drawing=off
  fi
else
  sketchybar --set wifi drawing=off
fi
