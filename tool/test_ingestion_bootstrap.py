"""Offline A1 accepted-state bootstrap tests.

These cover the COLD_START_BASELINE_GAP fix: a canonical Production baseline is
reconciled with one-time source re-observations into a LocalDeltaState so that
already-published posts are no longer classified NEW purely because local state
was empty. No network, database, or Production mutation is exercised.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.bootstrap import (  # noqa: E402
    REJECT_DUPLICATE_IDENTITY, REJECT_IDENTITY_MISMATCH, REJECT_MALFORMED_SOURCE,
    REJECT_OBSERVATION_FAILED, bootstrap_accepted_state, observe_canonical_posts,
)
from ingestion.crawler import FetchError, RequestBudget  # noqa: E402
from ingestion.delta import run_delta  # noqa: E402
from ingestion.models import RawAttachment, RawPost  # noqa: E402
from ingestion.parser import canonical_post_url  # noqa: E402


def make_post(post_id='1705', title='2026년 5월 고3 모의고사', body='본문 메타데이터',
              attachments=()):
    return RawPost(
        external_post_id=str(post_id),
        url=canonical_post_url(str(post_id)),
        title=title,
        category='◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료',
        published_at='2026-07-24T13:54:57+09:00',
        updated_at='2026-07-24T13:54:57+09:00',
        attachments=tuple(attachments),
        body_excerpt=body,
    )


def make_attachment(key='s1/s2', name='2026년 5월 고3_국어 문제.pdf'):
    url = f'https://blog.kakaocdn.net/dna/{key}/stable/file.pdf'
    return RawAttachment('kakaocdn', key, name, url, True)


def observations_for(*posts):
    return {post.external_post_id: post for post in posts}


class BootstrapReconcileTests(unittest.TestCase):
    def test_1_canonical_unchanged_source_is_not_new(self):
        post = make_post(attachments=(make_attachment(),))
        result = bootstrap_accepted_state(['1705'], observations_for(post),
                                          observed_at='2026-09-26T00:00:00+00:00')
        self.assertEqual(result.accepted, ['1705'])
        # Re-running discovery against the bootstrapped state must not be NEW.
        delta = run_delta([post], result.state,
                          observed_at='2026-09-27T00:00:00+00:00')
        self.assertEqual(delta.candidates[0].classification, 'UNCHANGED')
        self.assertEqual(delta.candidates[0].change_categories, [])

    def test_2_non_canonical_post_stays_new(self):
        canonical = make_post('1705', attachments=(make_attachment(),))
        result = bootstrap_accepted_state(['1705'], observations_for(canonical))
        # An ID absent from the canonical baseline is never bootstrapped.
        self.assertNotIn('2', result.state.entries)
        new_post = make_post('2', attachments=(make_attachment('s2/s2'),))
        delta = run_delta([new_post], result.state)
        self.assertEqual(delta.candidates[0].classification, 'NEW')

    def test_3_changed_canonical_source_is_modified(self):
        post = make_post(attachments=(make_attachment(),))
        result = bootstrap_accepted_state(['1705'], observations_for(post))
        edited_title = run_delta(
            [make_post(title='2026년 5월 고3 모의고사 수정', attachments=(make_attachment(),))],
            result.state)
        self.assertEqual(edited_title.candidates[0].classification, 'MODIFIED')
        self.assertIn('title_changed', edited_title.candidates[0].change_categories)
        added_resource = run_delta(
            [make_post(attachments=(make_attachment(),
                                    make_attachment('s1/s3', '정답.pdf')))],
            result.state)
        self.assertEqual(added_resource.candidates[0].classification, 'MODIFIED')
        self.assertIn('resource_added', added_resource.candidates[0].change_categories)

    def test_4_bootstrap_is_idempotent(self):
        posts = observations_for(make_post('1705', attachments=(make_attachment(),)),
                                 make_post('1661', attachments=(make_attachment('a/b'),)))
        first = bootstrap_accepted_state(['1705', '1661'], posts,
                                         observed_at='2026-09-26T00:00:00+00:00')
        second = bootstrap_accepted_state(['1661', '1705'], posts,
                                          observed_at='2026-09-27T12:00:00+00:00')
        # Different observation clocks, identical semantic accepted state.
        self.assertEqual(first.state.fingerprint(), second.state.fingerprint())
        self.assertEqual(first.report()['state_fingerprint'],
                         second.report()['state_fingerprint'])
        self.assertEqual(first.report()['accepted'], second.report()['accepted'])

    def test_5_duplicate_canonical_identity_fails_closed(self):
        post = make_post(attachments=(make_attachment(),))
        result = bootstrap_accepted_state(['1705', '1705'], observations_for(post))
        self.assertNotIn('1705', result.state.entries)
        self.assertEqual(result.accepted, [])
        reasons = {row['reason'] for row in result.rejected}
        self.assertIn(REJECT_DUPLICATE_IDENTITY, reasons)

    def test_6_observation_failure_is_not_accepted(self):
        # None means the bounded fetch failed; the post must not be accepted.
        result = bootstrap_accepted_state(['1705'], {'1705': None})
        self.assertNotIn('1705', result.state.entries)
        self.assertEqual(result.accepted, [])
        self.assertEqual(result.rejected[0]['reason'], REJECT_OBSERVATION_FAILED)

    def test_7_malformed_and_mismatched_source_fail_closed(self):
        malformed = make_post(title='', attachments=(make_attachment(),))
        mismatch = make_post('9999', attachments=(make_attachment(),))
        result = bootstrap_accepted_state(
            ['1705', '1706'], {'1705': malformed, '1706': mismatch})
        self.assertEqual(result.accepted, [])
        reasons = {row['external_post_id']: row['reason'] for row in result.rejected}
        self.assertEqual(reasons['1705'], REJECT_MALFORMED_SOURCE)
        self.assertEqual(reasons['1706'], REJECT_IDENTITY_MISMATCH)

    def test_8_resource_stable_identity_is_preserved(self):
        post = make_post(attachments=(make_attachment('s1/s2', '국어.pdf'),
                                      make_attachment('s1/s3', '정답.pdf')))
        result = bootstrap_accepted_state(['1705'], observations_for(post))
        descriptors = result.state.entries['1705'].accepted_resource_descriptors
        keys = {(d['provider'], d['source_resource_key']) for d in descriptors}
        self.assertEqual(keys, {('kakaocdn', 's1/s2'), ('kakaocdn', 's1/s3')})
        # Same resources re-observed remain UNCHANGED (identity preserved).
        delta = run_delta([post], result.state)
        self.assertEqual(delta.candidates[0].classification, 'UNCHANGED')

    def test_9_unrelated_sitemap_posts_are_not_auto_accepted(self):
        canonical = make_post('1705', attachments=(make_attachment(),))
        old_sitemap = make_post('4', attachments=(make_attachment('s4/s4'),))
        # Even if an old post is observed, only baseline IDs are bootstrapped.
        result = bootstrap_accepted_state(
            ['1705'], observations_for(canonical, old_sitemap))
        self.assertEqual(sorted(result.state.entries), ['1705'])
        delta = run_delta([old_sitemap], result.state)
        self.assertEqual(delta.candidates[0].classification, 'NEW')

    def test_10_bootstrap_reports_zero_production_mutation(self):
        result = bootstrap_accepted_state(
            ['1705'], observations_for(make_post(attachments=(make_attachment(),))))
        report = result.report()
        self.assertEqual(report['production_mutation'], 0)
        self.assertEqual(report['database_migration'], 0)
        self.assertEqual(report['scheduler_created'], 0)
        self.assertEqual(report['attachment_fetch_count'], 0)
        self.assertEqual(report['non_canonical_accepted'], 0)
        self.assertTrue(report['source_reobservation_required'])


class ObserveCanonicalPostsTests(unittest.TestCase):
    def test_bounded_budget_and_fail_closed_without_attachment_fetch(self):
        pages = {
            canonical_post_url('1705'): (
                '<meta property="og:title" content="2026년 5월 고3 모의고사">'
                '<meta property="article:published_time" content="2026-07-24T13:54:57+09:00">'
                '<a href="/category/%EA%B3%A03">c</a>'
                '<div class="contents_style">본문'
                '<a href="https://blog.kakaocdn.net/dna/s1/s2/file.pdf?signature=x">'
                '2026년 5월 고3_국어 문제.pdf</a></div>'),
        }
        requested: list[str] = []

        class StubFetcher:
            def __init__(self):
                self.request_budget = RequestBudget(6)

            def get(self, url, accept=None, request_label='request'):
                requested.append(url)
                self.request_budget.reserve(request_label)
                if url in pages:
                    return pages[url]
                raise FetchError(url, 'not found', transient=False)

        observations, budget, used = observe_canonical_posts(
            ['1705', '1706'], fetcher=StubFetcher())
        # Only landing pages are requested; no attachment URL is fetched.
        self.assertTrue(all('kakaocdn' not in url for url in requested))
        self.assertEqual(budget, 2 * (2 + 1))
        self.assertEqual(used, 2)
        self.assertIsNotNone(observations['1705'])
        self.assertEqual(observations['1705'].external_post_id, '1705')
        self.assertIsNone(observations['1706'])  # fetch failure -> None (fail closed)
        # A failed observation is not accepted.
        result = bootstrap_accepted_state(['1705', '1706'], observations)
        self.assertEqual(result.accepted, ['1705'])


if __name__ == '__main__':
    unittest.main()
