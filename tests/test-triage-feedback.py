#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "triage-feedback.py"
SPEC = importlib.util.spec_from_file_location("triage_feedback", SCRIPT)
assert SPEC and SPEC.loader
TRIAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TRIAGE)


def event(labels: list[str], body: str = "", number: int = 42) -> dict:
    return {
        "repository": {"full_name": "mitzracing/live-for-speed-linux"},
        "issue": {
            "number": number,
            "body": body,
            "labels": [{"name": name} for name in labels],
        },
    }


class CaptureHandler(BaseHTTPRequestHandler):
    requests: list[dict] = []

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length))
        self.__class__.requests.append(
            {
                "path": self.path,
                "authorization": self.headers.get("Authorization"),
                "payload": payload,
            }
        )
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b"{}")

    def log_message(self, _format: str, *_args: object) -> None:
        return


class FeedbackTriageTest(unittest.TestCase):
    def test_bug_enters_manjaro_contributor_queue(self) -> None:
        plan = TRIAGE.build_plan(
            event(
                ["type:bug"],
                "### Linux distribution\n\nManjaro Linux\n\n### What happened?\n\nWindow closed.",
            )
        )
        self.assertEqual(
            plan["labels"],
            ["distro:manjaro", "help wanted", "status:needs-reproduction"],
        )
        self.assertIn("contributor queue", plan["comments"][0])
        self.assertFalse(plan["sensitive"])

    def test_arch_compatibility_preserves_exact_runtime_guidance(self) -> None:
        plan = TRIAGE.build_plan(
            event(["type:compatibility"], "### Linux distribution\n\nArch Linux")
        )
        self.assertEqual(
            plan["labels"],
            ["distro:arch", "help wanted", "status:needs-reproduction"],
        )
        self.assertIn("exact Wine and payload pins", plan["comments"][0])

    def test_feature_waits_for_maintainer(self) -> None:
        plan = TRIAGE.build_plan(event(["type:feature"]))
        self.assertEqual(plan["labels"], ["status:needs-maintainer"])
        self.assertIn("before implementation", plan["comments"][0])

    def test_unknown_ticket_waits_for_classification(self) -> None:
        plan = TRIAGE.build_plan(event([]))
        self.assertEqual(plan["labels"], ["status:needs-maintainer"])
        self.assertIn("did not use a recognized support form", plan["comments"][0])

    def test_sensitive_pattern_is_flagged_without_echo(self) -> None:
        secret = "ghp_" + "abcdefghijklmnopqrstuvwxyz" + "0123456789"
        plan = TRIAGE.build_plan(event(["type:feedback"], f"### Notes\n\n{secret}"))
        self.assertTrue(plan["sensitive"])
        self.assertIn("status:possible-sensitive", plan["labels"])
        self.assertNotIn(secret, json.dumps(plan))
        self.assertIn("Possible sensitive data", plan["comments"][0])

    def test_apply_posts_labels_and_static_comment_to_mock_github(self) -> None:
        CaptureHandler.requests = []
        server = ThreadingHTTPServer(("127.0.0.1", 0), CaptureHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            source_event = event(["type:bug"])
            plan = TRIAGE.build_plan(source_event)
            TRIAGE.apply_plan(
                source_event,
                plan,
                "test-token",
                f"http://127.0.0.1:{server.server_address[1]}",
            )
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)

        self.assertEqual(len(CaptureHandler.requests), 2)
        labels_request, comment_request = CaptureHandler.requests
        self.assertEqual(labels_request["path"], "/repos/mitzracing/live-for-speed-linux/issues/42/labels")
        self.assertEqual(
            labels_request["payload"],
            {"labels": ["help wanted", "status:needs-reproduction"]},
        )
        self.assertEqual(comment_request["path"], "/repos/mitzracing/live-for-speed-linux/issues/42/comments")
        self.assertIn("contributor queue", comment_request["payload"]["body"])
        self.assertEqual(labels_request["authorization"], "Bearer test-token")

    def test_cli_dry_run_matches_library_plan(self) -> None:
        source_event = event(["type:feedback"], number=7)
        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as handle:
            json.dump(source_event, handle)
            handle.flush()
            result = subprocess.run(
                [str(SCRIPT), "--dry-run", handle.name],
                check=True,
                capture_output=True,
                text=True,
                timeout=20,
            )
        plan = json.loads(result.stdout)
        self.assertEqual(plan["issue_number"], 7)
        self.assertEqual(plan["labels"], ["status:needs-maintainer"])


if __name__ == "__main__":
    unittest.main()
