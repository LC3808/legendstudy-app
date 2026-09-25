"""Phase 1-A fixture-contract tests.

These tests cover the offline contract boundary. They do not connect to
Production or exercise discovery/network behavior.
"""
from __future__ import annotations

import hashlib
import json
import sys
import unittest
import tempfile
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.delta import (  # noqa: E402
    DeltaStateError, LocalDeltaState, fetch_failed_candidate, run_delta,
    write_delta_artifacts,
)
from ingestion.models import RawAttachment, RawPost  # noqa: E402
from ingestion.parser import canonical_post_url  # noqa: E402


FIXTURE_PATH = (Path(__file__).resolve().parent / 'ingestion' / 'samples'
                / 'phase1-delta' / 'manifest.json')
EXPECTED_IDS = {
    'new_post', 'unchanged_post', 'edited_title', 'edited_body_metadata',
    'edited_subject_known_mapping', 'edited_subject_ambiguous_mapping',
    'added_answer', 'added_audio', 'resource_absent_complete',
    'signature_rotation_only', 'malformed_post', 'partial_fetch', 'source_missing',
    'duplicate_observation', 'unknown_provider_query_change', 'fetch_timeout',
}
FORBIDDEN_TOKENS = (
    'credential=', 'expires=', 'signature=', 'cookie:', 'authorization:',
    'service_role', 'db_password', '<html',
)


def load_manifest() -> dict:
    return json.loads(FIXTURE_PATH.read_text(encoding='utf-8'))


class Phase1FixtureContractTests(unittest.TestCase):
    def test_required_fixture_inventory_is_complete(self):
        manifest = load_manifest()
        fixtures = manifest['fixtures']
        self.assertEqual({row['id'] for row in fixtures}, EXPECTED_IDS)
        self.assertEqual(len(fixtures), 16)
        for row in fixtures:
            self.assertEqual(row.get('source', manifest['source']), manifest['source'])
            self.assertTrue(row['external_post_id'].isdigit())
            self.assertTrue(row['expected_classification'])
            self.assertTrue(row['state_advance'])
            self.assertTrue(row['forbidden_actions'])

    def test_manifest_declarations_execute_against_delta_engine(self):
        """Fixture declarations are executable expectations, not documentation only."""
        manifest = {row['id']: row for row in load_manifest()['fixtures']}
        base = make_post(attachments=(make_attachment(),))
        accepted = run_delta([base]).state_after
        scenarios = {
            'new_post': run_delta([make_post('1901')]),
            'unchanged_post': run_delta([base], accepted),
            'edited_title': run_delta([make_post(title='2026년 5월 고3 모의고사 수정')], accepted),
            'edited_body_metadata': run_delta([make_post(body='본문 수정')], accepted),
            'edited_subject_known_mapping': run_delta([make_post(attachments=(
                make_attachment(name='2026년 5월 고3_영어 문제.pdf'),
            ))], accepted),
            'edited_subject_ambiguous_mapping': run_delta(
                [make_post(attachments=(
                    make_attachment(name='2026년 5월 고3_영어 문제.pdf'),
                ))], accepted, subject_ambiguous_ids=['1705']),
            'added_answer': run_delta([make_post(attachments=(
                make_attachment(), make_attachment('s1/s3', '2026년 5월 고3_국어 정답.pdf'),
            ))], accepted),
            'added_audio': run_delta([make_post(attachments=(
                make_attachment(), make_attachment('audio-1', '영어 듣기파일.mp3', 'box'),
            ))], accepted),
            'resource_absent_complete': run_delta([make_post(attachments=())], accepted),
            'signature_rotation_only': run_delta([make_post(attachments=(
                make_attachment(signed=False),
            ))], accepted),
            'malformed_post': run_delta([make_post(title='')], accepted),
            'partial_fetch': run_delta([make_post(body='partial')], accepted,
                                       partial_ids=['1705']),
            'source_missing': run_delta([], accepted, source_missing_ids=['1705']),
            'duplicate_observation': run_delta(
                [base, make_post(title='conflicting')], accepted),
            'unknown_provider_query_change': run_delta(
                [base], accepted, ambiguous_ids=['1705']),
            'fetch_timeout': run_delta([], accepted, fetch_failed_ids=['1705']),
        }
        for fixture_id, result in scenarios.items():
            row = manifest[fixture_id]
            candidate = result.candidates[0]
            self.assertEqual(candidate.classification, row['expected_classification'], fixture_id)
            for category in row.get('expected_change_categories', []):
                self.assertIn(category, candidate.change_categories, fixture_id)
            if fixture_id == 'partial_fetch':
                self.assertEqual(candidate.resource_change_summary['unconfirmed_absent'], [])
                self.assertNotIn('subject_mapping_changed', candidate.change_categories)

    def test_manifest_is_deterministically_serialized_and_redacted(self):
        raw = FIXTURE_PATH.read_bytes()
        parsed = json.loads(raw)
        canonical = json.dumps(parsed, ensure_ascii=False, sort_keys=True,
                               separators=(',', ':')).encode('utf-8')
        self.assertEqual(hashlib.sha256(canonical).hexdigest(),
                         'e94f3da3790247e828d60fc62e38dc2f4f527e1a84973f156b3c3cbc80c2eaa1')
        lowered = raw.decode('utf-8').lower()
        for token in FORBIDDEN_TOKENS:
            self.assertNotIn(token, lowered)

    def test_phase1_classifier_is_implemented(self):
        from ingestion.pipeline import classify_delta  # type: ignore
        self.assertTrue(callable(classify_delta))


def make_post(post_id='1705', title='2026년 5월 고3 모의고사', body='본문 메타데이터',
              attachments=()):
    return RawPost(
        external_post_id=post_id,
        url=canonical_post_url(post_id),
        title=title,
        category='◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료',
        published_at='2026-07-24T13:54:57+09:00',
        updated_at='2026-07-24T13:54:57+09:00',
        attachments=tuple(attachments),
        body_excerpt=body,
    )


def make_attachment(key='s1/s2', name='2026년 5월 고3_국어 문제.pdf',
                    provider='kakaocdn', signed=True):
    if provider == 'kakaocdn':
        url = f'https://blog.kakaocdn.net/dna/{key}/stable/file.pdf'
    else:
        url = f'https://t1.daumcdn.net/cfile/tistory/{key}'
    return RawAttachment(provider, key, name, url, signed)


class DeltaCoreTests(unittest.TestCase):
    def test_classification_and_state_advancement_are_deterministic(self):
        post = make_post(attachments=(make_attachment(),))
        first = run_delta([post], observed_at='2026-09-25T00:00:00+00:00')
        self.assertEqual(first.candidates[0].classification, 'NEW')
        self.assertEqual(len(first.state_before.entries), 0)
        self.assertEqual(len(first.state_after.entries), 1)

        unchanged = run_delta([post], first.state_after,
                              observed_at='2026-09-26T00:00:00+00:00')
        self.assertEqual(unchanged.candidates[0].classification, 'UNCHANGED')
        self.assertEqual(unchanged.candidates[0].change_categories, [])
        self.assertEqual(unchanged.state_after.fingerprint(), first.state_after.fingerprint())

        edited = run_delta([make_post(title='2026년 5월 고3 모의고사 수정',
                                      attachments=(make_attachment(),))], first.state_after,
                           observed_at='2026-09-26T00:00:00+00:00')
        self.assertEqual(edited.candidates[0].classification, 'MODIFIED')
        self.assertEqual(edited.candidates[0].change_categories, ['title_changed'])

    def test_body_resource_and_signature_contracts(self):
        base = make_post(attachments=(make_attachment(),))
        accepted = run_delta([base]).state_after
        body_edit = run_delta([make_post(body='본문 메타데이터 수정',
                                         attachments=(make_attachment(),))], accepted)
        self.assertEqual(body_edit.candidates[0].classification, 'MODIFIED')
        self.assertIn('body_or_metadata_changed', body_edit.candidates[0].change_categories)

        added = run_delta([make_post(attachments=(
            make_attachment(), make_attachment('s1/s3', '2026년 5월 고3_국어 정답.pdf'))
        )], accepted)
        self.assertIn('resource_added', added.candidates[0].change_categories)

        absent = run_delta([make_post(attachments=())], accepted)
        self.assertEqual(absent.candidates[0].classification, 'MODIFIED')
        self.assertIn('resource_unconfirmed_absent', absent.candidates[0].change_categories)

        rotated = run_delta([make_post(attachments=(make_attachment(signed=False),))], accepted)
        self.assertEqual(rotated.candidates[0].classification, 'UNCHANGED')
        self.assertNotIn('resource_changed', rotated.candidates[0].change_categories)

    def test_subject_fixtures_and_unknown_provider_are_explicit(self):
        base = make_post(attachments=(make_attachment(),))
        accepted = run_delta([base]).state_after
        known = run_delta([make_post(attachments=(
            make_attachment(name='2026년 5월 고3_영어 문제.pdf'),
        ))], accepted)
        self.assertEqual(known.candidates[0].classification, 'MODIFIED')
        self.assertIn('subject_mapping_changed', known.candidates[0].change_categories)

        ambiguous = run_delta([make_post(attachments=(
            make_attachment(name='2026년 5월 고3_영어 문제.pdf'),
        ))], accepted, subject_ambiguous_ids=['1705'])
        self.assertEqual(ambiguous.candidates[0].classification, 'AMBIGUOUS')
        self.assertIn('subject_mapping_conflict',
                      ambiguous.candidates[0].review_flags)

    def test_failure_and_ambiguity_do_not_advance_state(self):
        base = make_post(attachments=(make_attachment(),))
        accepted = run_delta([base]).state_after
        malformed = run_delta([make_post(title='', attachments=(make_attachment(),))], accepted)
        self.assertEqual(malformed.candidates[0].classification, 'MALFORMED')
        self.assertEqual(malformed.state_after.fingerprint(), accepted.fingerprint())

        partial = run_delta([base], accepted, partial_ids=['1705'])
        self.assertEqual(partial.candidates[0].classification, 'MALFORMED')
        self.assertEqual(partial.state_after.fingerprint(), accepted.fingerprint())

        ambiguous = run_delta([base], accepted, ambiguous_ids=['1705'])
        self.assertEqual(ambiguous.candidates[0].classification, 'AMBIGUOUS')
        self.assertEqual(ambiguous.state_after.fingerprint(), accepted.fingerprint())

        missing = run_delta([], accepted, source_missing_ids=['1705'])
        self.assertEqual(missing.candidates[0].classification, 'SOURCE_MISSING')
        self.assertIn('1705', missing.state_after.entries)

        failed = run_delta([], accepted, fetch_failed_ids=['1705'])
        self.assertEqual(failed.candidates[0].classification, 'FETCH_FAILED')
        self.assertIn('1705', failed.state_after.entries)

        duplicate = run_delta([base, make_post(title='conflicting',
                                                attachments=(make_attachment(),))], accepted)
        self.assertEqual(duplicate.candidates[0].classification, 'AMBIGUOUS')

    def test_unknown_state_version_is_rejected(self):
        with self.assertRaises(DeltaStateError):
            LocalDeltaState.from_dict({'state_version': 'future/99',
                                       'source': 'legendstudy', 'entries': {}})

    def test_artifacts_are_redacted_sorted_and_state_follows_finalize(self):
        post = make_post(attachments=(make_attachment(),))
        result = run_delta([post], observed_at='2026-09-25T00:00:00+00:00')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'artifacts'
            state_path = root / 'state.json'
            summary, candidates, state = write_delta_artifacts(result, output, state_path)
            self.assertTrue(summary.exists())
            self.assertTrue(candidates.exists())
            self.assertEqual(state, state_path)
            self.assertEqual(json.loads(state_path.read_text())['state_version'],
                             'legendstudy-delta-state/1')
            contents = (summary.read_text() + candidates.read_text()).lower()
            for token in ('credential=', 'expires=', 'signature=', '<html',
                          'authorization:', 'service_role', 'db_password'):
                self.assertNotIn(token, contents)

    def test_candidate_order_is_independent_of_input_order(self):
        posts = [make_post('1706', attachments=(make_attachment('s1/s3'),)),
                 make_post('1705', attachments=(make_attachment('s1/s2'),))]
        posts.append(make_post('999', attachments=(make_attachment('s1/s1'),)))
        first = run_delta(posts)
        second = run_delta(list(reversed(posts)))
        self.assertEqual([c.external_post_id for c in first.candidates], ['999', '1705', '1706'])
        self.assertEqual([c.as_dict() for c in first.candidates],
                         [c.as_dict() for c in second.candidates])

    def test_artifact_failure_does_not_write_state(self):
        post = make_post(attachments=(make_attachment(),))
        result = run_delta([post])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'artifacts'
            state_path = root / 'state.json'
            with mock.patch('ingestion.delta.os.replace', side_effect=OSError('blocked')):
                with self.assertRaises(OSError):
                    write_delta_artifacts(result, output, state_path)
            self.assertFalse(state_path.exists())


if __name__ == '__main__':
    unittest.main()
