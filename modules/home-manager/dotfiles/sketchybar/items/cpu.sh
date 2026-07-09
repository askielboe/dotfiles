# shellcheck shell=bash
# Right: cpu load graph — passive, repainted by the stats controller
# (items/stats_controller.sh + ../plugins/stats.sh). Sourced by ../sketchybarrc.
#
# cpu is a graph, not a number: plugins/stats.sh pushes the current load (0–1) as
# a new data point per system_stats event. 52 points × 5s ≈ 4 min of scrolling
# history. An icon sits to the left of the trace; no % label — the trace speaks
# for itself. A graph fills the whole bar height by default; enabling a background
# (kept invisible via a fully-transparent colour) with a set height confines the
# trace to that shorter box, which the bar centres vertically → top/bottom
# padding. height 18 ≈ half the 34px bar (sketchybar's own dotfiles use 22 in a
# 40px bar).
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
