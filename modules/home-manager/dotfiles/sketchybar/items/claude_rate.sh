# shellcheck shell=bash
# Right: live Claude output-token throughput. Sourced by ../sketchybarrc.
#
# Rolling 60s burn rate (output tokens/s) read from the local ~/.claude session
# logs, drawn as a cpu-style graph with the current rate as its label. Runtime
# poll lives in ../plugins/claude-rate.sh. Sits beside claude_usage so the two
# form one "Claude" cluster: usage = how much of the window is spent (180s
# network poll), rate = how fast right now (5s local poll). The glyph and trace
# are PEACH (the Claude brand orange) to match claude_usage; they dim to
# OVERLAY0 when idle and turn RED at full scale.
#
# Unlike the cpu/gpu graphs (which hide their label), this one keeps the label
# on to show the "N/s" number next to the sparkline.
sketchybar --add graph claude_rate right 40 \
  --set claude_rate \
    icon=󰓅 \
    icon.color="$PEACH" \
    label.font="Hack Nerd Font:Regular:11.0" \
    label.color="$PEACH" \
    graph.color="$PEACH" \
    graph.fill_color=0x30fab387 \
    graph.line_width=2 \
    background.drawing=on \
    background.color=0x00000000 \
    background.height=18 \
    update_freq=5 \
    script="$PLUGIN_DIR/claude-rate.sh"
