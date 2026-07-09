# shellcheck shell=bash
# Right: network cluster — wired/Wi-Fi link info + live/peak throughput. Sourced
# by ../sketchybarrc. The live/peak readouts are passive (repainted by the stats
# controller, items/stats_controller.sh); the link glyphs are passive too, driven
# by the hidden network_link controller (../plugins/network_link.sh).
#
# The five items are added in an interleaved order so they stay one file: right
# region packs right→left (first-added is rightmost), so the add order below reads
# on screen (left→right) as:
#   Wi-Fi 5G | live up/down | peak up/down | [eth glyph]
# The link glyphs (wifi leftmost, eth rightmost) bracket the throughput readouts,
# so they can't be split into a separate file without reordering the cluster.

# Link info (Ethernet speed indicator; Wi-Fi band) plus the live/peak throughput
# readouts, grouped at the right edge of the stats block. The link items (eth,
# wifi) are passive: the hidden network_link controller repaints them and toggles
# each item's drawing by whether that interface is up (so an undocked laptop shows
# only Wi-Fi, a desktop on the dock shows both).
sketchybar --add item eth right \
  --set eth \
    drawing=off \
    icon=󰈁 \
    icon.color="$GREEN"

# Peak throughput since the connection last came up, one line "up/down" (dimmed),
# at the right edge beside the link glyph. net_peak is reset by network_link.sh
# when the connection identity changes. Label font is the bar default (13pt).
sketchybar --add item netpeak right \
  --set netpeak \
    icon.drawing=off \
    icon.padding_left=0 \
    icon.padding_right=0 \
    label.color="$SUBTEXT0"

# Live throughput, one line "up/down" (bright), between the link indicator and the
# peak. network, netpeak, disk and the cpu graph are all passive — the single
# stats controller (items/stats_controller.sh) repaints them per system_stats, so
# they carry no script of their own. stats.sh feeds the whole "up/down" string as
# the label.
sketchybar --add item network right \
  --set network \
    icon.drawing=off \
    icon.padding_left=0 \
    icon.padding_right=0 \
    label.color="$TEXT"

sketchybar --add item wifi right \
  --set wifi \
    drawing=off \
    icon=󰖩 \
    icon.color="$BLUE"

# system_profiler (the only non-root Wi-Fi source in macOS 26) costs ~6s, so the
# controller runs off the critical path on a slow 60s timer plus wifi_change and
# system_woke — link speed/band change on cable/roam/wake, not continuously.
sketchybar --add item network_link right \
  --set network_link \
    drawing=off \
    update_freq=60 \
    script="$PLUGIN_DIR/network_link.sh" \
  --subscribe network_link wifi_change system_woke
