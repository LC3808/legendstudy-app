"""Dry-run aggregation: plans, duplicates, change detection, statistics."""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

from .models import PlannedPost, QuarantineCase, RawPost
from .normalizer import BLOCKING, exam_identity, normalize


@dataclass
class DryRunResult:
    plans: list[PlannedPost] = field(default_factory=list)
    quarantine: list[QuarantineCase] = field(default_factory=list)
    changed: list[str] = field(default_factory=list)
    unchanged: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)
    merge_candidates: list[dict] = field(default_factory=list)
    parse_errors: list[dict] = field(default_factory=list)

    def counts(self) -> dict:
        by_type = Counter(p.content_item['content_type'] for p in self.plans if p.content_item)
        by_conf = Counter(p.confidence for p in self.plans)
        kinds = Counter(c.kind for c in self.quarantine)
        resources = [r for p in self.plans for r in p.resources]
        return {
            'posts_parsed': len(self.plans),
            'parse_errors': len(self.parse_errors),
            'content_items': sum(1 for p in self.plans if p.content_item),
            'content_types': dict(sorted(by_type.items())),
            'exams': sum(1 for p in self.plans if p.exam),
            'exam_subjects': sum(len(p.occurrences) for p in self.plans),
            'resources': len(resources),
            'resource_types': dict(sorted(Counter(r['resource_type'] for r in resources).items())),
            'link_kinds': dict(sorted(Counter(r['link_kind'] for r in resources).items())),
            'providers': dict(sorted(Counter(r['provider'] for r in resources).items())),
            'confidence': dict(sorted(by_conf.items())),
            'publish_candidates': sum(1 for p in self.plans if p.publishable),
            'quarantine_cases': len(self.quarantine),
            'quarantine_posts': len({c.external_post_id for c in self.quarantine}),
            'quarantine_blocking_posts': len({
                c.external_post_id for c in self.quarantine if c.kind in BLOCKING}),
            'quarantine_kinds': dict(sorted(kinds.items())),
            'changed': len(self.changed),
            'unchanged': len(self.unchanged),
            'missing_sources': len(self.missing),
            'merge_candidates': len(self.merge_candidates),
        }


def load_state(path: Path | None) -> dict:
    if path and Path(path).exists():
        return json.loads(Path(path).read_text(encoding='utf-8'))
    return {}


def run(posts: list[RawPost], crawled_at: str, previous: dict | None = None) -> DryRunResult:
    previous = previous or {}
    result = DryRunResult()
    by_identity: dict[tuple, list[str]] = defaultdict(list)

    for post in posts:
        try:
            plan = normalize(post, crawled_at)
        except Exception as exc:  # parser invariant failure: never silent
            result.parse_errors.append({
                'external_post_id': post.external_post_id,
                'error': f'{type(exc).__name__}: {exc}',
            })
            continue
        result.plans.append(plan)
        result.quarantine.extend(plan.quarantine)

        digest = plan.source_post['content_hash']
        if previous.get(post.external_post_id) == digest:
            result.unchanged.append(post.external_post_id)
        else:
            result.changed.append(post.external_post_id)

        identity = exam_identity(plan)
        if identity:
            by_identity[identity].append(post.external_post_id)

    for identity, ids in sorted(by_identity.items()):
        if len(ids) > 1:
            case = QuarantineCase(
                'merge_candidate_exam', ids[0],
                'Several source posts normalise to one canonical exam identity; '
                'human review decides the canonical content item.',
                {'identity': list(identity), 'external_post_ids': sorted(ids)})
            result.quarantine.append(case)
            result.merge_candidates.append(case.payload)

    # Sources present in prior state but absent from this run are never deleted.
    for known in previous:
        if known not in {p.external_post_id for p in posts}:
            result.missing.append(known)
            result.quarantine.append(QuarantineCase(
                'source_missing', known,
                'Previously ingested source post was not observed in this run. '
                'Sets source_status for review; never unpublishes content.', {}))
    return result


def next_state(result: DryRunResult, previous: dict | None = None) -> dict:
    state = dict(previous or {})
    for plan in result.plans:
        state[plan.external_post_id] = plan.source_post['content_hash']
    return state
