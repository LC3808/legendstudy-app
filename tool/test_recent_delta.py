"""Focused offline tests for the A2 recent-delta glue.

The bounded discovery, delta classification, and observation contracts are
already covered by the Phase 1/2 and bootstrap suites; these tests only cover the
new glue: lastmod-based recency selection and the redacted report shape. No
network is used.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion.crawler import SitemapEntry  # noqa: E402
from ingestion.delta import LocalDeltaState, StateEntry, run_delta  # noqa: E402
from ingestion.discovery import (  # noqa: E402
    DiscoveryCandidate, DiscoveryPlan, NetworkDiscovery, ReconciliationState,
)
from ingestion.recent_delta import (  # noqa: E402
    build_report, select_recent_by_lastmod,
)
from ingestion.models import RawAttachment, RawPost  # noqa: E402
from ingestion.parser import canonical_post_url  # noqa: E402


def accepted_state_with(*ids: str) -> LocalDeltaState:
    state = LocalDeltaState.empty()
    for post_id in ids:
        state.entries[post_id] = StateEntry(
            source='legendstudy', external_post_id=post_id,
            accepted_canonical_hash='h', accepted_observation_fingerprint='f',
            accepted_source_times={}, accepted_projection={},
            accepted_resource_descriptors=(),
            last_successful_observation_at=None)
    return state


class RecencySelectionTests(unittest.TestCase):
    def test_recency_uses_lastmod_not_numeric_id(self):
        # Small ids with recent lastmod must beat large ids with old lastmod.
        sitemap = [
            SitemapEntry('2', '2013-10-06T01:23:25+09:00'),
            SitemapEntry('4', '2013-10-06T01:22:43+09:00'),
            SitemapEntry('1618', '2026-09-18T00:00:00+09:00'),
            SitemapEntry('1712', '2026-09-19T22:17:41+09:00'),
            SitemapEntry('1711', '2026-09-19T20:58:04+09:00'),
        ]
        recent = select_recent_by_lastmod(sitemap, LocalDeltaState.empty(), limit=3)
        self.assertEqual([e.external_post_id for e in recent], ['1712', '1711', '1618'])
        self.assertNotIn('2', [e.external_post_id for e in recent])

    def test_accepted_posts_are_excluded_and_limit_bounds(self):
        sitemap = [SitemapEntry(str(i), f'2026-09-{i:02d}T00:00:00+09:00')
                   for i in range(10, 20)]
        state = accepted_state_with('19', '18')  # most recent two already accepted
        recent = select_recent_by_lastmod(sitemap, state, limit=3)
        ids = [e.external_post_id for e in recent]
        self.assertNotIn('19', ids)
        self.assertNotIn('18', ids)
        self.assertEqual(ids, ['17', '16', '15'])
        self.assertLessEqual(len(recent), 3)

    def test_missing_lastmod_ranks_last(self):
        sitemap = [SitemapEntry('100', None),
                   SitemapEntry('101', '2020-01-01T00:00:00+09:00')]
        recent = select_recent_by_lastmod(sitemap, LocalDeltaState.empty(), limit=2)
        self.assertEqual([e.external_post_id for e in recent], ['101', '100'])


class ReportTests(unittest.TestCase):
    def _network(self):
        return NetworkDiscovery(sitemap=(), feed=(), feed_status='UNAVAILABLE',
                                robots_observed=True,
                                budget={'ceiling': 24, 'requests': 2, 'retries': 0,
                                        'remaining': 22})

    def _post(self, post_id, title):
        att = RawAttachment('kakaocdn', 's1/s2', 'q.pdf',
                             f'https://blog.kakaocdn.net/dna/s1/s2/f.pdf', True)
        return RawPost(post_id, canonical_post_url(post_id), title,
                       '◆ "고3"을 위한 공간 /3학년 모의고사 전과목 자료',
                       '2026-09-19T00:00:00+09:00', '2026-09-19T00:00:00+09:00',
                       (att,), '본문')

    def test_report_counts_titles_and_redaction(self):
        posts = [self._post('1712', '2026년 9월 고1 모의고사')]
        result = run_delta(posts, LocalDeltaState.empty(),
                           observed_at='2026-09-26T00:00:00+00:00')
        plan = DiscoveryPlan(
            candidates=(DiscoveryCandidate('1712', 1, ('sitemap_new',),
                                           sitemap_lastmod='2026-09-19T22:17:41+09:00'),),
            cursor_before=ReconciliationState.empty(),
            cursor_after=ReconciliationState.empty(),
            reconciliation_scan=())
        report = build_report(self._network(), plan, result,
                              {'1712': '2026년 9월 고1 모의고사'})
        self.assertEqual(report['counts']['new'], 1)
        self.assertEqual(report['candidates'][0]['external_post_id'], '1712')
        self.assertEqual(report['candidates'][0]['classification'], 'NEW')
        self.assertEqual(report['candidates'][0]['title'], '2026년 9월 고1 모의고사')
        self.assertEqual(report['production_write'], 0)
        self.assertEqual(report['attachment_fetch_count'], 0)
        self.assertEqual(report['publication'], 0)
        # No signed attachment URL / query leaks into the report.
        blob = str(report).lower()
        for token in ('signature=', 'credential=', 'expires=', 'kakaocdn.net/dna'):
            self.assertNotIn(token, blob)


if __name__ == '__main__':
    unittest.main()
