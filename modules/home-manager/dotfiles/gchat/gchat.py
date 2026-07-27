#!/usr/bin/env python3
"""Google Chat unread poller — neutral, importable library (no UI).

This is the OAuth/API core that answers "how many unread conversations does each
Google Chat account have?". It carries NO menu-bar / status-bar rendering of its
own — callers import it and format the result however they like. Today the only
consumer is the SwiftBar item (dotfiles/swiftbar/gchat.1m.py), which imports
`account_labels`, `access_token`, `account_unread`, `STATE_DIR`, `CHAT_URL` and
the `json` module from here.

home-manager symlinks this file to ~/.local/lib/gchat/gchat.py (see
modules/home-manager/darwin-specific.nix); the SwiftBar plugin puts that dir on
sys.path and `import gchat`. It was extracted here (2026-07) when sketchybar was
removed — it previously lived as the sketchybar plugin these functions powered.

Per account there is no "unread badge" endpoint, so we:

  1. list every space/DM/group the user belongs to (`spaces.list`, paginated);
  2. read each space's per-user read state (`getSpaceReadState.lastReadTime`);
  3. ask `messages.list` whether any message exists with
     `createTime > lastReadTime` — if so, that space is unread.

Sending a message advances your own `lastReadTime`, so messages you sent don't
count. A space you've never opened has no `lastReadTime` and counts as unread if
it holds any message — matching how Google Chat itself bolds it.

Each account is one JSON state file under ~/.local/state/gchat/*.json (written by
`gchat-login`). The OAuth access token is refreshed in place when near expiry;
the rotating file lives outside the read-only nix store. The per-space checks fan
out across a thread pool so a large space list stays fast.
"""

import concurrent.futures as cf
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://chat.googleapis.com/v1"
TOKEN_URL = "https://oauth2.googleapis.com/token"
CHAT_URL = "https://chat.google.com/"
EPOCH = "1970-01-01T00:00:00Z"
HTTP_TIMEOUT = 10
MAX_WORKERS = 16

STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "gchat"
)


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


def account_unread(token):
    """Count of unread conversations for the account behind `token`."""
    spaces = list_spaces(token)
    if not spaces:
        return 0
    with cf.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        return sum(ex.map(lambda s: space_unread(token, s), spaces))


def account_labels():
    """Sorted state-file stems (the accounts), excluding the shared client.json."""
    if not STATE_DIR.exists():
        return []
    return sorted(p.stem for p in STATE_DIR.glob("*.json") if p.name != "client.json")
