# shellcheck shell=bash
# Left: AeroSpace workspaces + the controller that repaints them. Sourced by
# ../sketchybarrc; $AEROSPACE, $PLUGIN_DIR and the colour vars come from there.
# Runtime repaint logic lives in ../plugins/aerospace.sh.

# Fired by exec-on-workspace-change in aerospace.toml.
sketchybar --add event aerospace_workspace_change

# One item per workspace, hidden until the controller paints it. Each shows the
# workspace id (icon) plus a glyph per app in that workspace (label, rendered in
# sketchybar-app-font — the controller fills it in). The focused one gets a mauve
# background pill; other occupied ones a subtle surface pill. The numbered home
# row 1-9 always shows (a dim bare number, no pill/glyphs, when empty); letter
# workspaces only show when they hold a window or are focused (there are ~30
# persistent workspaces). label starts hidden so empty workspaces show only their
# id until painted.
# label.y_offset=-2: the id digit (Hack Nerd Font) and the app glyphs
# (sketchybar-app-font) have different font metrics. sketchybar centres each
# field on its own em box, but the app-font glyphs are top-heavy — their ink sits
# in the upper part of the box — so at y_offset=0 their optical centre lands ~2.5px
# ABOVE the digit's and the glyphs visibly float above the row. Aligning the
# BASELINES (bottoms) doesn't fix this: the glyphs are taller, so equal bottoms
# still leave their centre high. Instead nudge ONLY the label (glyphs) DOWN 2pt so
# its optical centre meets the digit's, which already sits at the pill centre
# (measured: digit centre y≈33.5, glyph centre 30 -> 34). Leave the icon at the
# default y_offset=0.
for ws in $("$AEROSPACE" list-workspaces --all); do
  sketchybar --add item space."$ws" left \
    --set space."$ws" \
      drawing=off \
      icon="$ws" \
      icon.padding_left=8 \
      icon.padding_right=4 \
      label.font="sketchybar-app-font:Regular:15.0" \
      label.drawing=off \
      label.y_offset=-2 \
      label.padding_left=2 \
      label.padding_right=8 \
      click_script="$AEROSPACE workspace $ws"
done

# A single hidden controller repaints all workspace items in one call;
# per-item scripts would spawn ~30 processes per workspace switch.
# space_windows_change catches windows being created, destroyed or moved between
# workspaces (changing which ones are non-empty), which fires no aerospace event.
sketchybar --add item space_controller left \
  --set space_controller \
    drawing=off \
    script="$PLUGIN_DIR/aerospace.sh" \
  --subscribe space_controller aerospace_workspace_change space_windows_change
