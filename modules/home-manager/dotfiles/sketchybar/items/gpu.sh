# shellcheck shell=bash
# Right: gpu utilisation graph. Sourced by ../sketchybarrc.
#
# The stats provider has no GPU stat; this graph self-polls ioreg on its own timer
# via ../plugins/gpu.sh (unlike the cpu graph, which the stats controller feeds).
# Same trace styling as the cpu graph (items/cpu.sh): icon to the left, no % label;
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
