# shellcheck shell=bash
# Left: AeroSpace workspaces + per-window glyph pool + the controller that
# repaints them. Sourced by ../sketchybarrc; $AEROSPACE, $PLUGIN_DIR and the
# colour vars come from there. Runtime repaint logic lives in
# ../plugins/aerospace.sh.

# Fired by exec-on-workspace-change in aerospace.toml.
sketchybar --add event aerospace_workspace_change

# One item per workspace, hidden until the controller paints it. Each shows the
# workspace id; the focused one is accent-coloured (the per-window app glyphs
# live in the win.* pool below). Only the focused and non-empty workspaces are
# drawn (there are ~30 persistent ones).
for ws in $("$AEROSPACE" list-workspaces --all); do
  sketchybar --add item space."$ws" left \
    --set space."$ws" \
      drawing=off \
      icon="$ws" \
      icon.padding_left=8 \
      icon.padding_right=8 \
      click_script="$AEROSPACE workspace $ws"
done

# A fixed pool of window items. On each repaint the controller fills win.1..N
# with one sketchybar-app-font glyph per window in the FOCUSED workspace,
# highlights the focused window's glyph, hides the rest, and --moves the pool to
# sit right after the focused workspace item. A fixed pool (vs. dynamic
# --add/--remove) keeps the single-repaint model and avoids item churn. 16
# covers any realistic accordion depth; windows beyond that are not shown.
# icon.y_offset nudges the app-font glyphs down to vertical centre.
for i in {1..16}; do
  sketchybar --add item win."$i" left \
    --set win."$i" \
      drawing=off \
      icon.font="sketchybar-app-font:Regular:15.0" \
      icon.y_offset=-1 \
      icon.padding_left=4 \
      icon.padding_right=4 \
      label.drawing=off \
      background.corner_radius=6 \
      background.height=20 \
      background.drawing=off
done

# A single hidden controller repaints all workspace items in one call;
# per-item scripts would spawn ~30 processes per workspace switch.
# front_app_switched and space_windows_change catch windows being created,
# destroyed or moved between workspaces, which fire no aerospace event.
sketchybar --add item space_controller left \
  --set space_controller \
    drawing=off \
    script="$PLUGIN_DIR/aerospace.sh" \
  --subscribe space_controller aerospace_workspace_change front_app_switched space_windows_change
