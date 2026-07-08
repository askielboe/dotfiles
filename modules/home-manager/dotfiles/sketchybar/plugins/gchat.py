#!/usr/bin/env python3
"""Google Chat unread indicator for sketchybar — one chip per account.

sketchybar routes a click to a whole item, not to a character inside its label,
so a single item showing "2·1" can only ever open one account. To make each
count independently clickable we run ONE item per account, named
`gchat.<label>`, and this script polls exactly that account (its name arrives as
$NAME, e.g. "gchat.work-a", and the label after the dot is the state-file stem).
A separate static item owns the shared 󰭹 icon, so these count items carry no
icon of their own — the bar reads "󰭹 2·0". The "·" separator is appended here to
every count except the rightmost (last in sort order). items/gchat.sh declares
the items by enumerating the state files at bar load.

Per account there is no "unread badge" endpoint, so we:

  1. list every space/DM/group the user belongs to (`spaces.list`, paginated);
  2. read each space's per-user read state (`getSpaceReadState.lastReadTime`);
  3. ask `messages.list` whether any message exists with
     `createTime > lastReadTime` — if so, that space is unread.

Sending a message advances your own `lastReadTime`, so messages you sent don't
count. A space you've never opened has no `lastReadTime` and counts as unread if
it holds any message — matching how Google Chat itself bolds it.

The chip's click_script is rewritten each poll to open *this* account via
`https://chat.google.com/?authuser=<email>` — Google's account router resolves
`authuser=<email>` to the right session regardless of Chrome's sign-in order (an
index like /u/0/ is not stable). The email comes from the state file's `email`
field, written by `gchat-login`; without it we fall back to the plain URL.

Each account is one JSON state file under ~/.local/state/gchat/*.json (written by
`gchat-login`). The OAuth access token is refreshed in place when near expiry,
exactly like the claude_usage plugin; the rotating file lives outside the
read-only nix store. Colour vars (TEXT/PEACH/RED/OVERLAY0) come from the
environment — plugins/gchat.sh sources colors.sh before exec'ing this script.

The per-space checks fan out across a thread pool so a large space list stays
fast. update_freq=60 keeps us far under the API's 3000-reads/min project quota
even with hundreds of spaces.
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
CHAT_URL = "https://chat.google.com/"
EPOCH = "1970-01-01T00:00:00Z"
HTTP_TIMEOUT = 10
MAX_WORKERS = 16

STATE_DIR = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "gchat"
)
# sketchybar passes the item name in $NAME, e.g. "gchat.work-a"; the login/"no
# accounts" anchor is the bare "gchat".
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


def click_script_for(email):
    """Shell command that opens Google Chat for this specific account.

    `?authuser=<email>` is Google's account-router hint; unlike a /u/<index>/
    path it doesn't depend on the browser's sign-in order. Falls back to the
    plain Chat URL when the state file has no `email` (e.g. minted before
    gchat-login captured it — add one to the JSON to enable per-account routing).
    """
    if not email:
        return f"open '{CHAT_URL}'"
    q = urllib.parse.urlencode({"authuser": email})
    return f"open '{CHAT_URL}?{q}'"


def render(label, color, drawing="on", click=None):
    """Paint the count item's label (optionally its click target) and exit.

    The shared 󰭹 lives on a separate static item, so we only ever set the label
    here; the count items are created with icon.drawing=off.
    """
    args = [
        f"drawing={drawing}",
        f"label={label}",
        f"label.color={color}",
    ]
    if click is not None:
        args.append(f"click_script={click}")
    sb_set(*args)
    sys.exit(0)


def hide():
    """This account is all read — hide the chip and exit."""
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


def main():
    labels = account_labels()

    # The bare "gchat" name reaches here only as the placeholder shown before any
    # account exists — once accounts exist the shared icon owns that name and has
    # no script. Prompt to log in (or bow out if somehow invoked with accounts).
    if not NAME.startswith("gchat."):
        hide() if labels else render("login", OVERLAY0)

    label = NAME[len("gchat.") :]
    state_path = STATE_DIR / f"{label}.json"
    if not state_path.exists():
        hide()  # account removed since bar load — this count disappears

    st = json.loads(state_path.read_text())
    click = click_script_for(st.get("email"))
    # Dot-separate the counts: every account but the rightmost (last in sort
    # order) carries a trailing separator so the row reads "2·0".
    sep = "" if labels and label == labels[-1] else "·"

    try:
        token = access_token(state_path)
        count = account_unread(token)
    except urllib.error.HTTPError:
        render(f"!{sep}", RED, click=click)  # token/quota rejected -> re-login
    except (urllib.error.URLError, OSError):
        render(f"?{sep}", OVERLAY0, click=click)  # network down -> self-heals
    except Exception:  # noqa: BLE001 - never crash the bar
        render(f"!{sep}", RED, click=click)

    # Peach when this account has unread, dim grey at 0 (always shown).
    color = PEACH if count > 0 else OVERLAY0
    render(f"{count}{sep}", color, click=click)


if __name__ == "__main__":
    main()
