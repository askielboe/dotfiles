#!/bin/bash
# Claude usage meter: the 7-day window renders as a filling pie-ring, the
# 5-hour window as a percentage beside it, and the extra-usage (pay-as-you-go)
# spend appears only once a window hits 100%. Once the chip goes red (a window
# ≥ 85%) it also appends a hourglass countdown to that binding window's reset,
# so a healthy chip stays minimal but a hot one says when it clears. All read
# from Anthropic's authoritative /api/oauth/usage endpoint — same as `/usage`.
#
# Auth is a user:profile-scoped OAuth token minted once by `claude-usage-login`
# (modules/darwin/settings/claude-usage-login.sh) into the state file below.
# The token expires every ~8h; this plugin refreshes it in place via the stored
# refresh token. That file rotates, so it lives outside the nix store, not in
# the repo. jq/curl come from services.sketchybar.extraPackages.
#
# Polls at update_freq=180 (the documented safe interval for this endpoint;
# a shorter cadence with the required User-Agent still risks the rate-limited
# bucket). No event subscriptions — purely timer-driven.

# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/claude-usage/oauth.json"
# api.anthropic.com is the live token endpoint. The old console.anthropic.com host
# is deprecated (301s to platform.claude.com) and its /v1/oauth/token is globally
# rate-limited (persistent 429), so refreshes there never succeed.
TOKEN_URL="https://api.anthropic.com/v1/oauth/token"
USAGE_URL="https://api.anthropic.com/api/oauth/usage"
CLIENT_ID="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
# The claude-code/<v> User-Agent is required; without it the endpoint routes to
# an aggressively rate-limited bucket. The exact version is not significant.
UA="claude-code/2.1.201"
ICON="󰛄"

# Weekly (7-day) utilisation renders as a filling pie-ring in the label:
# index 0 = empty circle, 1..8 = circle-slice-1..8 (~12.5% each), 8 = full.
# Glyphs are embedded literally because macOS /bin/bash is 3.2 and lacks
# printf '\U' for astral (>U+FFFF) codepoints.
RING=(󰄰 󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)

# Paint the item and stop. $1=label text, $2=label colour. The glyph is always
# PEACH (the Claude brand orange); only the label carries state colour.
render() {
  sketchybar --set claude_usage drawing=on icon="$ICON" \
    icon.color="$PEACH" label="$1" label.color="$2"
  exit 0
}

# Not authenticated (no token yet) or auth is broken (refresh/usage failed):
# hide the chip entirely rather than nag with a "login"/"auth?" label. It
# reappears on the next poll as soon as a valid token is present again.
hide() {
  sketchybar --set claude_usage drawing=off
  exit 0
}

# Compact humanised duration for the reset countdown: "5d3h", "2h13m", "45m".
# Drops the smaller unit when it's zero (e.g. "2h" not "2h0m", "5d" not "5d0h").
fmt_dur() {
  local s="$1" d h m
  d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    { [ "$h" -gt 0 ] && printf '%dd%dh' "$d" "$h"; } || printf '%dd' "$d"
  elif [ "$h" -gt 0 ]; then
    { [ "$m" -gt 0 ] && printf '%dh%dm' "$h" "$m"; } || printf '%dh' "$h"
  else
    printf '%dm' "$m"
  fi
}

[ -f "$STATE_FILE" ] || hide

access_token="$(jq -r '.access_token // empty' "$STATE_FILE" 2>/dev/null)"
refresh_token="$(jq -r '.refresh_token // empty' "$STATE_FILE" 2>/dev/null)"
expires_at="$(jq -r '.expires_at // 0' "$STATE_FILE" 2>/dev/null)"
[ -n "$access_token" ] || hide

# Refresh when the access token is within 5 min of expiry (or already gone).
now="$(date +%s)"
if [ "$now" -ge "$((expires_at - 300))" ]; then
  [ -n "$refresh_token" ] || hide
  resp="$(curl -fsS --max-time 10 -X POST "$TOKEN_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg rt "$refresh_token" --arg id "$CLIENT_ID" \
      '{grant_type:"refresh_token",refresh_token:$rt,client_id:$id}')")" || hide
  printf '%s' "$resp" | jq -e '.access_token' >/dev/null 2>&1 || hide
  # Persist rotated tokens atomically; keep the old refresh token if none returned.
  tmp="$STATE_FILE.tmp"
  printf '%s' "$resp" | jq --arg oldrt "$refresh_token" '{
    access_token,
    refresh_token: (.refresh_token // $oldrt),
    expires_at: ((now + (.expires_in // 28800)) | floor)
  }' > "$tmp" && mv "$tmp" "$STATE_FILE" && chmod 600 "$STATE_FILE"
  access_token="$(printf '%s' "$resp" | jq -r '.access_token')"
fi

usage="$(curl -fsS --max-time 10 "$USAGE_URL" \
  -H "Authorization: Bearer $access_token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "User-Agent: $UA" \
  -H "Content-Type: application/json")" || render "…" "$OVERLAY0"

# Bail if the payload is not the expected object (e.g. an auth error body).
printf '%s' "$usage" | jq -e '.five_hour.utilization' >/dev/null 2>&1 || hide

# utilization is a 0–100 percentage per the endpoint spec; round to int.
# extra_usage amounts are minor units (e.g. cents) — divide by 10^decimal_places
# for the major-currency figure, and label it with the account's currency.
# resets_at is each window's UTC reset instant as ISO-8601 with microseconds and
# a +00:00 offset (e.g. 2026-…T16:50:00.766135+00:00) — take the fixed-width
# YYYY-MM-DDTHH:MM:SS prefix and parse it as UTC into epoch seconds (0 if null).
read -r five_h seven_d over_enabled over_used over_dp over_cur five_reset seven_reset \
  <<<"$(printf '%s' "$usage" | jq -r '
  def reset_epoch: if . == null or . == "" then 0
    else (.[0:19] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) end;
  [ (.five_hour.utilization // 0 | round),
    (.seven_day.utilization // 0 | round),
    (.extra_usage.is_enabled // false),
    (.extra_usage.used_credits // 0),
    (.extra_usage.decimal_places // 2),
    (.extra_usage.currency // "USD"),
    (.five_hour.resets_at | reset_epoch),
    (.seven_day.resets_at | reset_epoch)
  ] | @tsv' | tr "\t" " ")"

# Colour follows the most-binding window: neutral TEXT until it runs high, then
# RED past the 85% threshold. The icon glyph stays PEACH (brand) regardless, so
# a healthy chip carries no alert colour at all. The ring and percentage share
# the label colour (a sketchybar label carries a single colour). Track the
# binding window's reset instant alongside `worst` so the red-state countdown
# below reports when THAT window (the one driving the alert) actually clears.
worst="$five_h"; reset_epoch="$five_reset"
[ "$seven_d" -gt "$worst" ] && { worst="$seven_d"; reset_epoch="$seven_reset"; }
if [ "$worst" -ge 85 ]; then color="$RED"; else color="$TEXT"; fi

# Weekly (7-day) utilisation → pie-ring glyph. Map 0–100 onto the 9 RING states
# by rounding to the nearest eighth, but keep the endpoints honest: any non-zero
# usage shows at least a sliver (never the empty circle), and the full circle is
# reserved strictly for a true 100% (so 88–99% caps at slice-7).
idx=$(( (seven_d * 8 + 50) / 100 ))
[ "$seven_d" -gt 0 ] && [ "$idx" -eq 0 ] && idx=1
[ "$seven_d" -lt 100 ] && [ "$idx" -ge 8 ] && idx=7
[ "$idx" -gt 8 ] && idx=8

# Hourly-ish (5-hour) utilisation → a plain percentage beside the ring, e.g.
# "󰪡 45%".
label="${RING[$idx]} ${five_h}%"

# Time-to-reset of the binding window (hourglass glyph), shown ONLY while the
# chip is red (worst ≥ 85) — the "when does the pressure ease" number. A 5-hour
# reset shows as e.g. "󰔟 2h13m", a 7-day reset as "󰔟 5d3h". Below the threshold
# it's noise, so the calm state stays minimal. Guard on a future epoch to skip a
# stale/zero reset (e.g. a null resets_at, which reset_epoch mapped to 0).
if [ "$worst" -ge 85 ] && [ "$reset_epoch" -gt "$now" ]; then
  label="$label 󰔟 $(fmt_dur $(( reset_epoch - now )))"
fi

# Currency symbol for the common cases; fall back to the ISO code + space.
case "$over_cur" in
  USD) sym="\$" ;;
  EUR) sym="€"  ;;
  GBP) sym="£"  ;;
  *)   sym="$over_cur " ;;
esac
divisor="$(awk "BEGIN { printf \"%d\", 10 ^ $over_dp }")"

# Append extra-usage (pay-as-you-go) spend ONLY once a window is actually maxed
# out — i.e. 5h or 7d has reached 100%. Below 100% the spend is background noise,
# so hiding it keeps the chip narrow and calm; at 100% it becomes the number that
# matters (what the overage is costing). Still suppressed when it rounds to zero
# or the bucket is disabled, which would render a meaningless "€0".
if [ "$over_enabled" = "true" ] && { [ "$five_h" -ge 100 ] || [ "$seven_d" -ge 100 ]; }; then
  spend="$(awk "BEGIN { printf \"%.0f\", $over_used / $divisor }")"
  [ "$spend" -gt 0 ] && label="$label ${sym}${spend}"
fi

render "$label" "$color"
