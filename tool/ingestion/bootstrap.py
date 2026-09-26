"""Accepted-state bootstrap for Daily Sync Phase 1 (Track A / A1).

Problem (COLD_START_BASELINE_GAP): an empty ``LocalDeltaState`` makes the delta
engine classify already-published Production posts as ``NEW`` simply because no
local state exists. Old sitemap IDs (2, 4, 6, 7, 8, ...) were reported ``NEW``
for this reason, which does not mean they are new Production content.

Fix (Owner-approved OPTION 1): the Production canonical rows are the *authority*
for which posts are the accepted baseline; each such post is re-observed exactly
once through the existing bounded crawler/parser so its accepted-state fields are
built from the real source body rather than fabricated. There is no second state
model, no new hashing logic, no scheduler, and no Production write.

This module is deliberately offline and pure at its core:

* :func:`bootstrap_accepted_state` reconciles a canonical-ID authority set with a
  mapping of source observations and returns a ``LocalDeltaState``. It never
  touches the network or a database, so it is fully deterministic and testable.
* :func:`observe_canonical_posts` is the only network-capable helper. It reuses
  ``PoliteFetcher`` + ``parse_html`` under a request budget bounded to the
  canonical scope. Attachments are never fetched.
* :func:`main` is an explicit operator command, not a scheduler.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Mapping

from . import SOURCE
from .crawler import (
    ACCEPT_HTML, DEFAULT_DELAY_SECONDS, DEFAULT_MAX_RETRIES,
    DEFAULT_TIMEOUT_SECONDS, FetchError, PoliteFetcher, RequestBudget,
)
from .delta import LocalDeltaState, StateEntry, build_accepted_state_entry
from .models import RawPost
from .normalizer import normalize
from .parser import canonical_post_url, parse_html

BOOTSTRAP_SCHEMA_VERSION = 'legendstudy-accepted-bootstrap/1'

# Deterministic fail-closed reasons. A rejected post is never silently accepted.
REJECT_INVALID_IDENTITY = 'invalid_canonical_identity'
REJECT_DUPLICATE_IDENTITY = 'duplicate_canonical_identity'
REJECT_OBSERVATION_FAILED = 'source_observation_failed'
REJECT_IDENTITY_MISMATCH = 'identity_mismatch'
REJECT_MALFORMED_SOURCE = 'malformed_source'
REJECT_PARSER_FAILURE = 'parser_invariant_failure'


def _numeric_key(external_post_id: str) -> tuple[int, int | str]:
    value = str(external_post_id)
    return (0, int(value)) if value.isdigit() else (1, value)


@dataclass
class BootstrapResult:
    """Outcome of a bootstrap reconciliation.

    ``state`` contains accepted canonical posts only. ``rejected`` records the
    fail-closed reason per skipped post. No non-canonical post can be accepted.
    """
    state: LocalDeltaState
    accepted: list[str] = field(default_factory=list)
    rejected: list[dict] = field(default_factory=list)
    observed_at: str = '1970-01-01T00:00:00+00:00'
    baseline_count: int = 0
    source_requests_executed: int = 0
    source_request_budget: int = 0

    def report(self) -> dict:
        return {
            'schema_version': BOOTSTRAP_SCHEMA_VERSION,
            'source': SOURCE,
            'generated_at': self.observed_at,
            'baseline_count': self.baseline_count,
            'accepted_count': len(self.accepted),
            'accepted': sorted(self.accepted, key=_numeric_key),
            'rejected_count': len(self.rejected),
            'rejected': sorted(self.rejected,
                               key=lambda row: _numeric_key(row['external_post_id'])),
            # Only canonical baseline identities can ever enter the accepted set.
            'non_canonical_accepted': 0,
            'source_reobservation_required': True,
            'source_request_budget': self.source_request_budget,
            'source_requests_executed': self.source_requests_executed,
            'attachment_fetch_count': 0,
            'production_mutation': 0,
            'database_migration': 0,
            'scheduler_created': 0,
            'state_version': self.state.state_version,
            'state_fingerprint': self.state.fingerprint(),
        }


def _valid_baseline(baseline_ids: Iterable[str]) -> tuple[list[str], list[dict]]:
    """Return (unique valid canonical ids, rejections for invalid/duplicate)."""
    rejected: list[dict] = []
    counts: dict[str, int] = {}
    order: list[str] = []
    for raw in baseline_ids:
        value = str(raw)
        if value not in counts:
            order.append(value)
        counts[value] = counts.get(value, 0) + 1
    valid: list[str] = []
    for value in order:
        if not value.isdigit():
            rejected.append({'external_post_id': value,
                             'reason': REJECT_INVALID_IDENTITY})
        elif counts[value] > 1:
            # A canonical identity that appears twice is ambiguous, not accepted.
            rejected.append({'external_post_id': value,
                             'reason': REJECT_DUPLICATE_IDENTITY})
        else:
            valid.append(value)
    return valid, rejected


def bootstrap_accepted_state(
    baseline_ids: Iterable[str],
    observations: Mapping[str, RawPost | None],
    observed_at: str = '1970-01-01T00:00:00+00:00',
    *,
    sitemap_lastmods: Mapping[str, str | None] | None = None,
    map_subjects: bool = False,
    source_request_budget: int = 0,
    source_requests_executed: int = 0,
) -> BootstrapResult:
    """Reconcile a canonical baseline with source observations (pure/offline).

    ``baseline_ids`` is the Production authority: only these external post IDs may
    be accepted. ``observations`` maps each ID to a re-observed ``RawPost`` (or
    ``None`` when its bounded fetch failed). The accepted-state fields are built
    with the existing delta helpers, never fabricated. Any mismatch, duplicate,
    malformed source, parser failure, or missing observation fails closed.
    """
    sitemap_lastmods = sitemap_lastmods or {}
    valid_ids, rejected = _valid_baseline(baseline_ids)
    baseline_count = len(valid_ids) + len(rejected)
    state = LocalDeltaState.empty()
    accepted: list[str] = []

    for post_id in sorted(valid_ids, key=_numeric_key):
        observation = observations.get(post_id)
        if observation is None:
            rejected.append({'external_post_id': post_id,
                             'reason': REJECT_OBSERVATION_FAILED})
            continue
        if str(observation.external_post_id) != post_id:
            rejected.append({'external_post_id': post_id,
                             'reason': REJECT_IDENTITY_MISMATCH})
            continue
        if (not post_id.isdigit() or not observation.title
                or not observation.category):
            rejected.append({'external_post_id': post_id,
                             'reason': REJECT_MALFORMED_SOURCE})
            continue
        try:
            plan = normalize(observation, observed_at, map_subjects=map_subjects)
        except Exception:
            # Never leak a raw parser error; fail closed on this post only.
            rejected.append({'external_post_id': post_id,
                             'reason': REJECT_PARSER_FAILURE})
            continue
        entry: StateEntry = build_accepted_state_entry(
            observation, plan, observed_at, sitemap_lastmods.get(post_id))
        state.entries[post_id] = entry
        accepted.append(post_id)

    return BootstrapResult(
        state=state,
        accepted=accepted,
        rejected=rejected,
        observed_at=observed_at,
        baseline_count=baseline_count,
        source_requests_executed=source_requests_executed,
        source_request_budget=source_request_budget,
    )


def observe_canonical_posts(
    baseline_ids: Iterable[str],
    *,
    fetcher: PoliteFetcher | None = None,
    delay: float = DEFAULT_DELAY_SECONDS,
    timeout: int = DEFAULT_TIMEOUT_SECONDS,
    max_retries: int = DEFAULT_MAX_RETRIES,
) -> tuple[dict[str, RawPost | None], int, int]:
    """Bounded one-time re-observation of canonical landing pages.

    Reuses the existing ``PoliteFetcher`` (serial, polite delay, timeout, retries)
    and ``parse_html``. The request budget is bounded to the canonical scope; no
    attachment bytes are ever fetched. Returns ``(observations, budget, used)``.
    """
    ids, _ = _valid_baseline(baseline_ids)
    ids = sorted(set(ids), key=_numeric_key)
    ceiling = max(1, len(ids)) * (max_retries + 1)
    if fetcher is None:
        budget = RequestBudget(ceiling)
        fetcher = PoliteFetcher(
            delay=delay, timeout=timeout, max_retries=max_retries,
            max_requests=ceiling, request_budget=budget)
    observations: dict[str, RawPost | None] = {}
    for post_id in ids:
        try:
            html = fetcher.get(canonical_post_url(post_id), accept=ACCEPT_HTML,
                               request_label=post_id)
            observations[post_id] = parse_html(post_id, html)
        except FetchError:
            # Fetch failure is fail-closed evidence, not a deletion or acceptance.
            observations[post_id] = None
    used = fetcher.request_budget.requests if fetcher.request_budget else 0
    return observations, ceiling, used


def load_baseline(path: Path) -> list[str]:
    """Load the operator-provided canonical baseline authority.

    Expected shape produced by a read-only Production query:
    ``{"source": "legendstudy", "external_post_ids": ["1661", ...]}``.
    """
    payload = json.loads(Path(path).read_text(encoding='utf-8'))
    if not isinstance(payload, dict):
        raise ValueError('baseline file must be a JSON object')
    if payload.get('source') != SOURCE:
        raise ValueError(f'unexpected baseline source {payload.get("source")!r}')
    ids = payload.get('external_post_ids')
    if not isinstance(ids, list):
        raise ValueError('baseline external_post_ids must be a list')
    return [str(value) for value in ids]


def write_bootstrap_artifacts(result: BootstrapResult, state_path: Path,
                              report_path: Path) -> tuple[Path, Path]:
    """Persist the accepted state (existing contract) and a redacted report."""
    state_path = Path(state_path)
    report_path = Path(report_path)
    result.state.write(state_path)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        json.dumps(result.report(), ensure_ascii=False, sort_keys=True, indent=2)
        + '\n', encoding='utf-8')
    return state_path, report_path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog='ingestion.bootstrap',
        description='Bootstrap Daily Sync accepted state from the canonical '
                    'Production baseline (offline reconcile + bounded re-observe).')
    parser.add_argument('--baseline', required=True, type=Path,
                        help='canonical baseline JSON from a read-only Production '
                             'query: {"source":"legendstudy","external_post_ids":[...]}')
    parser.add_argument('--state-out', required=True, type=Path,
                        help='output path for the serialized accepted LocalDeltaState')
    parser.add_argument('--report-out', required=True, type=Path,
                        help='output path for the redacted bootstrap report JSON')
    parser.add_argument('--observe', action='store_true',
                        help='perform the bounded one-time source re-observation '
                             '(network). Without it, no network access occurs.')
    parser.add_argument('--observed-at', default='1970-01-01T00:00:00+00:00',
                        help='observation-only timestamp; does not affect the '
                             'semantic accepted-state fingerprint.')
    args = parser.parse_args(argv)

    baseline = load_baseline(args.baseline)
    if not args.observe:
        parser.error('refusing to bootstrap without --observe: the accepted state '
                     'requires a real source observation, never fabricated fields.')
    observations, budget, used = observe_canonical_posts(baseline)
    result = bootstrap_accepted_state(
        baseline, observations, observed_at=args.observed_at,
        source_request_budget=budget, source_requests_executed=used)
    write_bootstrap_artifacts(result, args.state_out, args.report_out)
    print(json.dumps(result.report(), ensure_ascii=False, sort_keys=True, indent=2))
    return 0


if __name__ == '__main__':  # pragma: no cover
    raise SystemExit(main())
