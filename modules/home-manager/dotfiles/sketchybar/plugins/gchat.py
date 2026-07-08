#!/usr/bin/env python3
"""Google Chat unread indicator for sketchybar.

Polls the Google Chat REST API for one or more Workspace accounts and paints the
`gchat` bar item with the number of unread conversations. There is no single
"unread badge" endpoint, so per account we:

  1. list every space/DM/group the user belongs to (`spaces.list`, paginated);
  2. read each space's per-user read state (`getSpaceReadState.lastReadTime`);
  3. ask `messages.list` whether any message exists with
     `createTime > lastReadTime` — if so, that space is unread.

Sending a message advances your own `lastReadTime`, so messages you sent don't
count. A space you've never opened has no `lastReadTime` and counts as unread if
it holds any message — matching how Google Chat itself bolds it.

Each account is one JSON state file under ~/.local/state/gchat/*.json (written by
`gchat-login`). The OAuth access token is refreshed in place when near expiry,
exactly like the claude_usage plugin; the rotating file lives outside the
read-only nix store. Colour vars (TEXT/PEACH/RED/OVERLAY0) come from the
environment — plugins/gchat.sh sources colors.sh before exec'ing this script.

The per-space checks fan out across a thread pool so a large space list stays
fast. update_freq=60 keeps us far under the API's 3000-reads/min project quota
even with hundreds of spaces across both accounts.
"""

import concurrent.futures as cf
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://chat.googleapis.com/v1"
TOKEN_URL = "https://oauth2.googleapis.com/token"
EPOCH = "1970-01-01T00:00:00Z"
HTTP_TIMEOUT = 10
MAX_WORKERS = 16
ICON = "\U000f0b79"  # nf-md-chat

STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "gchat"
)
NAME = sys.argv[1] if len(sys.argv) > 1 else "gchat"

# Catppuccin Mocha colours, injected by the wrapper (see colors.sh); the
# fallbacks keep the script runnable standalone for debugging.
TEXT = os.environ.get("TEXT", "0xffcdd6f4")
PEACH = os.environ.get("PEACH", "0xfffab387")
RED = os.environ.get("RED", "0xfff38ba8")
OVERLAY0 = os.environ.get("OVERLAY0", "0xff6c7086")


def _get(url, token, _retry=True):
    """GET a Chat API URL with the bearer token, returning the parsed JSON.

    Retries once on a transient network error (DNS/timeout/connection reset) so a
    single blip doesn't drop an account. HTTP status errors are re-raised
    immediately — they mean the request itself was rejected, not the connection.
    """
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError:
        raise
    except (urllib.error.URLError, OSError):
        if _retry:
            time.sleep(0.5)
            return _get(url, token, _retry=False)
        raise


def sb_set(*args):
    """Apply `--set NAME <args...>` to the bar item (best effort)."""
    subprocess.run(["sketchybar", "--set", NAME, *args], check=False)


def render(label, color, drawing="on"):
    """Paint the item and exit."""
    sb_set(
        f"drawing={drawing}",
        f"icon={ICON}",
        f"icon.color={color}",
        f"label={label}",
        f"label.color={color}",
    )
    sys.exit(0)


def hide():
    """Everything is read — hide the item and exit."""
    sb_set("drawing=off")
    sys.exit(0)


def access_token(state_path):
    """Return a valid access token for the account, refreshing it in place.

    Google's OAuth refresh token for an Internal (Workspace) app does not
    expire, so we only ever swap the short-lived access token. The state file is
    rewritten atomically and kept at mode 0600.
    """
    st = json.loads(state_path.read_text())
    now = int(time.time())
    if now < st.get("expires_at", 0) - 300:
        return st["access_token"]

    body = urllib.parse.urlencode(
        {
            "grant_type": "refresh_token",
            "refresh_token": st["refresh_token"],
            "client_id": st["client_id"],
            "client_secret": st["client_secret"],
        }
    ).encode()
    req = urllib.request.Request(
        TOKEN_URL,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as r:
        tok = json.loads(r.read().decode())

    st["access_token"] = tok["access_token"]
    st["expires_at"] = now + int(tok.get("expires_in", 3600))
    tmp = state_path.with_suffix(".tmp")
    tmp.write_text(json.dumps(st, indent=2))
    os.replace(tmp, state_path)
    state_path.chmod(0o600)
    return st["access_token"]


def list_spaces(token):
    """All spaces the authenticated user belongs to (following pagination)."""
    spaces, page = [], None
    while True:
        q = {"pageSize": "1000"}
        if page:
            q["pageToken"] = page
        data = _get(f"{API}/spaces?" + urllib.parse.urlencode(q), token)
        spaces += data.get("spaces", [])
        page = data.get("nextPageToken")
        if not page:
            return spaces


def space_unread(token, space):
    """1 if the space has a message newer than the user's read state, else 0."""
    name = space["name"]  # "spaces/AAAA"
    space_id = name.split("/", 1)[1]
    try:
        rs = _get(f"{API}/users/me/spaces/{space_id}/spaceReadState", token)
        last = rs.get("lastReadTime") or EPOCH
    except (urllib.error.URLError, OSError):
        # No read state yet, or a transient per-space failure -> treat as unread
        # from the epoch (any message then counts).
        last = EPOCH

    q = {"filter": f'createTime > "{last}"', "pageSize": "1"}
    try:
        data = _get(f"{API}/{name}/messages?" + urllib.parse.urlencode(q), token)
    except (urllib.error.URLError, OSError):
        return 0  # one flaky space shouldn't drop the account; self-heals next poll
    return 1 if data.get("messages") else 0


def account_unread(state_path):
    """Count of unread conversations for one account."""
    token = access_token(state_path)
    spaces = list_spaces(token)
    if not spaces:
        return 0
    with cf.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        return sum(ex.map(lambda s: space_unread(token, s), spaces))


def main():
    files = sorted(p for p in STATE_DIR.glob("*.json") if p.name != "client.json")
    if not files:
        render("login", OVERLAY0)  # nothing set up yet

    labels, total, any_ok, auth_err, net_err = [], 0, False, False, False
    for f in files:
        try:
            c = account_unread(f)
            total += c
            labels.append(str(c))
            any_ok = True
        except urllib.error.HTTPError:
            labels.append("!")  # token/quota rejected -> real action needed
            auth_err = True
        except (urllib.error.URLError, OSError):
            labels.append("·")  # network down -> transient, don't alarm
            net_err = True
        except Exception:  # noqa: BLE001 - never crash the bar
            labels.append("!")
            auth_err = True

    if not any_ok:
        # Every account failed. Distinguish a real credential problem (red, needs
        # re-login) from a transient network outage (dim, self-heals) so the item
        # doesn't cry "auth?" every time the Wi-Fi drops.
        render("auth?", RED) if auth_err else render("", OVERLAY0)
    if total == 0 and not auth_err and not net_err:
        hide()  # everything genuinely read

    # Per-account breakdown when there's more than one account, e.g. "2·1"
    # ("·" marks an account that couldn't be reached this poll).
    label = "·".join(labels) if len(files) > 1 else labels[0]
    render(label, RED if auth_err else PEACH)


if __name__ == "__main__":
    main()
