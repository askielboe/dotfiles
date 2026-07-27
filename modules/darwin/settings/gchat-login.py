#!/usr/bin/env python3
"""One-time interactive OAuth login for a Google Chat account.

Run `gchat-login <label>` once per account (e.g. `gchat-login work-a`,
`gchat-login work-b`). It runs Google's loopback-redirect OAuth flow in your
browser with PKCE, then writes the resulting refresh token to
~/.local/state/gchat/<label>.json — the mutable state file the gchat poller
(dotfiles/gchat/gchat.py) reads and refreshes in place. That token rotates, so it
lives outside the read-only nix store and is never committed.

The Desktop-app OAuth client id/secret come from your Google Cloud project (see
the setup steps in modules/darwin/settings/gchat.nix). Provide them via the
GCHAT_CLIENT_ID / GCHAT_CLIENT_SECRET environment variables, or paste them when
prompted. The requested scopes are read-only: chat.spaces.readonly,
chat.messages.readonly, chat.users.readstate.readonly, plus openid + email so we
can record which account this is — the menu-bar item opens each account with
`?authuser=<email>` and needs to know the address (stored as `email` in the JSON).
"""

import base64
import hashlib
import http.server
import json
import os
import secrets
import socket
import sys
import time
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

SCOPES = [
    "openid",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/chat.spaces.readonly",
    "https://www.googleapis.com/auth/chat.messages.readonly",
    "https://www.googleapis.com/auth/chat.users.readstate.readonly",
]
AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "gchat"
)


def b64url(raw):
    """base64url without padding, per RFC 7636."""
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def email_from_token(tok):
    """Best-effort account email from the OAuth response (for ?authuser=).

    Prefers the id_token's `email` claim (no extra request; it's Google-issued
    over TLS, so we read the payload without verifying a signature), and falls
    back to the OIDC userinfo endpoint. Returns None if neither yields one — the
    login still succeeds, the gchat chip just won't deep-link to this account.
    """
    idt = tok.get("id_token")
    if idt:
        try:
            payload = idt.split(".")[1]
            payload += "=" * (-len(payload) % 4)  # restore base64url padding
            email = json.loads(base64.urlsafe_b64decode(payload)).get("email")
            if email:
                return email
        except Exception:  # noqa: BLE001 - fall through to the userinfo call
            pass
    try:
        req = urllib.request.Request(
            "https://openidconnect.googleapis.com/v1/userinfo",
            headers={"Authorization": f"Bearer {tok['access_token']}"},
        )
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read().decode()).get("email")
    except Exception:  # noqa: BLE001 - email is a nice-to-have, not required
        return None


def capture_code(port, expected_state):
    """Serve exactly one loopback request and return its ?code (or exit)."""
    result = {}

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):  # noqa: N802 - http.server API name
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            result["code"] = q.get("code", [None])[0]
            result["state"] = q.get("state", [None])[0]
            result["error"] = q.get("error", [None])[0]
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(
                b"<h2>Google Chat authorized.</h2>"
                b"You can close this tab and return to the terminal."
            )

        def log_message(self, *_):  # silence the default stderr logging
            pass

    httpd = http.server.HTTPServer(("127.0.0.1", port), Handler)
    try:
        httpd.handle_request()
    finally:
        httpd.server_close()

    if result.get("error"):
        sys.exit(f"authorization failed: {result['error']}")
    if not result.get("code") or result.get("state") != expected_state:
        sys.exit("no valid authorization code received (state mismatch)")
    return result["code"]


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: gchat-login <label>   (e.g. gchat-login work-a)")
    label = sys.argv[1]

    client_id = os.environ.get("GCHAT_CLIENT_ID") or input("OAuth client ID: ").strip()
    client_secret = (
        os.environ.get("GCHAT_CLIENT_SECRET")
        or input("OAuth client secret: ").strip()
    )
    if not client_id or not client_secret:
        sys.exit("client id and secret are required")

    verifier = b64url(secrets.token_bytes(32))
    challenge = b64url(hashlib.sha256(verifier.encode()).digest())
    state = secrets.token_urlsafe(16)

    # Bind an ephemeral loopback port for the redirect; Google matches loopback
    # redirect URIs by host, not port, so it needn't be pre-registered.
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    redirect = f"http://127.0.0.1:{port}/"

    params = {
        "client_id": client_id,
        "redirect_uri": redirect,
        "response_type": "code",
        "scope": " ".join(SCOPES),
        "access_type": "offline",  # ask for a refresh token
        "prompt": "consent",  # force a fresh refresh token every run
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    }
    url = AUTH_URL + "?" + urllib.parse.urlencode(params)

    print("Opening Google authorization in your browser.")
    print("If it doesn't open, paste this URL manually:\n")
    print(f"  {url}\n")
    webbrowser.open(url)

    code = capture_code(port, state)

    body = urllib.parse.urlencode(
        {
            "code": code,
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": redirect,
            "grant_type": "authorization_code",
            "code_verifier": verifier,
        }
    ).encode()
    req = urllib.request.Request(
        TOKEN_URL,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        tok = json.loads(r.read().decode())

    if "refresh_token" not in tok:
        sys.exit(
            "no refresh_token returned — revoke the prior grant at "
            "https://myaccount.google.com/permissions and retry"
        )

    email = email_from_token(tok)

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    out = STATE_DIR / f"{label}.json"
    out.write_text(
        json.dumps(
            {
                "label": label,
                "email": email,
                "client_id": client_id,
                "client_secret": client_secret,
                "refresh_token": tok["refresh_token"],
                "access_token": tok["access_token"],
                "expires_at": int(time.time()) + int(tok.get("expires_in", 3600)),
            },
            indent=2,
        )
    )
    out.chmod(0o600)
    print(f"\nSuccess. Saved {out}" + (f" ({email})" if email else ""))
    if not email:
        print(
            "Note: couldn't determine this account's email, so the chip will open "
            "the default Chat account. Add \"email\": \"you@domain\" to the JSON to "
            "route clicks to this account."
        )
    print("The Google Chat menu-bar item will pick it up on its next refresh.")


if __name__ == "__main__":
    main()
