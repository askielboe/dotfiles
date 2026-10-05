import argparse
import copy
from contextlib import closing
import datetime
import json
import logging
import socket
import sqlite3
import struct
import threading
import time
import urllib.request
from pathlib import Path


LOG = logging.getLogger("codex-status-collector")
MAX_FRAME = 64 * 1024 * 1024


def apply_status_patch(status, patch):
    path = patch.get("path", [])
    if not path or path[0] != "threadRuntimeStatus":
        return status
    operation = patch.get("op")
    value = patch.get("value")
    if len(path) == 1:
        if operation == "remove":
            return None
        if not isinstance(value, dict):
            raise ValueError("Invalid runtime status")
        return copy.deepcopy(value)
    if status is None:
        raise ValueError("Patch without snapshot")
    result = copy.deepcopy(status)
    parent = result
    for key in path[1:-1]:
        parent = parent[int(key)] if isinstance(parent, list) else parent[key]
    key = path[-1]
    if isinstance(parent, list):
        index = len(parent) if key == "-" else int(key)
        if operation == "remove":
            parent.pop(index)
        elif operation == "add":
            parent.insert(index, value)
        else:
            parent[index] = value
    elif operation == "remove":
        parent.pop(key, None)
    else:
        parent[key] = value
    return result


def classify(status):
    if not isinstance(status, dict):
        return "unknown"
    flags = status.get("activeFlags") or []
    if "waitingOnApproval" in flags or "waitingOnUserInput" in flags:
        return "waiting"
    return {"active": "working", "idle": "idle", "systemError": "error"}.get(status.get("type"), "unknown")


def lifecycle(path):
    # Terminal events provide positive idle evidence for threads without a live owner.
    try:
        with open(path, "rb") as source:
            source.seek(0, 2)
            source.seek(max(0, source.tell() - 256 * 1024))
            lines = source.read().splitlines()
        for line in reversed(lines):
            try:
                event = json.loads(line)
            except (ValueError, UnicodeDecodeError):
                continue
            if event.get("type") != "event_msg":
                continue
            kind = event.get("payload", {}).get("type")
            if kind not in {"task_started", "task_complete", "turn_aborted", "task_failed"}:
                continue
            stamp = datetime.datetime.fromisoformat(event["timestamp"].replace("Z", "+00:00")).timestamp()
            return ("idle" if kind in {"task_complete", "turn_aborted"} else "unknown", stamp)
    except (OSError, ValueError, KeyError, TypeError):
        pass
    return "unknown", 0


class IPC:
    def __init__(self, home):
        self.path = str(home / "ipc/ipc.sock")
        self.lock = threading.RLock()
        self.write_lock = threading.Lock()
        self.desired = set()
        self.statuses = {}
        self.revisions = {}
        self.sock = None
        self.client = None
        self.changed = threading.Event()

    def send(self, message):
        body = json.dumps(message, separators=(",", ":")).encode()
        with self.write_lock:
            sock = self.sock
            if sock is not None:
                sock.sendall(struct.pack("<I", len(body)) + body)

    def broadcast(self, method, ident, **kwargs):
        self.send({"type": "broadcast", "method": method, "version": 1,
                   "sourceClientId": self.client,
                   "params": {"conversationId": ident, "hostId": "local", **kwargs}})

    def refresh(self, identifiers):
        with self.lock:
            desired = set(identifiers)
            removals = self.desired - desired
            self.desired = desired
            for ident in removals:
                self.statuses.pop(ident, None)
                self.revisions.pop(ident, None)
            if not self.client:
                return
            for ident in removals:
                self.broadcast("thread-stream-following-changed", ident, following=False)
            for ident in desired:
                self.broadcast("thread-stream-following-changed", ident, following=True)
                self.broadcast("thread-stream-following-status-requested", ident)

    def process(self, message):
        # Discovery must answer negatively so this observer never delays owner routing.
        if message.get("type") == "client-discovery-request":
            self.send({"type": "client-discovery-response", "requestId": message.get("requestId"),
                       "response": {"canHandle": False}})
            return
        if message.get("type") == "request":
            self.send({"type": "response", "requestId": message.get("requestId"),
                       "resultType": "error", "error": "no-handler-for-request"})
            return
        if message.get("method") == "initialize" and message.get("type") == "response":
            client = message.get("result", {}).get("clientId")
            if not client:
                raise ValueError("IPC initialization failed")
            with self.lock:
                self.client = client
                self.refresh(self.desired)
            LOG.info("Connected to desktop status socket")
            return
        if message.get("method") != "thread-stream-state-changed":
            return
        params = message.get("params", {})
        ident = params.get("conversationId")
        if params.get("hostId", "local") != "local":
            return
        change = params.get("change", {})
        with self.lock:
            if ident not in self.desired:
                return
            try:
                if change.get("type") == "snapshot":
                    status = change["conversationState"].get("threadRuntimeStatus")
                elif change.get("type") == "patches":
                    if self.revisions.get(ident) != change.get("baseRevision"):
                        raise ValueError("Missing IPC patch")
                    status = self.statuses.get(ident, (None, 0))[0]
                    status_changed = False
                    for patch in change.get("patches", []):
                        if (patch.get("path") or [None])[0] == "threadRuntimeStatus":
                            status_changed = True
                            status = apply_status_patch(status, patch)
                    self.revisions[ident] = change["revision"]
                    if not status_changed:
                        return
                else:
                    return
                self.revisions[ident] = change["revision"]
                self.statuses[ident] = (status, time.time())
                self.changed.set()
            except (KeyError, ValueError, TypeError, IndexError):
                self.statuses.pop(ident, None)
                self.revisions.pop(ident, None)
                self.broadcast("thread-stream-following-status-requested", ident)

    def run(self):
        while True:
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            try:
                sock.settimeout(10)
                sock.connect(self.path)
                with self.lock:
                    self.sock = sock
                self.send({"type": "request", "requestId": "todoist-status-initialize",
                           "sourceClientId": "initializing-client", "version": 1,
                           "method": "initialize", "params": {"clientType": "todoist-status-collector"}, "timeoutMs": 5000})
                buffer = bytearray()
                while True:
                    try:
                        chunk = sock.recv(65536)
                    except socket.timeout:
                        continue
                    if not chunk:
                        raise EOFError("Desktop disconnected")
                    buffer.extend(chunk)
                    while len(buffer) >= 4:
                        length = struct.unpack("<I", buffer[:4])[0]
                        if not 0 < length <= MAX_FRAME:
                            raise ValueError("Invalid IPC frame size")
                        if len(buffer) < length + 4:
                            break
                        message = json.loads(buffer[4:length + 4])
                        del buffer[:length + 4]
                        self.process(message)
            except (OSError, EOFError, ValueError) as exc:
                LOG.info("Desktop status unavailable: %s", type(exc).__name__)
            finally:
                with self.lock:
                    self.sock = None
                    self.client = None
                    self.statuses.clear()
                    self.revisions.clear()
                    self.changed.set()
                sock.close()
            time.sleep(5)


def metadata(home, identifiers):
    result = {}
    for database in (home / "sqlite/state_5.sqlite", home / "state_5.sqlite"):
        if not database.exists():
            continue
        try:
            with closing(sqlite3.connect(database.as_uri() + "?mode=ro", uri=True, timeout=1)) as db:
                for ident in identifiers:
                    row = db.execute("SELECT archived,rollout_path FROM threads WHERE id=?", (ident,)).fetchone()
                    if row:
                        result[ident] = row
            if len(result) == len(identifiers):
                break
        except sqlite3.Error:
            LOG.warning("Cannot read desktop thread metadata")
    return result


def observations(ipc, records):
    now = time.time()
    result = {}
    with ipc.lock:
        live = dict(ipc.statuses)
        desired = set(ipc.desired)
    for ident in desired:
        state, stamp = "unknown", now
        archived, rollout = records.get(ident, (False, None))
        if archived:
            state = "archived"
        else:
            status, observed = live.get(ident, (None, 0))
            terminal, event_at = lifecycle(rollout) if rollout else ("unknown", 0)
            if now - observed <= 45 and classify(status) != "unknown":
                state, stamp = classify(status), observed
                if event_at > observed:
                    state, stamp = terminal, now
            elif terminal == "idle":
                state = "idle"
        result[ident] = {"state": state, "age_seconds": max(0, min(86400, now - stamp))}
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--token-file", required=True)
    parser.add_argument("--codex-home", default=str(Path.home() / ".codex"))
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    ipc = IPC(Path(args.codex_home))
    threading.Thread(target=ipc.run, daemon=True).start()
    url = args.url.rstrip("/")

    def request(path, body=None):
        token = Path(args.token_file).read_text().strip()
        if not token:
            raise ValueError("Missing collector credential")
        req = urllib.request.Request(url + path, headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
                                     data=json.dumps(body).encode() if body is not None else None)
        with urllib.request.urlopen(req, timeout=15) as response:
            return json.loads(response.read(1024 * 1024))

    next_refresh = 0
    while True:
        try:
            if time.monotonic() >= next_refresh:
                desired = request("/v1/threads")["threads"]
                ipc.refresh(desired)
                next_refresh = time.monotonic() + 15
            records = metadata(Path(args.codex_home), ipc.desired)
            request("/v1/observations", {"observations": observations(ipc, records)})
        except Exception as exc:
            LOG.warning("Status delivery failed: %s", type(exc).__name__)
        ipc.changed.wait(5)
        ipc.changed.clear()
        time.sleep(0.5)


if __name__ == "__main__":
    main()
