"""Offline contract tests for the Pilot C publication package."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from publish_pilot_c import (  # noqa: E402
    ACTIVATE_CONTENT, ACTIVATE_OCCURRENCES, ACTIVATE_RESOURCES, EXPECTED,
    EXPECTED_ACTIVE, PROJECT_REF, RESOURCE_BREAKDOWN, ScopeCounts,
    PublicationRefused, active_mode, anon_acceptance_sql, assert_project,
    assert_publish_allowed, rollback_sql, validate_preflight,
)
import publish_pilot_c as package  # noqa: E402


def clean_snapshot():
    value = dict(EXPECTED)
    value.update({f"active_{k}": 0 for k in EXPECTED_ACTIVE})
    value.update(active_subjects=23, provisional=363, verified=0, signed_urls=0,
                 duplicates=0, orphans=0, blocking_quarantine=0,
                 resource_breakdown=dict(RESOURCE_BREAKDOWN))
    return value


SCOPE = ScopeCounts(23, 23, 23, 363, 739)


class PublicationContractTests(unittest.TestCase):
    class Session:
        def __init__(self, rows=()):
            self.rows = list(rows)
            self.begun = self.committed = self.rolled_back = False
        def begin(self): self.begun = True
        def commit(self): self.committed = True
        def rollback(self): self.rolled_back = True
        def execute(self, _sql, _params=()): return list(self.rows)

    def test_wrong_project_rejected(self):
        with self.assertRaises(PublicationRefused): assert_project("muselry")

    def test_missing_approval_rejected(self):
        with self.assertRaises(PublicationRefused):
            assert_publish_allowed(PROJECT_REF, False)

    def test_clean_inactive_allowed(self):
        validate_preflight(clean_snapshot(), SCOPE)
        self.assertEqual(active_mode({k: 0 for k in EXPECTED_ACTIVE}), "publish")

    def test_exact_affected_row_counts_are_required(self):
        self.assertEqual(package.activate(self.Session([("x",)] * 23), ACTIVATE_CONTENT, 23), 23)
        with self.assertRaises(PublicationRefused):
            package.activate(self.Session([("x",)] * 22), ACTIVATE_CONTENT, 23)
        with self.assertRaises(PublicationRefused):
            package.activate(self.Session([("x",)] * 740), ACTIVATE_RESOURCES, 739)

    def test_mid_transaction_failure_rolls_back(self):
        session = self.Session()
        clean = clean_snapshot()
        original = package.read_snapshot
        package.read_snapshot = lambda _session: (clean, SCOPE)
        try:
            with self.assertRaises(PublicationRefused): package.publish(session)
        finally:
            package.read_snapshot = original
        self.assertTrue(session.begun)
        self.assertFalse(session.committed)
        self.assertTrue(session.rolled_back)

    def test_already_published_is_noop(self):
        self.assertEqual(active_mode(dict(EXPECTED_ACTIVE)), "already_published")

    def test_partial_active_rejected(self):
        with self.assertRaises(PublicationRefused):
            active_mode({"content_items": 23, "exam_subjects": 0, "resources": 0})

    def test_all_preflight_gates_reject_mismatch(self):
        for key, value in (("source_posts", 22), ("provisional", 362),
                           ("verified", 1), ("signed_urls", 1), ("duplicates", 1),
                           ("orphans", 1), ("blocking_quarantine", 1)):
            snapshot = clean_snapshot(); snapshot[key] = value
            with self.subTest(key=key), self.assertRaises(PublicationRefused):
                validate_preflight(snapshot, SCOPE)

    def test_scope_and_breakdown_reject(self):
        with self.assertRaises(PublicationRefused):
            validate_preflight(clean_snapshot(), ScopeCounts(22, 23, 23, 363, 739))
        snapshot = clean_snapshot(); snapshot["resource_breakdown"]["question"] = 359
        with self.assertRaises(PublicationRefused): validate_preflight(snapshot, SCOPE)

    def test_only_is_active_mutation_and_exact_chain(self):
        for sql in (ACTIVATE_CONTENT, ACTIVATE_OCCURRENCES, ACTIVATE_RESOURCES):
            self.assertIn("SET is_active = true", sql)
            self.assertNotRegex(sql.lower(), r"\b(insert|delete)\b")
            self.assertIn("pilot_", sql)
            self.assertNotIn("public.subjects", sql.lower())
            self.assertNotIn("quarantine", sql.lower())
        self.assertIn("FROM pilot_content", ACTIVATE_CONTENT)
        self.assertIn("FROM pilot_occurrences", ACTIVATE_OCCURRENCES)
        self.assertIn("FROM pilot_resources", ACTIVATE_RESOURCES)

    def test_rollback_has_no_delete_and_exact_scope(self):
        for sql in rollback_sql():
            self.assertNotRegex(sql.lower(), r"\b(delete|insert)\b")
            self.assertIn("pilot_", sql)
            self.assertIn("SET is_active = false", sql)

    def test_anon_acceptance_reads_public_projection_and_private_denial(self):
        sql = anon_acceptance_sql()
        self.assertIn("set local role anon", sql.lower())
        self.assertIn("source_posts", sql)
        self.assertIn("ingestion_quarantine", sql)
        self.assertIn("rollback", sql.lower())


if __name__ == "__main__":
    unittest.main()
