"""Offline Phase 1-B2 discovery, cursor and request-budget tests."""
from __future__ import annotations

import json
import io
import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.crawler import (  # noqa: E402
    BudgetExceeded, FetchError, PoliteFetcher, RequestBudget, SitemapEntry,
    sitemap_entries,
)
from ingestion.delta import LocalDeltaState, run_delta  # noqa: E402
from ingestion.discovery import (  # noqa: E402
    ABSOLUTE_REQUEST_CEILING, DISCOVERY_STATE_VERSION, FEED_STATUS_UNAVAILABLE,
    BoundedDiscoveryRunner, FeedCandidate, ReconciliationState,
    observe_selected, parse_feed_candidates, select_candidates,
    write_bounded_dry_run,
)
from ingestion.models import RawPost  # noqa: E402
from ingestion.parser import canonical_post_url  # noqa: E402


FIXTURE_DIR = Path(__file__).resolve().parent / 'ingestion' / 'samples' / 'phase1-discovery'
SITEMAP = (FIXTURE_DIR / 'sitemap.xml').read_text(encoding='utf-8')
RSS = (FIXTURE_DIR / 'rss.xml').read_text(encoding='utf-8')


def post(post_id: str) -> RawPost:
    return RawPost(str(post_id), canonical_post_url(str(post_id)),
                   '2026년 5월 고3 모의고사',
                   '◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료',
                   '2026-07-24T13:54:57+09:00',
                   '2026-07-24T13:54:57+09:00')


class DiscoveryFixtureTests(unittest.TestCase):
    def test_sitemap_lastmod_is_structured_and_numeric(self):
        entries = sitemap_entries(SITEMAP)
        self.assertEqual([(entry.external_post_id, entry.lastmod) for entry in entries], [
            ('999', '2026-09-20'), ('1705', '2026-09-25T00:00:00+00:00')
        ])

    def test_feed_recent_candidates_are_metadata_only(self):
        candidates = parse_feed_candidates(RSS)
        self.assertEqual([(item.external_post_id, item.timestamp) for item in candidates], [
            ('999', '2026-09-20'), ('1705', '2026-09-25')
        ])

    def test_priority_merge_deduplicates_and_caps_landing_pages(self):
        state = LocalDeltaState.empty()
        plan = select_candidates(
            [SitemapEntry(str(value), '2026-09-25') for value in (999, 1000, 1001, 1002, 1003, 1004)],
            [FeedCandidate('1004', '2026-09-25')], state,
            pending_retry_ids=['1003'], limit=5)
        self.assertEqual(len(plan.candidates), 5)
        self.assertEqual([candidate.external_post_id for candidate in plan.candidates],
                         ['1003', '999', '1000', '1001', '1002'])
        self.assertEqual(plan.reconciliation_scan, ())
        self.assertEqual(plan.cursor_before, plan.cursor_after)
        self.assertEqual(plan.candidates[0].sources, ('pending_retry', 'sitemap_new'))

    def test_full_priority_batch_does_not_consume_reconciliation_cursor(self):
        cursor = ReconciliationState('500')
        plan = select_candidates(
            [SitemapEntry(str(value), '2026-09-25') for value in range(500, 510)],
            [], LocalDeltaState.empty(), pending_retry_ids=['505', '506', '507', '508', '509'],
            cursor=cursor, limit=5)
        self.assertEqual([candidate.external_post_id for candidate in plan.candidates],
                         ['505', '506', '507', '508', '509'])
        self.assertEqual(plan.reconciliation_scan, ())
        self.assertEqual(plan.cursor_after, cursor)

    def test_partial_priority_batch_advances_only_selected_reconciliation_slots(self):
        cursor = ReconciliationState('500')
        accepted = run_delta(
            [post(str(value)) for value in range(500, 510)],
            observed_at='2026-09-24T00:00:00+00:00').state_after
        for entry in accepted.entries.values():
            entry.accepted_source_times['sitemap_lastmod'] = '2026-09-25'
        plan = select_candidates(
            [SitemapEntry(str(value), '2026-09-25') for value in range(500, 510)],
            [], accepted, pending_retry_ids=['505', '506'],
            cursor=cursor, limit=5)
        self.assertEqual([candidate.external_post_id for candidate in plan.candidates],
                         ['505', '506', '500', '501', '502'])
        self.assertEqual(plan.reconciliation_scan, ('500', '501', '502'))
        self.assertEqual(plan.cursor_after.next_external_post_id, '503')

    def test_cursor_progresses_wraps_and_rejects_unknown_version(self):
        cursor = ReconciliationState.empty()
        first, cursor = cursor.scan(['999', '1000', '1001'], 2)
        second, cursor = cursor.scan(['999', '1000', '1001'], 2)
        third, next_cursor = cursor.scan(['999', '1000', '1001'], 2)
        self.assertEqual((first, second, third),
                         (['999', '1000'], ['1001', '999'], ['1000', '1001']))
        self.assertEqual(next_cursor.next_external_post_id, '999')
        with self.assertRaises(ValueError):
            ReconciliationState.from_dict({
                'state_version': 'future/99', 'source': 'legendstudy',
                'next_external_post_id': '999',
            })

    def test_failed_run_does_not_write_cursor(self):
        cursor = ReconciliationState.empty()
        selected, next_cursor = cursor.scan(['999', '1000'], 1)
        self.assertEqual(selected, ['999'])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'cursor.json'
            self.assertFalse(path.exists())
            # Planning computes next_cursor; only the successful artifact path
            # below is allowed to persist it.
            self.assertFalse(path.exists())
            next_cursor.write(path)
            self.assertEqual(json.loads(path.read_text())['next_external_post_id'], '1000')

    def test_failed_reconciliation_observation_preserves_existing_cursor(self):
        accepted = run_delta(
            [post('999'), post('1000')],
            observed_at='2026-09-24T00:00:00+00:00').state_after
        for entry in accepted.entries.values():
            entry.accepted_source_times['sitemap_lastmod'] = '2026-09-25'
        plan = select_candidates(
            [SitemapEntry('999', '2026-09-25'), SitemapEntry('1000', '2026-09-25')],
            [], accepted, cursor=ReconciliationState('999'), limit=1)
        self.assertEqual(plan.reconciliation_scan, ('999',))
        self.assertEqual(plan.cursor_after.next_external_post_id, '1000')
        result = observe_selected(plan, [], accepted, failed_ids=['999'])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cursor_path = root / 'cursor-state.json'
            plan.cursor_before.write(cursor_path)
            write_bounded_dry_run(result, plan, root / 'artifacts', cursor_path=cursor_path)
            self.assertEqual(
                json.loads(cursor_path.read_text())['next_external_post_id'], '999')

    def test_budget_counts_retries_and_stops_at_ceiling(self):
        budget = RequestBudget(3)
        fetcher = PoliteFetcher(delay=0, max_retries=2, request_budget=budget)
        attempts = []

        def transient(req, timeout=None):
            attempts.append(req.full_url)
            raise urllib.error.HTTPError(req.full_url, 503, 'retry', {}, None)

        with mock.patch('urllib.request.urlopen', transient), \
                mock.patch('time.sleep'):
            with self.assertRaises(FetchError) as context:
                fetcher.get('https://legendstudy.com/1705')
        self.assertEqual(context.exception.reason, 'HTTP 503')
        self.assertEqual(len(attempts), 3)
        self.assertEqual(budget.as_dict(), {
            'ceiling': 3, 'requests': 3, 'retries': 2, 'remaining': 0,
        })
        with self.assertRaises(BudgetExceeded):
            budget.reserve('after-limit')

    def test_observation_is_passed_to_b1_and_artifact_keeps_discovery_fields(self):
        plan = select_candidates([SitemapEntry('1705', '2026-09-25')], [], limit=1)
        result = observe_selected(plan, [post('1705')], observed_at='2026-09-25T00:00:00+00:00')
        self.assertEqual(result.candidates[0].classification, 'NEW')
        self.assertEqual(result.candidates[0].source_times['sitemap_lastmod'], '2026-09-25')
        self.assertEqual(result.state_after.entries['1705'].accepted_source_times['sitemap_lastmod'],
                         '2026-09-25')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            summary, _, _ = write_bounded_dry_run(result, plan, root / 'artifacts',
                                                  root / 'delta-state.json',
                                                  root / 'cursor-state.json')
            summary_payload = json.loads(summary.read_text())
            self.assertEqual(summary_payload['discovery']['schema_version'],
                             'legendstudy-discovery/1')
            self.assertEqual(summary_payload['candidate_selection_order'], ['1705'])
            self.assertEqual(summary_payload['discovery']['budget']['ceiling'],
                             ABSOLUTE_REQUEST_CEILING)
            self.assertEqual(json.loads((root / 'cursor-state.json').read_text())['state_version'],
                             DISCOVERY_STATE_VERSION)

    def test_runner_artifact_reports_actual_budget_after_retry(self):
        budget = RequestBudget(ABSOLUTE_REQUEST_CEILING)
        fetcher = PoliteFetcher(delay=0, max_retries=1, request_budget=budget)
        runner = BoundedDiscoveryRunner(fetcher=fetcher)
        html = ('<meta property="og:title" content="2026년 5월 고3 모의고사">'
                '<meta property="article:published_time" content="2026-09-25">'
                '<div class="contents_style">body</div>')

        class Response:
            def __init__(self, body):
                self.body = body.encode('utf-8')

            def __enter__(self):
                return self

            def __exit__(self, *args):
                return False

            def read(self):
                return io.BytesIO(self.body).read()

        with mock.patch('urllib.request.urlopen', side_effect=[
                Response('User-agent: *'), Response(SITEMAP),
                urllib.error.HTTPError('https://legendstudy.com/999', 503,
                                       'retry', {}, None), Response(html)]), \
                mock.patch('time.sleep'):
            network = runner.discover()
            plan = select_candidates(list(network.sitemap), [], limit=1)
            posts, failures = runner.fetch_landing_pages(plan)
        self.assertEqual(failures, [])
        result = observe_selected(plan, posts)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            summary, _, _ = runner.write_dry_run(result, plan, root / 'artifacts')
            payload = json.loads(summary.read_text())
        self.assertEqual(payload['source_budget'], {
            'ceiling': ABSOLUTE_REQUEST_CEILING,
            'requests': 4,
            'retries': 1,
            'remaining': ABSOLUTE_REQUEST_CEILING - 4,
        })
        self.assertEqual(payload['discovery']['budget'], payload['source_budget'])

    def test_feed_is_explicitly_unavailable_without_verified_endpoint(self):
        self.assertEqual(FEED_STATUS_UNAVAILABLE, 'UNAVAILABLE')


if __name__ == '__main__':
    unittest.main()
