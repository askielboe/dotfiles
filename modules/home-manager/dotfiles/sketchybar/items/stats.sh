# shellcheck shell=bash
# Right: system stats — network throughput, wired/Wi-Fi link info, disk, gpu,
# cpu graph + the controllers that repaint them. Sourced by ../sketchybarrc;
# runtime repaint lives in ../plugins/stats.sh and ../plugins/network_link.sh.

# Link info (Ethernet speed indicator; Wi-Fi band) plus the live/peak throughput
# readouts, grouped at the right edge of the stats block. The link items (eth,
# wifi) are passive: the hidden network_link controller repaints them and toggles
# each item's drawing by whether that interface is up (so an undocked laptop shows
# only Wi-Fi, a desktop on the dock shows both). Right region packs right→left
# (first-added is rightmost), so the add order below reads on screen (left→right)
# as:
#   Wi-Fi 5G | live up/down | peak up/down | [eth glyph]
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
# stats controller at the bottom repaints them per system_stats, so they carry no
# script of their own. stats.sh feeds the whole "up/down" string as the label.
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

sketchybar --add item disk right \
  --set disk \
    icon=󰋊 \
    icon.color="$YELLOW"

# The provider has no GPU stat; this graph still polls ioreg on its own timer.
# Same trace styling as the cpu graph below (icon to the left, no % label);
# gpu.sh pushes each utilisation reading as a new 0–1 data point.
sketchybar --add graph gpu right 52 \
  --set gpu \
    icon=󰢮 \
    icon.color="$TEAL" \
    label.drawing=off \
    graph.color="$TEAL" \
    graph.fill_color=0x3094e2d5 \
    graph.line_width=2 \
    background.drawing=on \
    background.color=0x00000000 \
    background.height=18 \
    update_freq=5 \
    script="$PLUGIN_DIR/gpu.sh"

# cpu is a graph, not a number: stats.sh pushes the current load (0–1) as a new
# data point per system_stats event. 52 points × 5s ≈ 4 min of scrolling history.
# An icon sits to the left of the trace; no % label — the trace speaks for itself.
# A graph fills the whole bar height by default; enabling a background (kept
# invisible via a fully-transparent colour) with a set height confines the trace
# to that shorter box, which the bar centres vertically → top/bottom padding.
# height 18 ≈ half the 34px bar (sketchybar's own dotfiles use 22 in a 40px bar).
sketchybar --add graph cpu right 52 \
  --set cpu \
    icon=󰻠 \
    icon.color="$PEACH" \
    label.drawing=off \
    graph.color="$PEACH" \
    graph.fill_color=0x30fab387 \
    graph.line_width=2 \
    background.drawing=on \
    background.color=0x00000000 \
    background.height=18

# Battery temperature as an ambient-heat gauge: "do I need to move into the
# shade?". The battery is a slow thermal mass tracking the enclosure/environment,
# so it rises with sun/ambient heat rather than workload (unlike the SoC die temp)
# — the honest signal for overheating from the surroundings. temp.sh reads it
# non-root from AppleSmartBattery via ioreg (same path as gpu.sh) and recolours a
# thermometer glyph green/yellow/red by Apple's thermal limits. Sourced last so it
# sits at the left edge of the stats cluster, next to the cpu graph. Battery temp
# drifts slowly, so a 30s timer suffices; system_woke refreshes it after sleep.
sketchybar --add item temp right \
  --set temp \
    icon=󰔏 \
    icon.color="$GREEN" \
    update_freq=30 \
    script="$PLUGIN_DIR/temp.sh" \
  --subscribe temp system_woke

# stats_provider (brew: joncrangle/tap/sketchybar-system-stats) pushes the
# system_stats event every 5s over mach messages — no polling processes.
# en0 = Wi-Fi, en17 = USB dock LAN; stats.sh sums whichever carries traffic.
# The provider runs as its own launchd agent (sketchybar-stats-provider in
# modules/darwin/settings/sketchybar.nix), NOT from here: a backgrounded
# child of this config script lives in sketchybar's KeepAlive process group
# and gets reaped when launchd bounces that job at login, silently killing
# the stats. A supervised agent survives login and restarts if it dies.
# The provider also registers the event itself, but only after it starts, so
# add it here first to keep the subscription order-independent.
sketchybar --add event system_stats

sketchybar --add item stats_controller right \
  --set stats_controller \
    drawing=off \
    script="$PLUGIN_DIR/stats.sh" \
  --subscribe stats_controller system_stats
