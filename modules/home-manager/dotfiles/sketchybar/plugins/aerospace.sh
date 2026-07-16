#!/bin/bash
# Repaints the workspace items in a single sketchybar call. Each space.<ws> shows
# its id (icon) plus a glyph per app in it (label, sketchybar-app-font) — like the
# SketchyBar example. The focused one gets a mauve pill with dark text, other
# occupied ones a subtle surface pill. The numbered home row 1-9 is ALWAYS shown —
# as a dim bare number (no pill, no glyphs) when empty — so those slots are a
# fixed, at-a-glance strip and free ones are obvious; the letter workspaces (A-Z)
# only appear when they hold a window (or are focused), keeping the ~20 unused
# letters out of the bar. FOCUSED_WORKSPACE is set by the AeroSpace
# exec-on-workspace-change callback; on other events, ask aerospace.
#
# Speed matters here: this runs on every workspace switch and the focused pill
# only moves once it finishes, so a slow repaint reads as a laggy highlight. The
# whole thing is therefore kept to a handful of subprocesses — three aerospace
# queries, one awk pass and one sketchybar call. In particular the per-workspace
# app glyphs are computed in ONE awk pass over all windows (not an awk per
# workspace — that spawned ~30 processes and dominated the repaint at ~300ms),
# and the per-workspace lookups below are pure-bash (no subshell/fork per item).

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"

focused="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused)}"
nonempty=" $("$AEROSPACE" list-workspaces --monitor all --empty no | tr '\n' ' ') "

# All windows once, as "workspace|app-name" lines. icon_map.sh from
# pkgs.sketchybar-app-font (on the agent PATH) defines __icon_map, which maps an
# app name to a glyph in $icon_result (an in-shell function — no subprocess).
windows="$("$AEROSPACE" list-windows --all --format '%{workspace}|%{app-name}')"
map="$(command -v icon_map.sh)"
# shellcheck disable=SC1090 # resolved from PATH at runtime
[ -n "$map" ] && source "$map"

# One awk pass turns the window list into, per non-empty workspace, its deduped
# app names in first-seen order as a TAB-separated line ("ws<TAB>app1<TAB>app2").
# This replaces an awk invocation per workspace: doing it once is the whole point
# of this rewrite. Note: /bin/bash on macOS is 3.2 (no associative arrays), so
# the result stays a newline-delimited string and is looked up in-shell below.
app_lines="$(printf '%s\n' "$windows" | awk -F'|' '
  $2 != "" && !seen[$1 SUBSEP $2]++ { apps[$1] = apps[$1] $2 "\t" }
  END { for (w in apps) print w "\t" apps[w] }
')"

# Deduped app names for one workspace (TAB-separated) into $apps_result — a
# pure-bash scan of $app_lines, no subprocess. Empty when the workspace has no
# mapped windows. Sets a global rather than echoing so the caller needn't wrap it
# in $(...), which would fork a subshell for every one of the ~30 workspaces.
apps_result=""
apps_for() {
  local ws="$1" line
  apps_result=""
  while IFS= read -r line; do
    case "$line" in
    "$ws"$'\t'*)
      apps_result="${line#*$'\t'}"
      return 0
      ;;
    esac
  done <<EOF
$app_lines
EOF
}

# Glyph string for one workspace into $glyphs: its app names mapped to glyphs via
# __icon_map, space-separated (with a trailing space). Empty for an empty
# workspace. Same global-not-echo reason as apps_for.
glyphs=""
build_glyphs() {
  local ws="$1" app IFS=$'\t'
  glyphs=""
  apps_for "$ws"
  [ -z "$apps_result" ] && return 0
  for app in $apps_result; do
    [ -z "$app" ] && continue
    if [ -n "$map" ]; then
      __icon_map "$app"
      # shellcheck disable=SC2154 # icon_result is set by __icon_map
      glyphs="$glyphs$icon_result "
    else
      glyphs="$glyphs:default: "
    fi
  done
}

set --

for ws in $("$AEROSPACE" list-workspaces --all); do
  build_glyphs "$ws"
  g="$glyphs"
  if [ "$ws" = "$focused" ]; then
    set -- "$@" --set "space.$ws" drawing=on \
      label="$g" label.drawing=on label.color="$CRUST" \
      icon.color="$CRUST" background.drawing=on background.color="$MAUVE"
  else
    case "$nonempty" in
    *" $ws "*) set -- "$@" --set "space.$ws" drawing=on \
      label="$g" label.drawing=on label.color="$TEXT" \
      icon.color="$SUBTEXT0" background.drawing=on background.color="$SURFACE0" ;;
    # Empty & unfocused. The numbered home row 1-9 always stays visible, drawn as
    # a dim bare number (no pill, no glyphs) so the digit strip is fixed and free
    # slots are obvious at a glance. Letter workspaces (A-Z) instead hide when
    # empty, keeping the ~20 unused letters out of the bar. Reset pill/label/icon
    # state explicitly since items keep their prior look across repaints (a
    # just-emptied workspace would otherwise carry its old pill).
    *)
      case "$ws" in
      [1-9]) set -- "$@" --set "space.$ws" drawing=on \
        label="" label.drawing=off icon.color="$OVERLAY0" background.drawing=off ;;
      *) set -- "$@" --set "space.$ws" drawing=off ;;
      esac
      ;;
    esac
  fi
done

sketchybar "$@"
