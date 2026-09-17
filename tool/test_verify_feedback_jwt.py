"""Offline safety checks for the Feedback JWT verifier; no network requests."""

import contextlib
import io
import unittest
from pathlib import Path
from unittest.mock import patch

import verify_feedback_jwt as verifier


class FeedbackVerifierOfflineTests(unittest.TestCase):
    def test_default_main_is_offline_only(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), patch.object(verifier, "Transport", side_effect=AssertionError("network")):
            self.assertEqual(verifier.main([]), 0)
        self.assertIn("OFFLINE_ONLY", output.getvalue())

    def test_project_guard_requires_exact_project_and_rejects_service_role(self):
        key = "sb_publishable_offline"
        self.assertEqual(verifier.project_guard({"SUPABASE_URL": verifier.HOST, "SUPABASE_PUBLISHABLE_KEY": key}), key)
        with self.assertRaises(verifier.AcceptanceFailure):
            verifier.project_guard({"SUPABASE_URL": "https://other.supabase.co", "SUPABASE_PUBLISHABLE_KEY": key})
        with self.assertRaises(verifier.AcceptanceFailure):
            verifier.project_guard({"SUPABASE_URL": verifier.HOST, "SUPABASE_PUBLISHABLE_KEY": key, "SUPABASE_SERVICE_ROLE_KEY": "x"})

    def test_payload_is_exactly_eight_columns_and_test_marked(self):
        payload = verifier.feedback_payload("abc123", "A")
        self.assertEqual(tuple(payload), verifier.ALLOWED_INSERT_COLUMNS)
        self.assertTrue(payload["title"].startswith("[TEST] Feedback RLS acceptance abc123"))
        self.assertFalse(verifier.FORBIDDEN_INSERT_COLUMNS.intersection(payload))

    def test_deny_semantics_accept_only_error_or_empty_result(self):
        for response in (verifier.Response(401, {}), verifier.Response(403, {}), verifier.Response(200, []), verifier.Response(204, None)):
            verifier.Verifier.__new__(verifier.Verifier).deny_or_empty(response, "TEST")
        with self.assertRaises(verifier.AcceptanceFailure):
            verifier.Verifier.__new__(verifier.Verifier).deny_or_empty(verifier.Response(200, [{"status": "resolved"}]), "TEST")

    def test_source_contains_safety_contracts_and_no_cleanup(self):
        source = Path(verifier.__file__).read_text()
        self.assertIn("--run-production-acceptance", source)
        self.assertIn("getpass.getpass", source)
        self.assertIn("A_STATUS_CHANGED", source)
        self.assertIn("outbox_exactly_one=OWNER_SQL_READ_ONLY_REQUIRED", source)
        self.assertIn("SUPABASE_SERVICE_ROLE_KEY", source)
        self.assertNotIn("DELETE", source)


if __name__ == "__main__":
    unittest.main()
