# shellcheck shell=bash
# Right: network cluster — wired/Wi-Fi link info + live throughput. Sourced
# by ../sketchybarrc. The throughput readouts are passive (repainted by the stats
# controller, items/stats_controller.sh); the link glyphs are passive too, driven
# by the hidden network_link controller (../plugins/network_link.sh).
#
# Live throughput is a STACKED PAIR of log-scaled sparklines sharing one slot:
# upload (peach) on the top row, download (blue) on the bottom row, each with its
# current rate printed beside the trace (same graph+label idiom as claude_rate,
# items/claude_rate.sh). The two graph items are overlapped into one horizontal
# slot by y_offset (the vertical split) plus a negative padding on the top item
# (NET_OVERLAP below). The wifi/eth glyphs bracket the cluster.
#
# Items are added interleaved so the cluster stays one file: the right region
# packs right→left (first-added is rightmost), so the add order below reads on
# screen (left→right) as:
#   Wi-Fi 5G | [↑ spark 1.2M / ↓ spark 300K] | [eth glyph]

# Link info: Ethernet speed indicator (glyph only) — passive, toggled on/off by
# ../plugins/network_link.sh by whether a wired link is up.
sketchybar --add item eth right \
  --set eth \
    drawing=off \
    icon=󰈁 \
    icon.color="$GREEN"

# ---- Live throughput: stacked up/down sparklines -----------------------------
# net_down (bottom) + net_up (top) share one slot. The stats controller
# (../plugins/stats.sh) log-scales each live rate to 0..1 and --pushes it into
# each graph per system_stats event, and sets the rate labels (up→net_up top,
# down→net_down bottom); the graphs carry no script of their own.
# GEOMETRY IS PIXEL-TUNED — tweak these, `sketchybar --reload`, eyeball (measure
# with the screencapture+PIL workflow; see the reference_sketchybar_* memories).
NET_W=48                 # sparkline width in pt (≈ NET_W×5s ≈ 4min of history)
NET_H=13                 # per-row graph height; two rows stack in the 34pt bar
NET_YOFF=7               # vertical split from bar centre: +up row / −down row
NET_LW=34                # fixed rate-label width — keeps both rows the same width
                         #   so the overlap stays aligned as the numbers change
NET_FONT="Hack Nerd Font:Bold:9.0"
# The top row is pulled right by exactly one item width to land on top of the
# bottom row. Both rows are the same width (graph + fixed-width label), so this
# is NET_W + NET_LW. Verified with `sketchybar --query net_up`: with the item's
# padding_right at -NET_OVERLAP, net_up's origin equals net_down's (both 82pt
# wide, same x) — i.e. the two graphs share one slot. Must be the ITEM's
# padding_right, NOT label.padding_right (sketchybar clamps label padding to ≥0).
NET_OVERLAP=$(( NET_W + NET_LW ))

# Bottom row: download (cool/blue). Added first → anchors the slot's right edge.
sketchybar --add graph net_down right "$NET_W" \
  --set net_down \
    icon.drawing=off \
    graph.color="$BLUE" \
    graph.fill_color=0x2689b4fa \
    graph.line_width=2 \
    background.drawing=on \
    background.color=0x00000000 \
    background.height="$NET_H" \
    y_offset=-"$NET_YOFF" \
    label.font="$NET_FONT" \
    label.color="$TEXT" \
    label.width="$NET_LW" \
    label.align=right \
    label.padding_left=2 \
    label.padding_right=0

# Top row: upload (warm/peach). padding_right=-NET_OVERLAP pulls it right so it
# rides directly over net_down; +NET_YOFF raises it to the top row.
sketchybar --add graph net_up right "$NET_W" \
  --set net_up \
    icon.drawing=off \
    graph.color="$PEACH" \
    graph.fill_color=0x26fab387 \
    graph.line_width=2 \
    background.drawing=on \
    background.color=0x00000000 \
    background.height="$NET_H" \
    y_offset="$NET_YOFF" \
    label.font="$NET_FONT" \
    label.color="$TEXT" \
    label.width="$NET_LW" \
    label.align=right \
    label.padding_left=2 \
    label.padding_right=0 \
    padding_right=-"$NET_OVERLAP"

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
