# shellcheck shell=bash
# Right: system stats — network, disk, gpu, cpu graph + the controller that
# repaints them. Sourced by ../sketchybarrc; runtime repaint lives in
# ../plugins/stats.sh.

# cpu, disk and network are passive: a single controller below repaints all
# three per system_stats event, so they carry no script of their own.
sketchybar --add item network right \
  --set network \
    icon=󰛳 \
    icon.color="$LAVENDER"

sketchybar --add item disk right \
  --set disk \
    icon=󰋊 \
    icon.color="$YELLOW"

# The provider has no GPU stat; this one still polls ioreg.
sketchybar --add item gpu right \
  --set gpu \
    icon=󰢮 \
    icon.color="$TEAL" \
    update_freq=5 \
    script="$PLUGIN_DIR/gpu.sh"

# cpu is a graph, not a number: stats.sh pushes the current load (0–1) as a new
# data point per system_stats event. 40 points × 5s ≈ 3 min of scrolling history.
# No icon — the trace speaks for itself; the exact % label sits to its right.
# background.height (< bar height 34) insets the trace vertically, and the bar
# centres it, so the graph gets top/bottom padding; label.padding_left keeps the
# % off the trace.
sketchybar --add graph cpu right 40 \
  --set cpu \
    icon.drawing=off \
    graph.color="$PEACH" \
    graph.fill_color=0x30fab387 \
    graph.line_width=2 \
    background.height=16 \
    label.padding_left=10

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
