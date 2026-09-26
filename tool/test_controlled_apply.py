"""A3-1: general controlled-apply scope tests.

The general controlled apply reuses the exact Pilot C writer/apply gates through
`assert_in_scope`; only the fixed pilot id list and the 2025-2026 year window are
generalized to an explicit Owner-approved id set. These tests are offline and do
not open a database session.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.models import PlannedPost  # noqa: E402
from ingestion.writer import (  # noqa: E402
    PILOT_C, ScopeViolation, approved_scope, assert_in_scope, assert_no_collisions,
    expected_rows,
)


def exam_plan(post_id: str, *, year: int = 2026, confidence: str = 'high',
              publishable: bool = True, content_type: str = 'exam',
              subjects=('국어', '영어'), mapping_status: str = 'unmapped') -> PlannedPost:
    occurrences = [{'source_subject_key': s, 'mapping_status': mapping_status,
                    'is_active': False} for s in subjects]
    resources = [{'source_resource_key': f'{post_id}-{s}', 'source_post_external_id': post_id,
                  'resource_type': 'question', 'link_kind': 'unknown', 'is_active': False}
                 for s in subjects]
    return PlannedPost(
        source_post={'source': 'legendstudy', 'external_post_id': post_id},
        content_item={'source_content_key': 'main', 'slug': f'legendstudy-{post_id}-main',
                      'content_type': content_type, 'is_active': False},
        exam={'year': year, 'exam_month': 9, 'grade_level': 3,
              'exam_type': 'evaluation_mock'} if content_type == 'exam' else None,
        occurrences=occurrences, resources=resources,
        confidence=confidence, publishable=publishable)


class GeneralControlledApplyTests(unittest.TestCase):
    def test_1_empty_approval_refuses_every_plan(self):
        scope = approved_scope([])
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1712')], scope)

    def test_2_approved_high_confidence_new_ids_pass(self):
        scope = approved_scope(['1712', '1711', '1649'])
        plans = [exam_plan('1712'), exam_plan('1711'), exam_plan('1649', year=2024)]
        assert_in_scope(plans, scope)  # must not raise
        assert_no_collisions(plans)

    def test_3_plan_outside_approved_is_refused(self):
        scope = approved_scope(['1712', '1711', '1649'])
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1712'), exam_plan('9999')], scope)

    def test_4_medium_confidence_approved_id_is_refused(self):
        scope = approved_scope(['1710'])
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1710', confidence='medium', publishable=False)],
                            scope)

    def test_5_low_confidence_blocking_style_is_refused(self):
        # A blocking quarantine collapses confidence to low / not publishable.
        scope = approved_scope(['1618'])
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1618', confidence='low', publishable=False)],
                            scope)

    def test_6_identity_collision_is_refused(self):
        scope = approved_scope(['1712'])
        dup = [exam_plan('1712'), exam_plan('1712')]
        assert_in_scope(dup, scope)  # scope membership ok
        with self.assertRaises(ScopeViolation):
            assert_no_collisions(dup)

    def test_7_pilot_c_scope_is_unchanged(self):
        # Pilot C keeps its 2025-2026 window and has no explicit id set.
        self.assertIsNone(PILOT_C.approved_ids)
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1649', year=2024)], PILOT_C)  # 2024 out of window
        assert_in_scope([exam_plan('1705', year=2026)], PILOT_C)  # in window, no id gate

    def test_8_general_allows_2024_csat_with_explicit_approval(self):
        scope = approved_scope(['1649'])
        assert_in_scope([exam_plan('1649', year=2024)], scope)  # open year window

    def test_9_verified_mapping_is_refused(self):
        scope = approved_scope(['1712'])
        with self.assertRaises(ScopeViolation):
            assert_in_scope([exam_plan('1712', mapping_status='verified')], scope)

    def test_10_expected_rows_counts_are_shared_core(self):
        plans = [exam_plan('1712', subjects=('국어', '영어', '수학'))]
        rows = expected_rows(plans)
        self.assertEqual(rows, {'source_posts': 1, 'content_items': 1, 'exams': 1,
                                'exam_subjects': 3, 'resources': 3})


if __name__ == '__main__':
    unittest.main()
