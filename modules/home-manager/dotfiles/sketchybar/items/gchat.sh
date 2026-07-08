# shellcheck shell=bash
# Right: gchat. Sourced by ../sketchybarrc.
#
# Google Chat unread indicator across one or more Workspace accounts. The plugin
# (plugins/gchat.sh -> gchat.py) polls the Chat REST API per account: it lists
# spaces, compares each space's per-user read state against its newest message,
# and shows the count of unread conversations (per-account when there are two,
# e.g. "2·1"). Hidden while everything is read; shows "login" until you run
# `gchat-login <label>` for at least one account, "auth?" if every account fails.
#
# Clicking opens Google Chat in the browser. update_freq=60 is comfortably within
# the API's 3000-reads/min project quota even with hundreds of spaces.
sketchybar --add item gchat right \
  --set gchat \
    icon=󰭹 \
    icon.color="$TEXT" \
    drawing=off \
    update_freq=60 \
    click_script="open 'https://chat.google.com/'" \
    script="$PLUGIN_DIR/gchat.sh"
