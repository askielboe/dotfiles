# shellcheck shell=bash
# Right: Claude usage. Sourced by ../sketchybarrc.
#
# Claude 5-hour token window + extra-usage spend from /api/oauth/usage. The
# plugin owns the label: the 5-hour window as a percentage (e.g. "45%") and the
# pay-as-you-go spend appended only once it hits 100% (e.g. "100% €62"). When the
# label turns RED (5-hour ≥ 85%) it also appends an hourglass countdown to that
# window's reset (e.g. "92% 󰔟 2h13m"). It also refreshes the OAuth token in
# place. The glyph is pinned to PEACH (the Claude brand orange) at all times;
# only the label turns RED, and only when the 5-hour window runs high — so the
# chip stays calm and branded until it needs attention. The 7-day/weekly window
# is intentionally not shown.
# Stays hidden (drawing=off) until you run `claude-usage-login` once, and re-hides
# itself if auth ever breaks. update_freq=180 is the endpoint's safe poll rate.
sketchybar --add item claude_usage right \
  --set claude_usage \
    icon=󰛄 \
    icon.color="$PEACH" \
    drawing=off \
    update_freq=180 \
    script="$PLUGIN_DIR/claude-usage.sh"
