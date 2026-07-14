# shellcheck shell=bash
# Left: AeroSpace workspaces + the controller that repaints them. Sourced by
# ../sketchybarrc; $AEROSPACE, $PLUGIN_DIR and the colour vars come from there.
# Runtime repaint logic lives in ../plugins/aerospace.sh.

# Fired by exec-on-workspace-change in aerospace.toml.
sketchybar --add event aerospace_workspace_change

# One item per workspace, hidden until the controller paints it. Each shows the
# workspace id (icon) plus a glyph per app in that workspace (label, rendered in
# sketchybar-app-font — the controller fills it in). The focused one gets a mauve
# background pill; other non-empty ones a subtle surface pill; empty ones are
# hidden (there are ~30 persistent workspaces). label starts hidden so empty
# workspaces show nothing until painted.
# icon.y_offset=-1: the id digit (Hack Nerd Font) and the app glyphs
# (sketchybar-app-font) have different font metrics, so at the same offset the
# digit's baseline lands ~1.5px above the glyphs' — the key visibly floats above
# the row. Nudge ONLY the icon down 1pt so the two baselines line up (measured:
# digit bottom 43 -> 45 vs glyph bottom 44-45). Do NOT also offset the label:
# moving both together just shifts the whole pill and leaves the gap unchanged.
for ws in $("$AEROSPACE" list-workspaces --all); do
  sketchybar --add item space."$ws" left \
    --set space."$ws" \
      drawing=off \
      icon="$ws" \
      icon.padding_left=8 \
      icon.padding_right=4 \
      icon.y_offset=-1 \
      label.font="sketchybar-app-font:Regular:15.0" \
      label.drawing=off \
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
