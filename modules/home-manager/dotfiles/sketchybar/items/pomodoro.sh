# shellcheck shell=bash
# Center: current focus / pomodoro. Sourced by ../sketchybarrc.
#
# Backed by openpomodoro-cli (on the agent's PATH via services.sketchybar
# .extraPackages). `pomodoro start "task"` sets the label + a 25-min countdown;
# the CLI's start/stop hooks (~/.pomodoro/hooks, nix-managed) fire this event so
# the item wakes instantly. pomodoro.sh flips update_freq, so it only ticks (1s)
# while a Pomodoro runs — idle costs no polling. Left-click finishes the
# Pomodoro (counts it toward the daily goal); right-click cancels it.
sketchybar --add event pomodoro_update

sketchybar --add item pomodoro center \
  --set pomodoro \
    icon=󰔟 \
    icon.color="$PEACH" \
    drawing=off \
    update_freq=0 \
    script="$PLUGIN_DIR/pomodoro.sh" \
    click_script='if [ "$BUTTON" = "right" ]; then pomodoro cancel; else pomodoro finish; fi' \
  --subscribe pomodoro pomodoro_update
