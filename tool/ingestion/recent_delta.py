"""A2 recent-delta operator run.

Bounded discovery + one-time re-observation + delta classification against the
A1-bootstrapped accepted state. This module is *glue only*: it orchestrates the
existing discovery/delta/crawler/parser/normalizer contracts and adds no new
crawler, delta engine, or state model.

Source READ ONLY: it fetches robots.txt, sitemap.xml, and at most the existing
landing-page limit. It never fetches attachments, writes a database, or
publishes. The output is an inspectable, redacted candidate report for human
review (A3), not a publication.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from .crawler import SitemapEntry
from .delta import DeltaRun, LocalDeltaState, load_delta_state
from .discovery import (
    NORMAL_LANDING_PAGE_LIMIT, BoundedDiscoveryRunner, DiscoveryPlan,
    NetworkDiscovery, observe_selected, select_candidates,
)
from .models import RawPost

RECENT_DELTA_SCHEMA_VERSION = 'legendstudy-recent-delta/1'


def select_recent_by_lastmod(sitemap: list[SitemapEntry],
                             accepted_state: LocalDeltaState,
                             limit: int = NORMAL_LANDING_PAGE_LIMIT) -> list[SitemapEntry]:
    """Return the most recent not-yet-accepted sitemap entries by ``lastmod``.

    LegendStudy's sitemap carries a real ``lastmod`` per post, so recency comes
    from that source metadata rather than the numeric ``external_post_id``. The
    existing ``select_candidates`` ranks not-in-state posts by ascending numeric
    id, which — under a sparse accepted baseline — would surface the *oldest*
    posts (a historical flood) instead of the recent ones. This bounded slice
    supplies the ``lastmod`` recency that Track A / A2 requires, and the slice is
    then handed to the unchanged ``select_candidates`` / delta contracts.
    """
    unaccepted = [entry for entry in sitemap
                  if entry.external_post_id not in accepted_state.entries]
    # lastmod ISO-8601 sorts lexically; missing lastmod ranks last. Newest first,
    # then highest numeric id as a stable deterministic tiebreak.
    unaccepted.sort(
        key=lambda e: (e.lastmod or '', _numeric_desc(e.external_post_id)),
        reverse=True)
    return unaccepted[:max(0, limit)]


def _numeric_desc(external_post_id: str) -> int:
    value = str(external_post_id)
    return int(value) if value.isdigit() else -1


def plan_recent(state_path: Path, *, feed_url: str | None = None,
                limit: int = NORMAL_LANDING_PAGE_LIMIT,
                runner: BoundedDiscoveryRunner | None = None,
                ) -> tuple[NetworkDiscovery, DiscoveryPlan, BoundedDiscoveryRunner]:
    """Discover (robots + sitemap [+ optional feed]) and select recent candidates.

    No landing page is fetched here, so the selection can be inspected before any
    per-post observation.
    """
    state = load_delta_state(Path(state_path))
    runner = runner or BoundedDiscoveryRunner()
    network = runner.discover(feed_url=feed_url)
    # Recency comes from sitemap lastmod, not the numeric id (see §3 / A2). Feed
    # the unchanged select_candidates only the recent unaccepted slice so it does
    # not surface the oldest posts as a historical flood.
    recent = select_recent_by_lastmod(list(network.sitemap), state, limit=limit)
    plan = select_candidates(recent, list(network.feed),
                             accepted_state=state, limit=limit)
    return network, plan, runner


def observe_recent(plan: DiscoveryPlan, runner: BoundedDiscoveryRunner,
                   state_path: Path,
                   observed_at: str = '1970-01-01T00:00:00+00:00') -> DeltaRun:
    """Fetch the selected landing pages and classify them against accepted state."""
    state = load_delta_state(Path(state_path))
    posts, failures = runner.fetch_landing_pages(plan)
    return observe_selected(plan, posts, accepted_state=state,
                            observed_at=observed_at, failed_ids=failures)


def _title_lookup(posts: list[RawPost]) -> dict[str, str]:
    return {post.external_post_id: post.title for post in posts}


def build_report(network: NetworkDiscovery, plan: DiscoveryPlan,
                 result: DeltaRun | None,
                 titles: dict[str, str] | None = None) -> dict:
    """Redacted, inspectable A2 report. No signed URLs/queries are included."""
    titles = titles or {}
    counts = {k: 0 for k in ('new', 'modified', 'unchanged', 'malformed',
                             'ambiguous', 'source_missing', 'failed')}
    candidates: list[dict] = []
    if result is not None:
        for candidate in result.candidates:
            name = candidate.classification.lower()
            if name in counts:
                counts[name] += 1
            if candidate.observation_status == 'FETCH_FAILED':
                counts['failed'] += 1
            row = {
                'external_post_id': candidate.external_post_id,
                'classification': candidate.classification,
                'observation_status': candidate.observation_status,
                'source_times': candidate.source_times,
                'content_type': candidate.safe_metadata.get('content_type'),
                'change_categories': candidate.change_categories,
                'review_flags': candidate.review_flags,
            }
            title = titles.get(candidate.external_post_id)
            if title and candidate.classification in {'NEW', 'MODIFIED'}:
                row['title'] = title
            candidates.append(row)
    return {
        'schema_version': RECENT_DELTA_SCHEMA_VERSION,
        'feed_status': network.feed_status,
        'sitemap_items_observed': len(network.sitemap),
        'candidate_selection_order': [c.external_post_id for c in plan.candidates],
        'candidate_sources': {c.external_post_id: list(c.sources)
                              for c in plan.candidates},
        'landing_page_limit': plan.landing_page_limit,
        'source_budget': network.budget,
        'counts': counts,
        'candidates': candidates,
        'production_read': 'source-only (robots/sitemap/landing)',
        'production_write': 0,
        'attachment_fetch_count': 0,
        'publication': 0,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog='ingestion.recent_delta',
        description='A2 bounded recent discovery + delta against accepted state '
                    '(source read only; no publication).')
    parser.add_argument('--state', required=True, type=Path,
                        help='A1-bootstrapped accepted LocalDeltaState JSON')
    parser.add_argument('--report-out', required=True, type=Path)
    parser.add_argument('--limit', type=int, default=NORMAL_LANDING_PAGE_LIMIT)
    parser.add_argument('--feed-url', default=None,
                        help='verified RSS/feed endpoint only; omitted -> UNAVAILABLE')
    parser.add_argument('--plan-only', action='store_true',
                        help='discover + select but do not fetch landing pages')
    parser.add_argument('--observed-at', default='1970-01-01T00:00:00+00:00')
    args = parser.parse_args(argv)

    network, plan, runner = plan_recent(args.state, feed_url=args.feed_url,
                                        limit=args.limit)
    result = None
    titles: dict[str, str] = {}
    if not args.plan_only:
        posts, failures = runner.fetch_landing_pages(plan)
        titles = _title_lookup(posts)
        result = observe_selected(plan, posts,
                                  accepted_state=load_delta_state(args.state),
                                  observed_at=args.observed_at, failed_ids=failures)
    report = build_report(network, plan, result, titles)
    args.report_out.parent.mkdir(parents=True, exist_ok=True)
    args.report_out.write_text(
        json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + '\n',
        encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == '__main__':  # pragma: no cover
    raise SystemExit(main())
