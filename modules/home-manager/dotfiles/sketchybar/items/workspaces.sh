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
# label.y_offset=-2: the id digit (Hack Nerd Font) and the app glyph
# (sketchybar-app-font) have different font metrics — the app-font glyph is
# top-heavy (its ink sits high in the em box), so at y_offset=0 it floats ~2px
# above the digit. Nudge only the label (glyph) down 2pt so its optical centre
# meets the digit's, which already sits at the pill centre.
sketchybar --add item space left \
  --set space \
    icon.font="Hack Nerd Font:Bold:14.0" \
    icon.color="$CRUST" \
    icon.padding_left=8 \
    icon.padding_right=4 \
    label.font="sketchybar-app-font:Regular:15.0" \
    label.color="$CRUST" \
    label.y_offset=-2 \
    label.padding_left=2 \
    label.padding_right=8 \
    background.drawing=on \
    background.color="$MAUVE" \
    background.corner_radius=6 \
    script="$PLUGIN_DIR/aerospace.sh" \
  --subscribe space aerospace_workspace_change front_app_switched
