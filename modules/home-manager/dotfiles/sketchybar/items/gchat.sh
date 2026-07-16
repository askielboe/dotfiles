# shellcheck shell=bash
# Centre (position "q", native left-of-notch): gchat unread pills. Sourced by
# ../sketchybarrc, LAST in the q block so it sits flush against the notch — i.e.
# centre — and stays put when the transient focus HUD (pomodoro/micromanager,
# also in q) appears to its left.
#
# Google Chat unread indicator: a shared 󰭹 icon followed by one clickable count
# per account — e.g. "󰭹 2 0". Each count is its own sketchybar item
# (gchat.<label>, one per ~/.local/state/gchat/<label>.json), so clicking a number
# opens *that* account (the poller sets its click_script to
# https://chat.google.com/?authuser=<email>; see plugins/gchat.py).
#
# Look: an account with unread renders as a filled PILL — peach background, dark
# (CRUST) count — so new messages read at a glance; an all-read account is a dim,
# pill-less 0. "!" is a red pill (token rejected -> re-run gchat-login); "?" is a
# dim transient network blip. The pill geometry (corner_radius/height) is set here;
# plugins/gchat.py only toggles background.drawing + the colours each poll.
#
# The q region stacks first-added = leftmost (last-added = flush against the
# notch). We add the shared icon first (leftmost) then the counts in order, so the
# row reads "󰭹 a b" left→right. Enumerated at bar load, so a new account needs a
# reload (`hs` does).
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
  sketchybar --add item gchat q \
    --set gchat \
      icon=󰭹 \
      icon.color="$TEXT" \
      drawing=off \
      update_freq=60 \
      click_script="open 'https://chat.google.com/'" \
      script="$PLUGIN_DIR/gchat.sh"
else
  # Shared icon, leftmost (added first). Static: no script; clicking it opens the
  # default Chat account (the numbers are the per-account targets).
  sketchybar --add item gchat q \
    --set gchat \
      icon=󰭹 \
      icon.color="$TEXT" \
      icon.padding_right=4 \
      label.drawing=off \
      drawing=on \
      click_script="open 'https://chat.google.com/'"
  # Counts in on-screen order (left → right); each self-polls its own account. No
  # icon on the counts — the shared 󰭹 is a separate item, added first so it lands
  # leftmost. Pill geometry lives here (rounded, 18px tall); the poller flips
  # background.drawing on for the unread/error states and off when all-read. Label
  # padding is the pill's inner padding, held constant so 0<->pill doesn't reflow.
  for ((i = 0; i < ${#labels[@]}; i++)); do
    label="${labels[$i]}"
    sketchybar --add item "gchat.$label" q \
      --set "gchat.$label" \
        icon.drawing=off \
        label=0 \
        label.color="$OVERLAY0" \
        label.padding_left=6 \
        label.padding_right=6 \
        background.corner_radius=9 \
        background.height=18 \
        background.drawing=off \
        drawing=on \
        update_freq=60 \
        click_script="open 'https://chat.google.com/'" \
        script="$PLUGIN_DIR/gchat.sh"
  done
fi
