# shellcheck shell=bash
# Far-left green Apple logo with a click popup (Preferences / Activity / Lock
# Screen), echoing the SketchyBar example. Sourced first in the left region by
# ../sketchybarrc; colour vars come from there. The glyph is nf-fa-apple in Hack
# Nerd Font. Lock uses `pmset displaysleepnow` (CGSession's lock path was removed
# on modern macOS) — it locks when "require password after sleep" is set, which
# it effectively always is.

sketchybar --add item apple left \
  --set apple \
    icon="" \
    icon.font="Hack Nerd Font:Bold:16.0" \
    icon.color="$GREEN" \
    icon.padding_left=6 \
    icon.padding_right=6 \
    label.drawing=off \
    background.drawing=off \
    popup.background.color="$SURFACE0" \
    popup.background.corner_radius=8 \
    popup.background.border_width=2 \
    popup.background.border_color="$SURFACE1" \
    popup.background.shadow.drawing=on \
    popup.horizontal=off \
    popup.y_offset=4 \
    click_script="sketchybar --set apple popup.drawing=toggle"

# Popup rows. Each acts, then closes the popup. Icons are nf-fa cog / search /
# lock. label.align=left with matching paddings makes them read as a menu.
sketchybar --add item apple.prefs popup.apple \
  --set apple.prefs \
    icon="" \
    icon.font="Hack Nerd Font:Regular:13.0" \
    icon.color="$TEXT" \
    label="Preferences" \
    label.align=left \
    background.padding_left=4 \
    background.padding_right=4 \
    click_script="open -a 'System Settings'; sketchybar --set apple popup.drawing=off" \
  --add item apple.activity popup.apple \
  --set apple.activity \
    icon="" \
    icon.font="Hack Nerd Font:Regular:13.0" \
    icon.color="$TEXT" \
    label="Activity" \
    label.align=left \
    background.padding_left=4 \
    background.padding_right=4 \
    click_script="open -a 'Activity Monitor'; sketchybar --set apple popup.drawing=off" \
  --add item apple.lock popup.apple \
  --set apple.lock \
    icon="" \
    icon.font="Hack Nerd Font:Regular:13.0" \
    icon.color="$TEXT" \
    label="Lock Screen" \
    label.align=left \
    background.padding_left=4 \
    background.padding_right=4 \
    click_script="pmset displaysleepnow; sketchybar --set apple popup.drawing=off"
