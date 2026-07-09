# shellcheck shell=bash
# Right: battery temperature gauge. Sourced by ../sketchybarrc, last of the visible
# stats items so it sits at the left edge of the cluster, next to the cpu graph.
#
# Battery temperature as an ambient-heat gauge: "do I need to move into the
# shade?". The battery is a slow thermal mass tracking the enclosure/environment,
# so it rises with sun/ambient heat rather than workload (unlike the SoC die temp)
# — the honest signal for overheating from the surroundings. temp.sh reads it
# non-root from AppleSmartBattery via ioreg (same path as gpu.sh) and recolours a
# thermometer glyph green/yellow/red by Apple's thermal limits. Battery temp
# drifts slowly, so a 30s timer suffices; system_woke refreshes it after sleep.
sketchybar --add item temp right \
  --set temp \
    icon=󰔏 \
    icon.color="$GREEN" \
    update_freq=30 \
    script="$PLUGIN_DIR/temp.sh" \
  --subscribe temp system_woke
