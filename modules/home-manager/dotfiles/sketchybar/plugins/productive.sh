#!/bin/bash
# Productive time today: sums today's active (not-AFK) time that ActivityWatch
# categorises under the "Work" tree, using the same AFK-filter + categorize
# pipeline the AW dashboard runs. A dim companion figure shows today's
# Uncategorized time (how much active time no rule has claimed — watch it to
# know when the category rules need another app added).
#
# The category rules live server-side in aw-server (GET /api/0/settings/classes)
# and are edited in the AW web UI (Settings → Categories). Since the plugin reads
# whatever rules are applied, the bar always agrees with the AW dashboard.
#
# Drives TWO items in one shot: `productive` (owns the script/update_freq, icon,
# goal-ramped colour) and the passive `productive_unc` (dim, no script — repainted
# here). jq/curl come from services.sketchybar.extraPackages. `date` is only ever
# `date +FMT` (identical on BSD and GNU) and the window is [local-midnight .. now],
# so no non-portable date arithmetic is needed.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

AW="http://localhost:5600/api/0"
ICON="󰔟"
GOAL_HOURS=6                 # a full day's productive time == the green threshold
PRODUCTIVE_ROOTS='["Work"]'  # top-level categories that count; add "Comms" to
                             # also count Slack/email, "Media" to count everything

# Format whole seconds as "4h 13m" (or "47m" under an hour).
fmt() { local h=$(( $1/3600 )) m=$(( ($1%3600)/60 )); [ "$h" -gt 0 ] && printf '%dh %dm' "$h" "$m" || printf '%dm' "$m"; }

# Paint both items and stop. $1/$2 productive label/colour, $3 uncategorised label.
render() {
  sketchybar --set productive drawing=on icon="$ICON" icon.color="$2" label="$1" label.color="$2" \
             --set productive_unc drawing=on label="$3" label.color="$OVERLAY0"
  exit 0
}
# Hide both (AW unreachable / no data) — a broken bar is worse than an absent one;
# they reappear on the next tick once AW is back.
hide() { sketchybar --set productive drawing=off --set productive_unc drawing=off; exit 0; }

# Discover the local window+afk buckets by name so this works on any host and
# ignores the "-synced-from-*" copies AW creates for peer sync.
buckets="$(curl -fs --max-time 4 "$AW/buckets/")" || hide
win="$(printf '%s' "$buckets" | jq -r '[keys[]|select(startswith("aw-watcher-window_") and (contains("synced-from")|not))][0] // empty')"
afk="$(printf '%s' "$buckets" | jq -r '[keys[]|select(startswith("aw-watcher-afk_")    and (contains("synced-from")|not))][0] // empty')"
[ -n "$win" ] && [ -n "$afk" ] || hide

# Category rules — regex ones only ("none"/parent rules carry no matchable regex,
# and a literal null in the query text breaks the aw-query parser).
classes="$(curl -fs --max-time 4 "$AW/settings/classes" | jq -c '[.[]|select(.rule.type=="regex")|[.name,.rule]]')" || hide
[ -n "$classes" ] && [ "$classes" != "[]" ] || hide

# Today's window: local midnight .. now, RFC3339 with a colon in the offset
# (built with bash string ops so we never depend on `date -d`/`date -v`).
off="$(date +%z)"; off="${off:0:3}:${off:3:2}"
period="$(date +%Y-%m-%dT00:00:00)${off}/$(date +%Y-%m-%dT%H:%M:%S)${off}"

# Canonical Activity query: window events, kept only during not-afk periods,
# categorised, then merged into one event per category with summed duration.
query="w = query_bucket(\"${win}\");
a = query_bucket(\"${afk}\");
na = filter_keyvals(a, \"status\", [\"not-afk\"]);
w = filter_period_intersect(w, na);
w = categorize(w, ${classes});
RETURN = merge_events_by_keys(w, [\"\$category\"]);"

body="$(jq -n --arg q "$query" --arg p "$period" '{query:[$q],timeperiods:[$p]}')"
resp="$(curl -fs --max-time 12 -H 'Content-Type: application/json' -d "$body" "$AW/query/")" || hide

# Sum Work-tree seconds and Uncategorised seconds from the merged categories. A
# query error returns an object (not [[...]]), so guard the shape and bail.
read -r secs unc <<<"$(printf '%s' "$resp" | jq -r --argjson roots "$PRODUCTIVE_ROOTS" '
  if type=="array" and (.[0]|type=="array") then
    ([ .[0][] | select(.data["$category"][0] as $r | ($roots|index($r))) | .duration ] | add // 0),
    ([ .[0][] | select(.data["$category"][0] == "Uncategorized")        | .duration ] | add // 0)
  else -1, -1 end | floor' | tr '\n' ' ')"
[ -n "$secs" ] && [ "$secs" -ge 0 ] 2>/dev/null || hide

# Colour ramps toward green as the day's productive time approaches the goal.
goal=$((GOAL_HOURS*3600))
if   [ "$secs" -ge "$goal" ];       then color="$GREEN"
elif [ "$secs" -ge "$((goal/2))" ]; then color="$TEXT"
elif [ "$secs" -ge 1800 ];          then color="$SUBTEXT0"
else color="$OVERLAY0"; fi

render "$(fmt "$secs")" "$color" "·$(fmt "$unc")"
