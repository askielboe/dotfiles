import json
import tempfile
import time
import unittest
from unittest.mock import patch
from pathlib import Path

import collector


ID = "01a0f169-b869-70c2-81c7-c4d1350a5e02"


class CollectorTests(unittest.TestCase):
    def test_waiting_precedes_active(self):
        for flag in ("waitingOnApproval", "waitingOnUserInput"):
            self.assertEqual(collector.classify({"type": "active", "activeFlags": [flag]}), "waiting")
        self.assertEqual(collector.classify({"type": "notLoaded"}), "unknown")

    def test_snapshot_and_array_patches(self):
        ipc = collector.IPC(Path("/unused"))
        ipc.desired = {ID}
        ipc.process({"method": "thread-stream-state-changed", "params": {"conversationId": ID, "change": {"type": "snapshot", "revision": 1, "conversationState": {"threadRuntimeStatus": {"type": "active", "activeFlags": []}}}}})
        ipc.process({"method": "thread-stream-state-changed", "params": {"conversationId": ID, "change": {"type": "patches", "baseRevision": 1, "revision": 2, "patches": [{"op": "add", "path": ["threadRuntimeStatus", "activeFlags", 0], "value": "waitingOnUserInput"}]}}})
        self.assertEqual(collector.classify(ipc.statuses[ID][0]), "waiting")
        ipc.process({"method": "thread-stream-state-changed", "params": {"conversationId": ID, "change": {"type": "patches", "baseRevision": 2, "revision": 3, "patches": [{"op": "remove", "path": ["threadRuntimeStatus", "activeFlags", 0]}]}}})
        self.assertEqual(collector.classify(ipc.statuses[ID][0]), "working")

    def test_missing_patch_invalidates_cache_and_requests_snapshot(self):
        ipc = collector.IPC(Path("/unused"))
        ipc.desired = {ID}
        ipc.statuses[ID] = ({"type": "idle"}, time.time())
        ipc.revisions[ID] = 1
        requests = []
        ipc.broadcast = lambda *args, **kwargs: requests.append(args)
        ipc.process({"method": "thread-stream-state-changed", "params": {"conversationId": ID, "change": {"type": "patches", "baseRevision": 2, "revision": 3, "patches": []}}})
        self.assertNotIn(ID, ipc.statuses)
        self.assertEqual(requests[0][0], "thread-stream-following-status-requested")

    def test_unrelated_patch_does_not_refresh_observation_age(self):
        ipc = collector.IPC(Path("/unused"))
        ipc.desired = {ID}
        ipc.statuses[ID] = ({"type": "active"}, 100)
        ipc.revisions[ID] = 1
        ipc.process({"method": "thread-stream-state-changed", "params": {"conversationId": ID, "change": {"type": "patches", "baseRevision": 1, "revision": 2, "patches": [{"op": "replace", "path": ["title"], "value": "unused"}]}}})
        self.assertEqual(ipc.statuses[ID][1], 100)
        self.assertEqual(ipc.revisions[ID], 2)

    def test_archive_overrides_runtime_and_stale_status_becomes_unknown(self):
        ipc = collector.IPC(Path("/unused"))
        ipc.desired = {ID}
        ipc.statuses[ID] = ({"type": "active"}, time.time() - 60)
        self.assertEqual(collector.observations(ipc, {})[ID]["state"], "unknown")
        self.assertEqual(collector.observations(ipc, {ID: (True, None)})[ID]["state"], "archived")

    def test_positive_terminal_evidence_only(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rollout.jsonl"
            stamp = "2026-09-30T08:00:00Z"
            path.write_text(json.dumps({"type": "event_msg", "timestamp": stamp, "payload": {"type": "task_complete"}}) + "\n")
            self.assertEqual(collector.lifecycle(path)[0], "idle")
            with path.open("a") as target:
                target.write(json.dumps({"type": "event_msg", "timestamp": stamp, "payload": {"type": "task_started"}}) + "\n")
            self.assertEqual(collector.lifecycle(path)[0], "unknown")

    def test_older_terminal_event_does_not_hide_live_error(self):
        ipc = collector.IPC(Path("/unused"))
        ipc.desired = {ID}
        now = time.time()
        ipc.statuses[ID] = ({"type": "systemError"}, now)
        with patch.object(collector, "lifecycle", return_value=("idle", now - 60)):
            self.assertEqual(collector.observations(ipc, {ID: (False, "/unused")})[ID]["state"], "error")
        with patch.object(collector, "lifecycle", return_value=("idle", now + 1)):
            self.assertEqual(collector.observations(ipc, {ID: (False, "/unused")})[ID]["state"], "idle")

    def test_observer_declines_ownership(self):
        ipc = collector.IPC(Path("/unused"))
        responses = []
        ipc.send = responses.append
        ipc.process({"type": "client-discovery-request", "requestId": "request1"})
        self.assertEqual(responses[0]["response"], {"canHandle": False})


if __name__ == "__main__":
    unittest.main()
