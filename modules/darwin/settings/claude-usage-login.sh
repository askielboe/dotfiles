# Body of the `claude-usage-login` writeShellApplication (see sketchybar.nix).
# No shebang / `set` line here — writeShellApplication prepends both and lints
# this with shellcheck at build time. One-time interactive PKCE login that mints
# a user:profile-scoped OAuth token and writes it to the mutable state file the
# claude-usage sketchybar plugin reads. The token rotates on refresh, so it
# lives outside the read-only nix store (never committed).

client_id="9d1c250a-e61b-44d9-88ed-5944d1962f5e"
redirect="https://console.anthropic.com/oauth/code/callback"
# Token exchange goes to api.anthropic.com. The old console.anthropic.com host is
# being deprecated (it 301s to platform.claude.com) and its /v1/oauth/token is
# globally rate-limited (persistent 429, no Retry-After); api.anthropic.com is the
# live endpoint. The redirect_uri above stays as the client's registered callback.
token_url="https://api.anthropic.com/v1/oauth/token"
# URL-encoded forms for the authorize query string.
redirect_enc="https%3A%2F%2Fconsole.anthropic.com%2Foauth%2Fcode%2Fcallback"
scope_enc="org:create_api_key%20user:profile%20user:inference"

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-usage"
state_file="$state_dir/oauth.json"

# PKCE: verifier is 32 random bytes base64url; challenge is its base64url SHA-256.
verifier="$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')"
challenge="$(printf '%s' "$verifier" | openssl dgst -binary -sha256 | openssl base64 | tr '+/' '-_' | tr -d '=')"

url="https://claude.ai/oauth/authorize?code=true&client_id=$client_id&response_type=code&redirect_uri=$redirect_enc&scope=$scope_enc&code_challenge=$challenge&code_challenge_method=S256&state=$verifier"

echo "Opening Claude authorization in your browser."
echo "If it does not open, paste this URL manually:"
echo
echo "  $url"
echo
command -v open >/dev/null 2>&1 && open "$url" >/dev/null 2>&1 || true

printf 'Paste the authorization code (looks like CODE#STATE): '
read -r pasted
pasted="${pasted//[[:space:]]/}"
if [ -z "$pasted" ]; then
  echo "No code entered; aborting." >&2
  exit 1
fi

# The manual flow returns "<code>#<state>"; split on the first '#'.
authcode="${pasted%%#*}"
state="${pasted#*#}"

resp="$(curl -fsS -X POST "$token_url" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n \
    --arg code "$authcode" \
    --arg state "$state" \
    --arg verifier "$verifier" \
    --arg client_id "$client_id" \
    --arg redirect "$redirect" \
    '{grant_type:"authorization_code",code:$code,state:$state,client_id:$client_id,redirect_uri:$redirect,code_verifier:$verifier}')")"

if ! printf '%s' "$resp" | jq -e '.access_token' >/dev/null 2>&1; then
  echo "Token exchange failed:" >&2
  printf '%s\n' "$resp" | jq -r '.error_description // .error // .' >&2
  exit 1
fi

mkdir -p "$state_dir"
# Normalize to {access_token, refresh_token, expires_at} with expires_at in
# epoch SECONDS — the same shape the plugin reads and rewrites on refresh.
printf '%s' "$resp" | jq '{
  access_token,
  refresh_token,
  expires_at: ((now + (.expires_in // 28800)) | floor)
}' > "$state_file"
chmod 600 "$state_file"

echo
echo "Success. Token saved to $state_file"
echo "The sketchybar claude_usage item will pick it up on its next refresh."
