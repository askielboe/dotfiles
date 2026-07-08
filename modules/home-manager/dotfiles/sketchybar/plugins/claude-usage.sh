#!/bin/bash
# Claude usage meter: 5-hour + 7-day token windows and the extra-usage
# (pay-as-you-go) spend, read from Anthropic's authoritative /api/oauth/usage
# endpoint — the same source the CLI's `/usage` command uses.
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

# Paint the item and stop. $1=label text, $2=label colour. The glyph is always
# PEACH (the Claude brand orange); only the label carries state colour.
render() {
  sketchybar --set claude_usage drawing=on icon="$ICON" \
    icon.color="$PEACH" label="$1" label.color="$2"
  exit 0
}

[ -f "$STATE_FILE" ] || render "login" "$OVERLAY0"

access_token="$(jq -r '.access_token // empty' "$STATE_FILE" 2>/dev/null)"
refresh_token="$(jq -r '.refresh_token // empty' "$STATE_FILE" 2>/dev/null)"
expires_at="$(jq -r '.expires_at // 0' "$STATE_FILE" 2>/dev/null)"
[ -n "$access_token" ] || render "login" "$OVERLAY0"

# Refresh when the access token is within 5 min of expiry (or already gone).
now="$(date +%s)"
if [ "$now" -ge "$((expires_at - 300))" ]; then
  [ -n "$refresh_token" ] || render "auth?" "$RED"
  resp="$(curl -fsS --max-time 10 -X POST "$TOKEN_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg rt "$refresh_token" --arg id "$CLIENT_ID" \
      '{grant_type:"refresh_token",refresh_token:$rt,client_id:$id}')")" || render "auth?" "$RED"
  printf '%s' "$resp" | jq -e '.access_token' >/dev/null 2>&1 || render "auth?" "$RED"
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

# Bail if the payload is not the expected object (e.g. an error body).
printf '%s' "$usage" | jq -e '.five_hour.utilization' >/dev/null 2>&1 || render "auth?" "$RED"

# utilization is a 0–100 percentage per the endpoint spec; round to int.
# extra_usage amounts are minor units (e.g. cents) — divide by 10^decimal_places
# for the major-currency figure, and label it with the account's currency.
read -r five_h seven_d over_enabled over_used over_dp over_cur \
  <<<"$(printf '%s' "$usage" | jq -r '
  [ (.five_hour.utilization // 0 | round),
    (.seven_day.utilization // 0 | round),
    (.extra_usage.is_enabled // false),
    (.extra_usage.used_credits // 0),
    (.extra_usage.decimal_places // 2),
    (.extra_usage.currency // "USD")
  ] | @tsv' | tr "\t" " ")"

# Colour the numbers only when the most-binding window runs high: they sit at
# neutral TEXT until then, and turn RED past the 85% threshold. The glyph stays
# PEACH (brand) regardless, so a healthy chip carries no alert colour at all.
worst="$five_h"; [ "$seven_d" -gt "$worst" ] && worst="$seven_d"
if [ "$worst" -ge 85 ]; then color="$RED"; else color="$TEXT"; fi

# Currency symbol for the common cases; fall back to the ISO code + space.
case "$over_cur" in
  USD) sym="\$" ;;
  EUR) sym="€"  ;;
  GBP) sym="£"  ;;
  *)   sym="$over_cur " ;;
esac
divisor="$(awk "BEGIN { printf \"%d\", 10 ^ $over_dp }")"

# Compact readout: 5h·7d window utilisation joined by a middot (the same
# separator the productive item uses), e.g. "42·30". The colour set above tints
# these numbers RED once the most-binding window runs high.
label="${five_h}·${seven_d}"

# Append extra-usage spend as a compact, rounded figure (e.g. "€62") — but only
# once it rounds to a non-zero amount. A pay-as-you-go bucket that is merely
# enabled (or has sub-unit spend) would render a meaningless "€0", so we hide the
# field entirely until spend is real, keeping the chip narrow and uncluttered.
if [ "$over_enabled" = "true" ]; then
  spend="$(awk "BEGIN { printf \"%.0f\", $over_used / $divisor }")"
  [ "$spend" -gt 0 ] && label="$label ${sym}${spend}"
fi

render "$label" "$color"
