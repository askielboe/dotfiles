#!/usr/bin/env python3
# <xbar.title>Google Chat unread</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Andreas Skielboe</xbar.author>
# <xbar.desc>Per-account Google Chat unread count in the native menu bar.</xbar.desc>
# <xbar.dependencies>python3</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
"""SwiftBar (or xbar) port of the sketchybar Google Chat unread indicator.

The heavy lifting — OAuth token rotation, spaces.list -> spaceReadState ->
messages.list unread detection, the per-space thread pool — already lives in the
sketchybar plugin. Rather than duplicate ~150 lines of API/OAuth code, we IMPORT
that poller and reuse its pure functions (`account_labels`, `access_token`,
`account_unread`, `CHAT_URL`). Importing it is side-effect-free: its `main()` is
guarded by `if __name__ == "__main__"`, and its module-level constants only read
env vars with fallbacks.

  Coupling note: this plugin therefore DEPENDS on
  ~/.config/sketchybar/plugins/gchat.py existing. If sketchybar is ever dropped,
  extract that file's API/OAuth core to a neutral shared module (e.g.
  ~/.local/lib/gchat/) and import from there instead.

Menu-bar rendering differs from sketchybar because the native bar has no rounded
"pill" backgrounds and can't colour individual words within one title line:

  * The icon is an SF Symbol (always renders natively — a Nerd Font glyph like
    󰭹 would be tofu in the system-font menu bar). Unread flips it to a badged,
    filled bubble; all-read is the quiet outline bubble.
  * The title shows the per-account counts space-joined ("2 0"), mirroring
    sketchybar, coloured as a whole line by the worst state (red error > peach
    unread > dim read).
  * Per-account detail + clickable `authuser` routing move into the dropdown,
    one row per account — actually richer than the flat sketchybar row.

Colours are Catppuccin as "light,dark" hex pairs so the item reads on either
menu-bar appearance. Refresh cadence is encoded in the filename (gchat.1m.py =
every minute), matching the sketchybar update_freq=60.
"""

import os
import sys
import urllib.error
import urllib.parse

# Reuse the sketchybar poller as a library (see module docstring).
POLLER_DIR = os.path.expanduser("~/.config/sketchybar/plugins")
sys.path.insert(0, POLLER_DIR)
try:
    import gchat as poller
except Exception as exc:  # noqa: BLE001 - surface the failure in the menu bar
    print("Chat ⚠️ | sfimage=exclamationmark.triangle.fill")
    print("---")
    print(f"Poller import failed: {exc}")
    print(f"Expected: {POLLER_DIR}/gchat.py")
    sys.exit(0)

# Catppuccin "Latte,Mocha" pairs — SwiftBar picks per menu-bar appearance.
PEACH = "#fe640b,#fab387"  # unread
DIM = "#6c6f85,#6c7086"  # all-read / neutral
RED = "#d20f39,#f38ba8"  # token rejected

# Per-account outcome markers used both in the title and to pick the icon/colour.
TOKEN_ERR = "!"  # HTTP 401/403/429 -> re-run gchat-login
NET_ERR = "?"  # transient network blip -> self-heals next poll


def chat_url(email):
    """Account-routed Chat URL (?authuser=<email>), or the plain URL if unknown.

    Mirrors the poller's `click_script_for` but yields a bare URL for SwiftBar's
    `href=` rather than a shell `open '...'` command.
    """
    if not email:
        return poller.CHAT_URL
    return f"{poller.CHAT_URL}?" + urllib.parse.urlencode({"authuser": email})


def poll(label):
    """Return (marker, email) for one account.

    `marker` is the unread count as a string, or TOKEN_ERR / NET_ERR. `email`
    powers the dropdown's per-account deep link.
    """
    state_path = poller.STATE_DIR / f"{label}.json"
    try:
        st = poller.json.loads(state_path.read_text())
    except Exception:  # noqa: BLE001 - removed since launch / unreadable
        return None, None
    email = st.get("email")
    try:
        token = poller.access_token(state_path)
        return str(poller.account_unread(token)), email
    except urllib.error.HTTPError:
        return TOKEN_ERR, email  # token/quota rejected
    except (urllib.error.URLError, OSError):
        return NET_ERR, email  # network down
    except Exception:  # noqa: BLE001 - never crash the menu bar
        return TOKEN_ERR, email


def render_title(markers):
    """Print the menu-bar line: SF Symbol + space-joined counts, worst-state colour."""
    counts = " ".join(m for m, _ in markers)
    has_token_err = any(m == TOKEN_ERR for m, _ in markers)
    unread = any(m.isdigit() and int(m) > 0 for m, _ in markers)

    if has_token_err:
        icon, color = "exclamationmark.triangle.fill", RED
    elif unread:
        icon, color = "message.badge.fill", PEACH
    else:
        icon, color = "message", DIM
    print(f"{counts} | sfimage={icon} color={color}")


def render_dropdown(markers):
    """Print the dropdown: one row per account (clickable), then bar actions."""
    print("---")
    for label, (marker, email) in markers.items():
        if marker == TOKEN_ERR:
            desc, sym = "token expired — run gchat-login", "exclamationmark.triangle"
        elif marker == NET_ERR:
            desc, sym = "offline", "wifi.slash"
        elif marker.isdigit() and int(marker) > 0:
            desc, sym = f"{marker} unread", "message.badge.fill"
        else:
            desc, sym = "read", "message"
        print(f"{label}: {desc} | href={chat_url(email)} sfimage={sym}")
    print("---")
    print(f"Open Google Chat | href={poller.CHAT_URL} sfimage=arrow.up.right.square")
    print("Refresh | refresh=true sfimage=arrow.clockwise")


def main():
    labels = poller.account_labels()
    if not labels:
        print("Chat | sfimage=message color=" + DIM)
        print("---")
        print("No accounts — run: gchat-login <label>")
        print(f"Open Google Chat | href={poller.CHAT_URL} sfimage=arrow.up.right.square")
        return

    results = {label: poll(label) for label in labels}
    # Drop accounts whose state file vanished mid-poll (marker None).
    results = {lbl: v for lbl, v in results.items() if v[0] is not None}
    if not results:
        print("Chat | sfimage=message color=" + DIM)
        return

    ordered = list(results.values())
    render_title(ordered)
    render_dropdown(results)


if __name__ == "__main__":
    main()
