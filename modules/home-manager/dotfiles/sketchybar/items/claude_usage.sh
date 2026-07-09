# shellcheck shell=bash
# Right: Claude usage. Sourced by ../sketchybarrc.
#
# Claude 5h / 7d token windows + extra-usage spend from /api/oauth/usage. The
# plugin owns the label: the 7-day window as a filling pie-ring, the 5-hour
# window as a percentage beside it (e.g. "󰪡 45%"), and the pay-as-you-go spend
# appended only once a window hits 100% (e.g. "󰪥 100% €62"). It also refreshes
# the OAuth token in place. The glyph is pinned to PEACH (the Claude brand
# orange) at all times; only the label turns RED, and only when the most-binding
# window runs high — so the chip stays calm and branded until it needs attention.
# Shows "login" until you run `claude-usage-login` once. update_freq=180 is the
# endpoint's safe poll rate.
sketchybar --add item claude_usage right \
  --set claude_usage \
    icon=󰛄 \
    icon.color="$PEACH" \
    drawing=off \
    update_freq=180 \
    script="$PLUGIN_DIR/claude-usage.sh"
