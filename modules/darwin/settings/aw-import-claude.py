"""Import Claude Code session activity into ActivityWatch.

Reads Claude Code's per-session JSONL logs under ~/.claude/projects, derives
active-time intervals per working directory (the real "what am I working on"
axis), and posts them to a local ActivityWatch bucket via the REST API.

Idempotency: we only post intervals that have *closed* (no activity for GAP
seconds after their last event) and whose end falls in the window
(prev_frontier, now - GAP]. A state file records the frontier, so re-runs post
each newly-closed interval exactly once regardless of how cwds interleave.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import socket
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
STATE_PATH = os.path.expanduser("~/.local/state/aw-import-claude/frontier")
AW_HOST = os.environ.get("AW_HOST", "127.0.0.1")
AW_PORT = int(os.environ.get("AW_PORT", "5600"))
GAP = int(os.environ.get("AW_CLAUDE_GAP", "480"))        # split interval on >8min silence
PAD = int(os.environ.get("AW_CLAUDE_PAD", "60"))         # tail pad / min interval length
CLIENT = "aw-import-claude"
BUCKET_TYPE = "claude.session.activity"


def hostname() -> str:
    return os.environ.get("AW_HOSTNAME") or socket.gethostname().split(".")[0]


def bucket_id() -> str:
    return f"{CLIENT}_{hostname()}"


def parse_ts(s: str) -> float | None:
    """ISO-8601 (…Z) -> epoch seconds."""
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
    except (ValueError, AttributeError):
        return None


def read_events() -> dict[str, list[float]]:
    """Collect event timestamps grouped by cwd across all session logs."""
    by_cwd: dict[str, list[float]] = defaultdict(list)
    for path in glob.glob(os.path.join(PROJECTS_DIR, "*", "*.jsonl")):
        try:
            with open(path, encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        rec = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    ts, cwd = rec.get("timestamp"), rec.get("cwd")
                    if not ts or not cwd:
                        continue
                    epoch = parse_ts(ts)
                    if epoch is not None:
                        by_cwd[cwd].append(epoch)
        except OSError:
            continue
    return by_cwd


def build_intervals(by_cwd: dict[str, list[float]]) -> list[dict]:
    """Coalesce per-cwd timestamps into [start, end] intervals split on GAP."""
    intervals: list[dict] = []
    for cwd, times in by_cwd.items():
        times.sort()
        start = prev = times[0]
        for t in times[1:]:
            if t - prev > GAP:
                intervals.append(mk(cwd, start, prev))
                start = t
            prev = t
        intervals.append(mk(cwd, start, prev))
    intervals.sort(key=lambda iv: iv["end"])
    return intervals


def mk(cwd: str, start: float, last: float) -> dict:
    end = last + PAD
    return {
        "cwd": cwd,
        "start": start,
        "end": end,
        "duration": end - start,
        "project": os.path.basename(cwd.rstrip("/")) or cwd,
    }


def http(method: str, path: str, body=None) -> tuple[int, bytes]:
    url = f"http://{AW_HOST}:{AW_PORT}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def server_up() -> bool:
    """True iff aw-server answers. A refused connection (URLError, not HTTPError)
    means the app just isn't running yet — expected at login, not an error."""
    try:
        with urllib.request.urlopen(f"http://{AW_HOST}:{AW_PORT}/api/0/info", timeout=5):
            return True
    except urllib.error.URLError:
        return False


def ensure_bucket() -> None:
    http(
        "POST",
        f"/api/0/buckets/{bucket_id()}",
        {"client": CLIENT, "type": BUCKET_TYPE, "hostname": hostname()},
    )  # 200 created / 304 already exists — either is fine


def iso(epoch: float) -> str:
    return datetime.fromtimestamp(epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def post_events(intervals: list[dict]) -> None:
    payload = [
        {
            "timestamp": iso(iv["start"]),
            "duration": round(iv["duration"], 3),
            "data": {"project": iv["project"], "path": iv["cwd"]},
        }
        for iv in intervals
    ]
    status, resp = http("POST", f"/api/0/buckets/{bucket_id()}/events", payload)
    if status >= 300:
        sys.exit(f"aw event post failed ({status}): {resp[:200]!r}")


def load_frontier() -> float:
    try:
        with open(STATE_PATH) as fh:
            return float(fh.read().strip())
    except (OSError, ValueError):
        return 0.0


def save_frontier(v: float) -> None:
    os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
    with open(STATE_PATH, "w") as fh:
        fh.write(repr(v))


def fmt_hours(seconds: float) -> str:
    return f"{seconds / 3600:.1f}h"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true", help="compute + print stats, post nothing, don't advance frontier")
    ap.add_argument("--all", action="store_true", help="ignore frontier: report/post the full history")
    args = ap.parse_args()

    by_cwd = read_events()
    if not by_cwd:
        print("no Claude events found", file=sys.stderr)
        return
    intervals = build_intervals(by_cwd)

    frontier_prev = 0.0 if args.all else load_frontier()
    frontier_now = time.time() - GAP
    fresh = [iv for iv in intervals if frontier_prev < iv["end"] <= frontier_now]

    if args.dry_run:
        totals: dict[str, float] = defaultdict(float)
        for iv in intervals:
            totals[iv["project"]] += iv["duration"]
        span_lo = iso(min(iv["start"] for iv in intervals))
        span_hi = iso(max(iv["end"] for iv in intervals))
        print(f"cwds: {len(by_cwd)}  intervals: {len(intervals)}  span: {span_lo} .. {span_hi}")
        print(f"newly-closed since frontier ({'all' if args.all else iso(frontier_prev)}): {len(fresh)} intervals")
        print("\ntop projects by total active time:")
        for proj, secs in sorted(totals.items(), key=lambda kv: -kv[1])[:25]:
            print(f"  {fmt_hours(secs):>7}  {proj}")
        return

    if not fresh:
        return
    if not server_up():
        print("aw-server not reachable; skipping (will retry next run)", file=sys.stderr)
        return
    ensure_bucket()
    post_events(fresh)
    if not args.all:
        save_frontier(frontier_now)
    print(f"posted {len(fresh)} intervals ({fmt_hours(sum(iv['duration'] for iv in fresh))}) to {bucket_id()}")


if __name__ == "__main__":
    main()
