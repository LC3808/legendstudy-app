"""Observed foreign-language labels, without inventing canonical subjects."""
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ingestion import parser
from ingestion.delta import safe_observation_fingerprint
from ingestion.normalizer import normalize
from ingestion.writer import approved_scope, assert_in_scope, ScopeViolation
from ingestion.parser import split_resource_kind, split_subject
from test_ingestion import raw, att, CRAWLED_AT

LABELS = ('독일어', '프랑스어', '스페인어', '중국어', '일본어',
          '러시아어', '아랍어', '베트남어', '한문')


class ForeignLabelTests(unittest.TestCase):
    def post(self, labels):
        return raw(post_id='9999', title='[2026년 9월 시행] 2027학년도 9월 모의평가',
                   attachments=[att(f'{i}/{kind}', f'2027학년도 9월 모의평가_f {label} {kind}.pdf')
                                for i, label in enumerate(labels)
                                for kind in ('문제', '정답,해설')])

    def test_observed_labels_recognized_without_post_id_exception(self):
        for label in LABELS:
            for kind in ('문제', '정답,해설'):
                left, _, _ = split_resource_kind(f'2027학년도 9월 모의평가_f {label} {kind}.pdf')
                self.assertEqual(split_subject(left), (label, False))
        plan = normalize(self.post(LABELS), CRAWLED_AT, map_subjects=True)
        self.assertEqual(len(plan.occurrences), 9)
        self.assertEqual(len(plan.resources), 18)
        self.assertNotIn('resource_subject_unknown', [q.kind for q in plan.quarantine])
        # Never invent a v1 subject for an unmapped foreign label: the occurrence
        # publishes with its raw label and subject_id NULL, and the taxonomy gap is
        # recorded as a deferred advisory (completed in a later taxonomy wave).
        self.assertEqual(sum(q.kind == 'subject_taxonomy_gap' for q in plan.quarantine), 9)
        # Product decision (2026-09-26): a non-core taxonomy gap (제2외국어/한문) is a
        # deferred advisory, not a whole-post publication blocker. The core exam is
        # publishable now; the unmapped labels are filled in Wave 1.
        self.assertEqual(plan.confidence, 'high')
        self.assertTrue(plan.publishable)
        assert_in_scope([plan], approved_scope([9999]))  # must not raise
        self.assertTrue(all(o.get('subject_id') is None for o in plan.occurrences))

    def test_blocking_metadata_still_holds_whole_post(self):
        # Safety preserved: a real structural/blocking gap (no parseable exam
        # year/month) still holds the whole post, unlike a deferred taxonomy gap.
        post = raw(post_id='8888', title='제목 미상',
                   attachments=[att('a/1', '2027학년도 9월 모의평가_f 국어 문제.pdf')])
        plan = normalize(post, CRAWLED_AT, map_subjects=True)
        self.assertEqual(plan.confidence, 'low')
        self.assertFalse(plan.publishable)
        with self.assertRaises(ScopeViolation):
            assert_in_scope([plan], approved_scope([8888]))

    def test_unrelated_accepted_fingerprint_unchanged(self):
        for labels, should_change in ((('국어', '영어'), False), (LABELS, True)):
            post = self.post(labels)
            current = normalize(post, CRAWLED_AT, map_subjects=True)
            old_tokens = tuple(t for t in parser.SUBJECT_TOKENS if t not in LABELS)
            with patch.object(parser, 'SUBJECT_TOKENS', old_tokens):
                previous = normalize(post, CRAWLED_AT, map_subjects=True)
            self.assertEqual(safe_observation_fingerprint(post, current) !=
                             safe_observation_fingerprint(post, previous), should_change)

    def test_unknown_and_word_boundary_remain_unknown(self):
        self.assertEqual(split_subject('시험 가짜독일어'), (None, False))
        self.assertEqual(split_subject('시험 미등록과목'), (None, False))


if __name__ == '__main__':
    unittest.main()
