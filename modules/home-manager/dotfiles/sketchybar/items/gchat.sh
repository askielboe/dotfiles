# shellcheck shell=bash
# Right: gchat. Sourced by ../sketchybarrc.
#
# Google Chat unread indicator: a single 󰭹 icon followed by one clickable count
# per account, dot-separated — e.g. "󰭹 2·0". Each count is its own sketchybar
# item (gchat.<label>, one per ~/.local/state/gchat/<label>.json), so clicking a
# number opens *that* account (the poller sets its click_script to
# https://chat.google.com/?authuser=<email>; see plugins/gchat.py). A count is
# peach when that account has unread and dim grey at 0. "!" (red) means the
# account's token was rejected (re-run gchat-login); "?" is a transient blip. The
# dot separator is appended to each non-last count's label by the poller.
#
# The right region stacks first-added = rightmost, so to read "󰭹 a·b" left→right
# we add the counts in reverse (rightmost first) and the shared icon last
# (leftmost). Enumerated at bar load, so a new account needs a reload (`hs` does).
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/gchat"

labels=()
if [ -d "$state_dir" ]; then
  for f in "$state_dir"/*.json; do
    [ -e "$f" ] || continue # no matches -> literal glob, skip
    base="$(basename "$f" .json)"
    [ "$base" = "client" ] && continue # shared client creds, not an account
    labels+=("$base")
  done
fi

if [ "${#labels[@]}" -eq 0 ]; then
  # Nothing set up yet: a single "login" prompt until `gchat-login <label>` runs.
  sketchybar --add item gchat right \
    --set gchat \
      icon=󰭹 \
      icon.color="$TEXT" \
      drawing=off \
      update_freq=60 \
      click_script="open 'https://chat.google.com/'" \
      script="$PLUGIN_DIR/gchat.sh"
else
  # Counts, rightmost first (reverse of on-screen order); each self-polls its
  # own account. No icon on the counts — the shared 󰭹 is a separate item, added
  # last so it lands leftmost. Tight label padding keeps "N·M" reading as a unit.
  for ((i = ${#labels[@]} - 1; i >= 0; i--)); do
    label="${labels[$i]}"
    sketchybar --add item "gchat.$label" right \
      --set "gchat.$label" \
        icon.drawing=off \
        label=0 \
        label.color="$OVERLAY0" \
        label.padding_left=2 \
        label.padding_right=2 \
        drawing=on \
        update_freq=60 \
        click_script="open 'https://chat.google.com/'" \
        script="$PLUGIN_DIR/gchat.sh"
  done
  # Shared icon, leftmost (added last). Static: no script; clicking it opens the
  # default Chat account (the numbers are the per-account targets).
  sketchybar --add item gchat right \
    --set gchat \
      icon=󰭹 \
      icon.color="$TEXT" \
      icon.padding_right=3 \
      label.drawing=off \
      drawing=on \
      click_script="open 'https://chat.google.com/'"
fi
