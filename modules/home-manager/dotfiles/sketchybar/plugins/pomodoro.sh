#!/bin/bash
# Center "current focus" item, backed by openpomodoro-cli.
#
# `pomodoro status` prints an empty line when nothing is running and
# "<time>  <description>" while a Pomodoro is active. The CLI's start/stop
# hooks (~/.pomodoro/hooks, nix-managed) fire the pomodoro_update event this
# item subscribes to, so it wakes instantly on start/finish/cancel. It only
# self-clocks (update_freq=1) while active — idle costs zero polling.
#
# Start one from anywhere with:  pomodoro start "What I'm working on"

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

line="$(pomodoro status -f '%!r  %d')"

if [ -z "$line" ]; then
  # Idle: hide and stop the per-second clock until a start hook wakes us.
  sketchybar --set "$NAME" drawing=off update_freq=0
  exit 0
fi

# A trailing '!' on the time (from %!r) means the Pomodoro has run out.
color="$PEACH"
case "$line" in
*'!'*) color="$RED" ;;
esac

sketchybar --set "$NAME" \
  drawing=on \
  update_freq=1 \
  icon.color="$color" \
  label="$line"
