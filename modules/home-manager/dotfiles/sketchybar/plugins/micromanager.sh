#!/bin/bash
# Cold Turkey Micromanager focus-block indicator (center, beside pomodoro).
#
# Micromanager is not nix-managed and exposes no CLI or events, so we poll its
# NSUserDefaults prefs plist. `defaults read` goes through cfprefsd, so values
# are fresh even while the app is writing them.
#   locked    1 while a block is being enforced, 0 idle
#   endTime   block end timestamp (NSDate string, UTC), present only while blocking
#   whitelist colon-separated, hex-encoded lowercase app-name substrings
#
# A single anchor item (`micromanager`) runs this; it repaints the anchor plus a
# fixed pool of app-font glyph slots (`micromanager.app.1..N`) in one chained
# --set. Shown only while a block is active and counting down; hidden otherwise.
#
# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

PREF="com.getcoldturkey.micromanager-pro"
POOL=6

hide_all() {
  local args=(--set micromanager drawing=off update_freq=5 label="")
  local i
  for i in 1 2 3 4 5 6; do
    args+=(--set "micromanager.app.$i" drawing=off)
  done
  sketchybar "${args[@]}"
  exit 0
}

# Parse Micromanager's endTime ("2026-07-08 17:48:55 +0000", NSDate/UTC) into
# epoch seconds. Uses python3 (guaranteed on the agent PATH via
# services.sketchybar.extraPackages) rather than `date -f`, since that flag's
# syntax differs between GNU (`-d`) and BSD (`-j -f`) date and the agent PATH
# carries GNU coreutils' date.
parse_time() {
  python3 -c 'import sys,datetime; print(int(datetime.datetime.strptime(sys.argv[1],"%Y-%m-%d %H:%M:%S %z").timestamp()))' "${1//\"/}" 2>/dev/null
}

fmt_remaining() {
  local s="$1"
  if [ "$s" -ge 3600 ]; then
    printf '%dh%02dm' "$((s / 3600))" "$(((s % 3600) / 60))"
  elif [ "$s" -ge 60 ]; then
    printf '%dm' "$((s / 60))"
  else
    printf '%ds' "$s"
  fi
}

# --- session active? ---------------------------------------------------------
locked="$(defaults read "$PREF" locked 2>/dev/null)" || hide_all
[ "$locked" = "1" ] || hide_all

end_raw="$(defaults read "$PREF" endTime 2>/dev/null)" || hide_all
end_epoch="$(parse_time "$end_raw")" || hide_all
[ -n "$end_epoch" ] || hide_all
now="$(date +%s)"
remaining=$((end_epoch - now))
[ "$remaining" -gt 0 ] || hide_all

label="$(fmt_remaining "$remaining")"
color="$MAUVE"
[ "$remaining" -le 120 ] && color="$RED"

# --- allowlist glyphs --------------------------------------------------------
# whitelist: hex-encoded lowercase substrings, ':' separated. Decode, normalise
# to a display name, map to a sketchybar-app-font glyph via icon_map.sh (same
# mechanism as front_app.sh); fall back to :default: (itself an app-font glyph).
whitelist="$(defaults read "$PREF" whitelist 2>/dev/null | tr -d '"')"
map="$(command -v icon_map.sh)"
# shellcheck disable=SC1090 # resolved from PATH at runtime (pkgs.sketchybar-app-font)
[ -n "$map" ] && source "$map"

args=(--set micromanager drawing=on update_freq=1 label="$label" icon.color="$color")

i=1
IFS=':' read -ra entries <<<"$whitelist"
for hex in "${entries[@]}"; do
  [ -z "$hex" ] && continue
  [ "$i" -gt "$POOL" ] && break
  name="$(printf '%b' "$(printf '%s' "$hex" | sed 's/../\\x&/g')")"
  case "$name" in
  1password) app="1Password" ;;
  *) app="$(tr '[:lower:]' '[:upper:]' <<<"${name:0:1}")${name:1}" ;;
  esac
  glyph=":default:"
  if command -v __icon_map >/dev/null 2>&1; then
    __icon_map "$app"
    # shellcheck disable=SC2154 # icon_result is set by __icon_map
    glyph="$icon_result"
  fi
  args+=(--set "micromanager.app.$i" drawing=on icon="$glyph")
  i=$((i + 1))
done

# Hide any unused slots.
while [ "$i" -le "$POOL" ]; do
  args+=(--set "micromanager.app.$i" drawing=off)
  i=$((i + 1))
done

sketchybar "${args[@]}"
