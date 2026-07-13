# shellcheck shell=bash
# Left: an AeroSpace binding-mode indicator. Hidden in 'main' mode; shown as a
# red "SERVICE" pill while in service mode. Service mode has no other visual cue,
# so it's easy to hit alt-shift-; and get silently stuck with every main-mode
# keybind dead until esc — this pill makes that state obvious.
#
# There is no runtime script here on purpose. AeroSpace's on-mode-changed
# callback does NOT expose the target mode (only window/workspace callbacks get
# env vars — see the AeroSpace guide), so the mode can't be derived at repaint
# time. Instead the aerospace.toml service-mode bindings toggle this item's
# `drawing` directly: the binding that ENTERS service does `--set aerospace_mode
# drawing=on`, and every binding that returns to main does `drawing=off`. Driving
# it from the bindings (rather than on-mode-changed + an explicit show) keeps it
# race-free: no two fire-and-forget sketchybar calls can reorder show/hide.
sketchybar --add item aerospace_mode left \
  --set aerospace_mode \
    drawing=off \
    icon=󰖷 \
    icon.color="$CRUST" \
    icon.padding_left=8 \
    icon.padding_right=4 \
    label="SERVICE" \
    label.color="$CRUST" \
    label.padding_left=2 \
    label.padding_right=8 \
    background.drawing=on \
    background.color="$RED" \
    background.corner_radius=6
