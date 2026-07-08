# shellcheck shell=bash
# Right: Claude usage. Sourced by ../sketchybarrc.
#
# Claude 5h / 7d token windows + extra-usage spend from /api/oauth/usage. The
# plugin owns the icon, label and colour (severity of the most-binding window)
# and refreshes the OAuth token in place. Shows "login" until you run
# `claude-usage-login` once. update_freq=180 is the endpoint's safe poll rate.
sketchybar --add item claude_usage right \
  --set claude_usage \
    icon=󰛄 \
    icon.color="$MAUVE" \
    drawing=off \
    update_freq=180 \
    script="$PLUGIN_DIR/claude-usage.sh"
