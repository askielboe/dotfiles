# shellcheck shell=bash
# Left: a SINGLE pill showing the focused AeroSpace workspace id (icon) plus the
# focused app's glyph (label, sketchybar-app-font) — nothing else. This replaces
# the former ~30-item per-workspace strip. Runtime repaint lives in
# ../plugins/aerospace.sh; $AEROSPACE, $PLUGIN_DIR and the colour vars come from
# ../sketchybarrc.

# Fired by exec-on-workspace-change in aerospace.toml.
sketchybar --add event aerospace_workspace_change

# The pill repaints on workspace switch (aerospace_workspace_change) AND on app
# switch (front_app_switched, a sketchybar built-in) so the app glyph tracks the
# frontmost app even when the workspace doesn't change.
#
# label.y_offset=2: the id digit (Hack Nerd Font) and the app glyph
# (sketchybar-app-font) have different font metrics. The app-font glyph sits LOW
# in its em box, so when the label is centred by its line metrics the glyph's
# optical centre lands below the digit's (which is dead-centre in the pill).
# Measured live (screencapture + bbox optical centre, digit as reference): at
# y_offset=0 the glyph sits ~2.5px low and at the old -2 it sagged ~4.5px; +2
# brings its centre to within 0.5px of the digit's. Positive y_offset = up (see
# apple.sh). Value derived empirically by sweeping -2..4 — do not "correct" the
# sign back to negative, that was the original bug.
sketchybar --add item space left \
  --set space \
    icon.font="Hack Nerd Font:Bold:14.0" \
    icon.color="$CRUST" \
    icon.padding_left=8 \
    icon.padding_right=4 \
    label.font="sketchybar-app-font:Regular:15.0" \
    label.color="$CRUST" \
    label.y_offset=2 \
    label.padding_left=2 \
    label.padding_right=8 \
    background.drawing=on \
    background.color="$MAUVE" \
    background.corner_radius=6 \
    script="$PLUGIN_DIR/aerospace.sh" \
  --subscribe space aerospace_workspace_change front_app_switched
