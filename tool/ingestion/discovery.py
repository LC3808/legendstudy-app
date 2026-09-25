"""Phase 1-B2 discovery, reconciliation and bounded observation helpers.

Discovery only chooses landing pages.  It does not infer deltas, fetch
attachments, write Production, or create a scheduler.  The selected posts are
passed to :mod:`ingestion.delta` for the B1 classification contract.
"""
from __future__ import annotations

import os
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from xml.etree import ElementTree

from . import SITE_ORIGIN, SOURCE
from .crawler import (
    ACCEPT_HTML, ACCEPT_XML, DEFAULT_DELAY_SECONDS, DEFAULT_MAX_RETRIES,
    DEFAULT_TIMEOUT_SECONDS, FetchError, PoliteFetcher, RequestBudget,
    SitemapEntry, sitemap_entries,
)
from .delta import DeltaRun, LocalDeltaState, run_delta, write_delta_artifacts
from .parser import normalize_post_url, parse_html
from .models import RawPost

DISCOVERY_STATE_VERSION = 'legendstudy-reconciliation-state/1'
DISCOVERY_SCHEMA_VERSION = 'legendstudy-discovery/1'
NORMAL_LANDING_PAGE_LIMIT = 5
ABSOLUTE_REQUEST_CEILING = 24
FEED_STATUS_UNAVAILABLE = 'UNAVAILABLE'
FEED_STATUS_AVAILABLE = 'AVAILABLE'


def _numeric_key(value: str) -> tuple[int, int | str]:
    value = str(value)
    return (0, int(value)) if value.isdigit() else (1, value)


@dataclass(frozen=True)
class FeedCandidate:
    external_post_id: str
    timestamp: str | None = None


def _xml_name(tag: str) -> str:
    return tag.rsplit('}', 1)[-1].lower()


def _child_text(node: ElementTree.Element, names: set[str]) -> str | None:
    for child in node:
        if _xml_name(child.tag) in names:
            value = (child.text or '').strip()
            if value:
                return value
    return None


def _feed_link(node: ElementTree.Element) -> str | None:
    for child in node:
        if _xml_name(child.tag) != 'link':
            continue
        href = child.attrib.get('href')
        if href:
            return href.strip()
        if child.text and child.text.strip():
            return child.text.strip()
    guid = _child_text(node, {'guid', 'id'})
    return guid.strip() if guid else None


def parse_feed_candidates(xml: str) -> list[FeedCandidate]:
    """Parse RSS/Atom numeric post hints without retaining feed bodies."""
    try:
        root = ElementTree.fromstring(xml)
    except ElementTree.ParseError:
        return []
    candidates: dict[str, FeedCandidate] = {}
    for node in root.iter():
        if _xml_name(node.tag) not in {'item', 'entry'}:
            continue
        url = _feed_link(node)
        canonical = normalize_post_url(url) if url else None
        if not canonical:
            continue
        post_id = canonical.rsplit('/', 1)[-1]
        timestamp = _child_text(node, {'pubdate', 'published', 'updated', 'modified'})
        current = candidates.get(post_id)
        if current is None or (timestamp or '') > (current.timestamp or ''):
            candidates[post_id] = FeedCandidate(post_id, timestamp)
    return [candidates[key] for key in sorted(candidates, key=_numeric_key)]


@dataclass(frozen=True)
class ReconciliationState:
    next_external_post_id: str | None = None
    state_version: str = DISCOVERY_STATE_VERSION
    source: str = SOURCE

    def __post_init__(self) -> None:
        if self.state_version != DISCOVERY_STATE_VERSION:
            raise ValueError(
                f'unsupported reconciliation state version {self.state_version!r}')
        if self.source != SOURCE:
            raise ValueError(f'unsupported reconciliation state source {self.source!r}')

    @classmethod
    def empty(cls) -> 'ReconciliationState':
        return cls()

    @classmethod
    def from_dict(cls, payload: dict) -> 'ReconciliationState':
        if not isinstance(payload, dict):
            raise ValueError('reconciliation state must be an object')
        return cls(
            next_external_post_id=payload.get('next_external_post_id'),
            state_version=payload.get('state_version'),
            source=payload.get('source'),
        )

    def as_dict(self) -> dict:
        return {
            'state_version': self.state_version,
            'source': self.source,
            'next_external_post_id': self.next_external_post_id,
        }

    def scan(self, inventory: list[str], limit: int) -> tuple[list[str], 'ReconciliationState']:
        ids = sorted({str(value) for value in inventory if str(value).isdigit()},
                     key=_numeric_key)
        if not ids or limit <= 0:
            return [], self
        if self.next_external_post_id is None:
            start = 0
        else:
            start = next((index for index, value in enumerate(ids)
                          if _numeric_key(value) >= _numeric_key(self.next_external_post_id)), 0)
        count = min(limit, len(ids))
        selected = [ids[(start + offset) % len(ids)] for offset in range(count)]
        next_id = ids[(start + count) % len(ids)]
        return selected, ReconciliationState(next_id)

    def write(self, path: Path) -> None:
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        fd, temporary = tempfile.mkstemp(prefix=f'.{path.name}.', dir=str(path.parent))
        try:
            with os.fdopen(fd, 'w', encoding='utf-8') as handle:
                import json
                json.dump(self.as_dict(), handle, ensure_ascii=False, sort_keys=True, indent=2)
                handle.write('\n')
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(temporary, path)
        except Exception:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass
            raise


@dataclass(frozen=True)
class DiscoveryCandidate:
    external_post_id: str
    priority: int
    sources: tuple[str, ...]
    sitemap_lastmod: str | None = None
    feed_timestamp: str | None = None
    reconciliation_rank: int | None = None

    def as_dict(self) -> dict:
        return {
            'external_post_id': self.external_post_id,
            'priority': self.priority,
            'sources': list(self.sources),
            'sitemap_lastmod': self.sitemap_lastmod,
            'feed_timestamp': self.feed_timestamp,
        }


@dataclass(frozen=True)
class DiscoveryPlan:
    candidates: tuple[DiscoveryCandidate, ...]
    cursor_before: ReconciliationState
    cursor_after: ReconciliationState
    reconciliation_scan: tuple[str, ...]
    landing_page_limit: int = NORMAL_LANDING_PAGE_LIMIT
    request_ceiling: int = ABSOLUTE_REQUEST_CEILING
    budget: dict = field(default_factory=lambda: {
        'ceiling': ABSOLUTE_REQUEST_CEILING,
        'requests': 0,
        'retries': 0,
        'remaining': ABSOLUTE_REQUEST_CEILING,
    })

    def as_dict(self) -> dict:
        return {
            'schema_version': DISCOVERY_SCHEMA_VERSION,
            'source': SOURCE,
            'candidate_selection_order': [c.external_post_id for c in self.candidates],
            'candidates': [c.as_dict() for c in self.candidates],
            'reconciliation_scan': list(self.reconciliation_scan),
            'cursor_before': self.cursor_before.as_dict(),
            'cursor_after': self.cursor_after.as_dict(),
            'landing_page_limit': self.landing_page_limit,
            'request_ceiling': self.request_ceiling,
            'budget': self.budget,
        }


def _accepted_lastmod(state: LocalDeltaState, post_id: str) -> str | None:
    entry = state.entries.get(post_id)
    return entry.accepted_source_times.get('sitemap_lastmod') if entry else None


def select_candidates(sitemap: list[SitemapEntry], feed: list[FeedCandidate],
                      accepted_state: LocalDeltaState | None = None,
                      pending_retry_ids: list[str] | tuple[str, ...] = (),
                      cursor: ReconciliationState | None = None,
                      limit: int = NORMAL_LANDING_PAGE_LIMIT,
                      budget: dict | None = None) -> DiscoveryPlan:
    """Merge discovery hints and select at most ``limit`` landing pages."""
    state = accepted_state or LocalDeltaState.empty()
    cursor = cursor or ReconciliationState.empty()
    sitemap_by_id = {entry.external_post_id: entry for entry in sitemap}
    feed_by_id = {entry.external_post_id: entry for entry in feed}
    info: dict[str, dict] = {}

    def add(post_id: str, priority: int, source: str, *, rank: int | None = None) -> None:
        post_id = str(post_id)
        item = info.setdefault(post_id, {
            'priority': priority, 'sources': set(), 'rank': rank,
            'sitemap_lastmod': None, 'feed_timestamp': None,
        })
        item['priority'] = min(item['priority'], priority)
        item['sources'].add(source)
        if rank is not None and (item['rank'] is None or rank < item['rank']):
            item['rank'] = rank

    for post_id in sorted({str(value) for value in pending_retry_ids
                           if str(value).isdigit()}, key=_numeric_key):
        add(post_id, 0, 'pending_retry')
    for post_id, entry in sorted(sitemap_by_id.items(), key=lambda item: _numeric_key(item[0])):
        known = post_id in state.entries
        if not known:
            add(post_id, 1, 'sitemap_new')
        elif entry.lastmod and entry.lastmod != _accepted_lastmod(state, post_id):
            add(post_id, 2, 'sitemap_lastmod')
        if post_id in info:
            info[post_id]['sitemap_lastmod'] = entry.lastmod
    for post_id, entry in sorted(feed_by_id.items(), key=lambda item: _numeric_key(item[0])):
        if post_id not in state.entries:
            add(post_id, 1, 'feed_new')
        else:
            add(post_id, 3, 'feed_recent')
        info[post_id]['feed_timestamp'] = entry.timestamp

    def sort_key(item: tuple[str, dict]) -> tuple:
        post_id, value = item
        tie = value['rank'] if value['priority'] == 4 else _numeric_key(post_id)
        return (value['priority'], tie)

    # Reserve landing-page slots for reconciliation only after higher-priority
    # candidates have been selected.  A full high-priority batch must not
    # consume an unseen cursor range that will not be fetched this run.
    priority_selected = sorted(info.items(), key=sort_key)[:max(0, limit)]
    remaining = max(0, limit - len(priority_selected))
    scan, cursor_after = cursor.scan(list(sitemap_by_id), remaining)
    for rank, post_id in enumerate(scan):
        add(post_id, 4, 'reconciliation', rank=rank)
        if post_id in sitemap_by_id:
            info[post_id]['sitemap_lastmod'] = sitemap_by_id[post_id].lastmod

    selected = []
    for post_id, value in sorted(info.items(), key=sort_key)[:max(0, limit)]:
        selected.append(DiscoveryCandidate(
            external_post_id=post_id,
            priority=value['priority'],
            sources=tuple(sorted(value['sources'])),
            sitemap_lastmod=value['sitemap_lastmod'],
            feed_timestamp=value['feed_timestamp'],
            reconciliation_rank=value['rank'],
        ))
    return DiscoveryPlan(tuple(selected), cursor, cursor_after, tuple(scan),
                         landing_page_limit=limit,
                         budget=budget or {
                             'ceiling': ABSOLUTE_REQUEST_CEILING,
                             'requests': 0,
                             'retries': 0,
                             'remaining': ABSOLUTE_REQUEST_CEILING,
                         })


@dataclass(frozen=True)
class NetworkDiscovery:
    sitemap: tuple[SitemapEntry, ...]
    feed: tuple[FeedCandidate, ...]
    feed_status: str
    robots_observed: bool
    budget: dict


class BoundedDiscoveryRunner:
    """Network-capable bounded observer; callers must explicitly invoke it."""

    def __init__(self, delay: float = DEFAULT_DELAY_SECONDS,
                 timeout: int = DEFAULT_TIMEOUT_SECONDS,
                 max_retries: int = DEFAULT_MAX_RETRIES,
                 fetcher: PoliteFetcher | None = None) -> None:
        if fetcher is not None:
            self.fetcher = fetcher
            self.budget = fetcher.request_budget or RequestBudget(ABSOLUTE_REQUEST_CEILING)
            self.fetcher.request_budget = self.budget
        else:
            self.budget = RequestBudget(ABSOLUTE_REQUEST_CEILING)
            self.fetcher = PoliteFetcher(
                delay=delay, timeout=timeout, max_retries=max_retries,
                max_requests=ABSOLUTE_REQUEST_CEILING,
                request_budget=self.budget)

    def discover(self, *, feed_url: str | None = None) -> NetworkDiscovery:
        """Fetch robots/sitemap and an explicitly supplied feed only.

        There is intentionally no default feed URL: the current repository has
        no verified LegendStudy RSS endpoint, so callers must supply one only
        after source verification.
        """
        self.fetcher.get(f'{SITE_ORIGIN}/robots.txt', accept=ACCEPT_HTML,
                         request_label='robots')
        sitemap_xml = self.fetcher.get(f'{SITE_ORIGIN}/sitemap.xml', accept=ACCEPT_XML,
                                       request_label='sitemap')
        sitemap = tuple(sitemap_entries(sitemap_xml))
        if feed_url is None:
            return NetworkDiscovery(sitemap, (), FEED_STATUS_UNAVAILABLE, True,
                                    self._budget_snapshot())
        feed_xml = self.fetcher.get(feed_url, accept=ACCEPT_XML, request_label='feed')
        return NetworkDiscovery(sitemap, tuple(parse_feed_candidates(feed_xml)),
                                FEED_STATUS_AVAILABLE, True, self._budget_snapshot())

    def fetch_landing_pages(self, plan: DiscoveryPlan) -> tuple[list[RawPost], list[str]]:
        posts: list[RawPost] = []
        failures: list[str] = []
        for candidate in plan.candidates[:NORMAL_LANDING_PAGE_LIMIT]:
            try:
                html = self.fetcher.get(f'{SITE_ORIGIN}/{candidate.external_post_id}',
                                        accept=ACCEPT_HTML,
                                        request_label=candidate.external_post_id)
                posts.append(parse_html(candidate.external_post_id, html))
            except FetchError:
                failures.append(candidate.external_post_id)
        return posts, failures

    def _budget_snapshot(self) -> dict:
        if self.fetcher.request_budget is not None:
            return self.fetcher.request_budget.as_dict()
        return {
            'ceiling': ABSOLUTE_REQUEST_CEILING,
            'requests': self.fetcher.stats.requests,
            'retries': self.fetcher.stats.retries,
            'remaining': max(0, ABSOLUTE_REQUEST_CEILING - self.fetcher.stats.requests),
        }

    def write_dry_run(self, result: DeltaRun, plan: DiscoveryPlan,
                      output_dir: Path, state_path: Path | None = None,
                      cursor_path: Path | None = None) -> tuple[Path, Path, Path | None]:
        """Write artifacts using this runner's actual shared request budget."""
        return write_bounded_dry_run(result, plan, output_dir, state_path,
                                     cursor_path, budget=self.budget)


def observe_selected(plan: DiscoveryPlan, posts: list[RawPost],
                     accepted_state: LocalDeltaState | None = None,
                     observed_at: str = '1970-01-01T00:00:00+00:00',
                     failed_ids: list[str] | tuple[str, ...] = ()) -> DeltaRun:
    """Pass selected landing-page observations directly to the B1 engine."""
    lastmods = {candidate.external_post_id: candidate.sitemap_lastmod
                for candidate in plan.candidates}
    # B1 currently accepts one shared lastmod value per call. The discovery
    # hint remains in plan/artifacts; classification never uses it as a delta.
    result = run_delta(posts, accepted_state, observed_at,
                       fetch_failed_ids=failed_ids)
    for candidate in result.candidates:
        if candidate.external_post_id in lastmods:
            lastmod = lastmods[candidate.external_post_id]
            candidate.source_times['sitemap_lastmod'] = lastmod
            entry = result.state_after.entries.get(candidate.external_post_id)
            if entry is not None and candidate.classification in {'NEW', 'MODIFIED', 'UNCHANGED'}:
                entry.accepted_source_times['sitemap_lastmod'] = lastmod
    return result


def write_bounded_dry_run(result: DeltaRun, plan: DiscoveryPlan,
                          output_dir: Path, state_path: Path | None = None,
                          cursor_path: Path | None = None,
                          budget: RequestBudget | dict | None = None) -> tuple[Path, Path, Path | None]:
    """Write B1 artifacts, then advance the reconciliation cursor safely."""
    actual_budget = (budget.as_dict() if isinstance(budget, RequestBudget)
                     else dict(budget) if budget is not None else dict(plan.budget))
    discovery = plan.as_dict()
    discovery['budget'] = actual_budget
    summary_extra = {
        'discovery': discovery,
        'candidate_selection_order': [c.external_post_id for c in plan.candidates],
        'source_budget': actual_budget,
    }
    paths = write_delta_artifacts(result, output_dir, state_path,
                                  summary_extra=summary_extra)
    # A cursor represents completed reconciliation observations, not merely
    # planned candidates.  Keep it unchanged for any failed or incomplete
    # observation, even though the safe diagnostic artifacts were finalized.
    cursor_safe = result.failed == 0 and all(
        candidate.observation_status == 'COMPLETE'
        and candidate.classification not in {
            'MALFORMED', 'AMBIGUOUS', 'SOURCE_MISSING', 'FETCH_FAILED'
        }
        for candidate in result.candidates)
    if cursor_path is not None and cursor_safe:
        plan.cursor_after.write(cursor_path)
    return paths
