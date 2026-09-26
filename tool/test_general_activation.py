"""Offline contract tests for the general controlled activation path (A3-1).

These cover `publish_scope`, which activates an explicit approved post set through
the same scope-parameterized ACTIVATE SQL and affected-row guards as Pilot C. No
database is used; a scripted fake session returns per-query rows. Pilot C's own
tests (test_publish_pilot_c) assert the unchanged Pilot C path.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from publish_pilot_c import (  # noqa: E402
    PROJECT_REF, PublicationRefused, ScopeCounts, publish_scope,
)

EXPECT = ScopeCounts(3, 3, 3, 36, 75)


class FakeSession:
    """Dispatches by SQL so publish_scope sees a coherent pre/post state."""

    def __init__(self, *, scope=(3, 3, 3, 36, 75), active_before=(0, 0, 0),
                 invariants=(0, 0, 0, 0), affected=(3, 36, 75),
                 active_after=(3, 36, 75), totals_before=None, totals_after=None,
                 after_scope=None):
        self.scope = scope
        self.active_before = active_before
        self.invariants = invariants
        self.affected = affected
        self.active_after = active_after
        self.totals_before = totals_before or {'content_items': 26, 'exam_subjects': 399,
                                                'resources': 814}
        self.totals_after = totals_after or dict(self.totals_before)
        self.after_scope = after_scope or scope
        self.activated = False
        self.begun = self.committed = self.rolled_back = False

    def begin(self): self.begun = True
    def commit(self): self.committed = True
    def rollback(self): self.rolled_back = True

    def execute(self, sql, params=()):
        # ACTIVATE_* are SCOPE_CTE + "UPDATE ..." so they start with WITH; match
        # on the UPDATE target substring, checked before the read queries.
        if 'UPDATE public.content_items' in sql:
            self.activated = True
            return [('id',)] * self.affected[0]
        if 'UPDATE public.exam_subjects' in sql:
            return [('id',)] * self.affected[1]
        if 'UPDATE public.resources' in sql:
            return [('id',)] * self.affected[2]
        if "'verified'" in sql:                    # SCOPE_INVARIANTS_QUERY
            return [tuple(self.invariants)]
        if 'WHERE c.is_active' in sql:              # SCOPE_ACTIVE_QUERY
            return [tuple(self.active_after if self.activated else self.active_before)]
        if sql.startswith('select count(*) from public.'):
            table = sql.split('public.')[1].strip()
            src = self.totals_after if self.activated else self.totals_before
            return [(src[table],)]
        if 'FROM pilot_posts' in sql:               # SCOPE_QUERY
            return [tuple(self.after_scope if self.activated else self.scope)]
        return []


class GeneralActivationTests(unittest.TestCase):
    def test_happy_path_activates_and_commits(self):
        s = FakeSession()
        self.assertEqual(publish_scope(s, ['1712', '1711', '1649'], EXPECT), 'published')
        self.assertTrue(s.begun and s.committed and not s.rolled_back)

    def test_scope_shape_mismatch_refused(self):
        s = FakeSession(scope=(2, 2, 2, 24, 50))
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711'], EXPECT)
        self.assertTrue(s.rolled_back and not s.committed)

    def test_target_not_inactive_refused(self):
        s = FakeSession(active_before=(1, 0, 0))
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711', '1649'], EXPECT)
        self.assertFalse(s.committed)

    def test_verified_signed_blocking_orphan_each_refuse(self):
        for inv in ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)):
            s = FakeSession(invariants=inv)
            with self.subTest(inv=inv), self.assertRaises(PublicationRefused):
                publish_scope(s, ['1712', '1711', '1649'], EXPECT)
            self.assertFalse(s.committed)

    def test_affected_row_mismatch_rolls_back(self):
        s = FakeSession(affected=(3, 35, 75))  # one exam_subject short
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711', '1649'], EXPECT)
        self.assertTrue(s.rolled_back and not s.committed)

    def test_postflight_active_mismatch_refused(self):
        s = FakeSession(active_after=(3, 36, 74))
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711', '1649'], EXPECT)
        self.assertFalse(s.committed)

    def test_row_totals_change_refused(self):
        s = FakeSession(totals_after={'content_items': 27, 'exam_subjects': 399,
                                      'resources': 814})
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711', '1649'], EXPECT)
        self.assertTrue(s.rolled_back and not s.committed)

    def test_scope_changed_mid_transaction_refused(self):
        s = FakeSession(after_scope=(3, 3, 3, 36, 74))
        with self.assertRaises(PublicationRefused):
            publish_scope(s, ['1712', '1711', '1649'], EXPECT)
        self.assertFalse(s.committed)


if __name__ == '__main__':
    unittest.main()
