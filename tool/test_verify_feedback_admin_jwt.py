"""Offline safety checks for the admin Feedback verifier; no network requests."""

import contextlib
import io
import unittest
from pathlib import Path
from unittest.mock import patch

import verify_feedback_admin_jwt as verifier


class FeedbackAdminVerifierOfflineTests(unittest.TestCase):
    def test_default_main_is_offline_only(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), patch.object(verifier, "Transport", side_effect=AssertionError("network")):
            self.assertEqual(verifier.main([]), 0)
        self.assertIn("OFFLINE_ONLY", output.getvalue())

    def test_admin_uuid_guard_and_identity_separation_are_explicit(self):
        self.assertEqual(verifier.ADMIN_EMAIL, "admin@legendstudy.com")
        self.assertEqual(verifier.EXPECTED_ADMIN_UUID, "d5eab102-da92-4c4c-9adb-16d2c9d20e4c")
        self.assertEqual(verifier.EXPECTED_USER_A_UUID, "18f916d4-9fed-4736-b454-02b972e85344")
        self.assertNotEqual(verifier.EXPECTED_ADMIN_UUID, verifier.EXPECTED_USER_A_UUID)

    def test_admin_fixture_is_test_marked_and_exactly_eight_columns(self):
        payload = verifier.admin_fixture_payload("abc123")
        self.assertEqual(tuple(payload), verifier.ALLOWED_INSERT_COLUMNS)
        self.assertTrue(payload["title"].startswith("[TEST] Feedback admin acceptance abc123"))
        self.assertFalse(verifier.FORBIDDEN_INSERT_COLUMNS.intersection(payload))

    def test_source_contains_admin_predicate_and_status_workflow(self):
        source = Path(verifier.__file__).read_text()
        self.assertIn("/rest/v1/rpc/is_feedback_admin", source)
        self.assertIn('"ADMIN_PREDICATE_FALSE"', source)
        self.assertIn('"A_PREDICATE_TRUE"', source)
        self.assertIn('self.update_status("ADMIN", "reviewing"', source)
        self.assertIn('self.update_status("A", "resolved"', source)
        self.assertIn('self.update_status("ADMIN", "resolved"', source)
        self.assertNotIn("def cleanup", source)
        self.assertNotIn("DELETE", source)
        self.assertNotIn("service_role", source.lower())
        self.assertNotIn("feedback_notifications?", source)

    def test_authenticated_request_sites_use_explicit_labels(self):
        source = Path(verifier.__file__).read_text()
        self.assertIn('data=payload,\n            label="A",', source)
        self.assertIn('data={},\n            label=label,', source)
        self.assertIn('data={"status": status},\n            label=label,', source)
        self.assertNotIn('self.call("GET", f"/rest/v1/{TABLE}?{query}", label)', source)

    def test_call_keyword_label_adds_the_expected_bearer(self):
        class RecordingTransport:
            def __init__(self):
                self.tokens = []

            def __call__(self, method, path, data=None, token=None, prefer=None):
                self.tokens.append(token)
                if path.endswith("is_feedback_admin"):
                    return verifier.Response(200, True)
                if token == "a-token":
                    return verifier.Response(403, {"code": "42501"})
                return verifier.Response(204, None)

        transport = RecordingTransport()
        app = verifier.AdminVerifier(
            {"SUPABASE_URL": verifier.HOST, "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_offline"},
            transport=transport,
            run_id="abc123",
        )
        app.sessions["ADMIN"] = {"id": verifier.EXPECTED_ADMIN_UUID, "token": "admin-token"}
        app.sessions["A"] = {"id": verifier.EXPECTED_USER_A_UUID, "token": "a-token"}
        app.fixture_id = "00000000-0000-0000-0000-000000000002"
        app.predicate("ADMIN")
        app.predicate("A")
        app.update_status("ADMIN", "reviewing", "TEST")
        app.update_status("A", "resolved", "TEST")
        self.assertEqual(transport.tokens, ["admin-token", "a-token", "admin-token", "a-token"])


if __name__ == "__main__":
    unittest.main()
