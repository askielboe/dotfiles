# shellcheck shell=bash
# Left: AeroSpace workspaces + the controller that repaints them. Sourced by
# ../sketchybarrc; $AEROSPACE, $PLUGIN_DIR and the colour vars come from there.
# Runtime repaint logic lives in ../plugins/aerospace.sh.

# Fired by exec-on-workspace-change in aerospace.toml.
sketchybar --add event aerospace_workspace_change

# One item per workspace, hidden until the controller paints it. Each shows the
# workspace id; the focused one is accent-coloured. Only the focused and
# non-empty workspaces are drawn (there are ~30 persistent ones).
for ws in $("$AEROSPACE" list-workspaces --all); do
  sketchybar --add item space."$ws" left \
    --set space."$ws" \
      drawing=off \
      icon="$ws" \
      icon.padding_left=8 \
      icon.padding_right=8 \
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
