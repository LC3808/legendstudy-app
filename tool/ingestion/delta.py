"""Offline deterministic Phase 1-B1 delta core.

This module deliberately has no network, database, scheduler, or publication
dependency.  It compares a complete local observation with an accepted local
snapshot and writes only redacted local artifacts.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import tempfile
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

from . import MAPPING_RULE_VERSION, PARSER_VERSION, SOURCE
from .models import PlannedPost, RawPost
from .normalizer import content_hash, normalize

STATE_VERSION = 'legendstudy-delta-state/1'
ARTIFACT_SCHEMA_VERSION = 'legendstudy-delta-artifacts/1'
CLASSIFICATIONS = frozenset({'NEW', 'UNCHANGED', 'MODIFIED', 'MALFORMED', 'AMBIGUOUS'})
OBSERVATION_STATUSES = frozenset({
    'COMPLETE', 'COMPLETE_BUT_INVALID', 'COMPLETE_BUT_CONFLICTING',
    'COMPLETE_BUT_UNSAFE_IDENTITY', 'PARTIAL', 'OBSERVATION_ONLY', 'FETCH_FAILED',
})


class DeltaStateError(ValueError):
    """Invalid, unsupported, or mismatched local state."""


class ArtifactWriteError(OSError):
    """Raised when a complete artifact set cannot be finalized."""


def _canonical_json(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(',', ':'))


def _sha256(value: object) -> str:
    return hashlib.sha256(_canonical_json(value).encode('utf-8')).hexdigest()


def _normalize_text(value: str | None) -> str:
    return ' '.join((value or '').split())


def _safe_source_times(post: RawPost, sitemap_lastmod: str | None = None) -> dict:
    return {
        'published_at': post.published_at,
        'updated_at': post.updated_at,
        'sitemap_lastmod': sitemap_lastmod,
    }


def _resource_descriptor(resource: dict) -> dict:
    """Keep only stable, non-secret resource projection fields."""
    return {
        'provider': resource.get('provider'),
        'source_resource_key': resource.get('source_resource_key'),
        'resource_type': resource.get('resource_type'),
        'display_label_fingerprint': _sha256(_normalize_text(resource.get('title'))),
        'occurrence_subject_key': resource.get('occurrence_subject_key'),
        'link_kind': resource.get('link_kind'),
        'unsigned_locator_fingerprint': _sha256(resource.get('source_url') or ''),
        'file_extension': resource.get('file_extension'),
    }


def _resource_key(resource: dict) -> tuple[str, str]:
    return (str(resource.get('provider') or ''),
            str(resource.get('source_resource_key') or ''))


def _post_id_sort_key(external_post_id: str) -> tuple[int, int | str]:
    """Numeric LegendStudy IDs sort numerically, with a safe text fallback."""
    value = str(external_post_id)
    return (0, int(value)) if value.isdigit() else (1, value)


def _safe_projection(post: RawPost, plan: PlannedPost, sitemap_lastmod: str | None) -> dict:
    exam = plan.exam or {}
    occurrences = [{
        'source_subject_key': item.get('source_subject_key'),
        'subject_id': item.get('subject_id'),
        'mapping_status': item.get('mapping_status'),
        'mapping_confidence': item.get('mapping_confidence'),
        'mapping_note': item.get('mapping_note'),
    } for item in sorted(plan.occurrences,
                         key=lambda item: str(item.get('source_subject_key') or ''))]
    resources = sorted((_resource_descriptor(resource) for resource in plan.resources),
                       key=_resource_key)
    return {
        'source': SOURCE,
        'external_post_id': post.external_post_id,
        'title': _normalize_text(post.title),
        'category': _normalize_text(post.category),
        # Sitemap lastmod is discovery evidence, not semantic content. It is
        # retained in the candidate/state metadata but excluded from the
        # observation fingerprint so a sitemap-only change cannot be false MODIFIED.
        'source_times': {
            'published_at': post.published_at,
            'updated_at': post.updated_at,
        },
        'content_type': (plan.content_item or {}).get('content_type'),
        'exam': {
            key: exam.get(key) for key in (
                'year', 'academic_year', 'exam_month', 'grade_level', 'exam_type',
                'exam_round', 'curriculum_version',
            )
        },
        'occurrences': occurrences,
        'resources': resources,
        # Store only a digest and diagnostics, never the observed body.
        'body_fingerprint': _sha256(_normalize_text(post.body_excerpt)),
        'body_length': len(_normalize_text(post.body_excerpt)),
    }


def safe_observation_fingerprint(post: RawPost, plan: PlannedPost,
                                 sitemap_lastmod: str | None = None) -> str:
    """Hash semantic source evidence while excluding crawl/signing material."""
    return _sha256(_safe_projection(post, plan, sitemap_lastmod))


def _accepted_projection_from_plan(post: RawPost, plan: PlannedPost,
                                   sitemap_lastmod: str | None) -> dict:
    return _safe_projection(post, plan, sitemap_lastmod)


def _entry_projection(entry: dict) -> dict:
    projection = entry.get('accepted_projection')
    if isinstance(projection, dict):
        return projection
    # State created by this module always has accepted_projection.  This
    # fallback makes malformed legacy-like entries rejectable by validation.
    return {}


@dataclass(frozen=True)
class StateEntry:
    source: str
    external_post_id: str
    accepted_canonical_hash: str
    accepted_observation_fingerprint: str
    accepted_source_times: dict
    accepted_projection: dict
    accepted_resource_descriptors: tuple[dict, ...]
    last_successful_observation_at: str | None
    last_observation_status: str = 'COMPLETE'

    def as_dict(self) -> dict:
        return {
            'source': self.source,
            'external_post_id': self.external_post_id,
            'accepted_canonical_hash': self.accepted_canonical_hash,
            'accepted_observation_fingerprint': self.accepted_observation_fingerprint,
            'accepted_source_times': self.accepted_source_times,
            'accepted_projection': self.accepted_projection,
            'accepted_resource_descriptors': list(self.accepted_resource_descriptors),
            'last_successful_observation_at': self.last_successful_observation_at,
            'last_observation_status': self.last_observation_status,
        }


@dataclass
class LocalDeltaState:
    entries: dict[str, StateEntry] = field(default_factory=dict)
    state_version: str = STATE_VERSION
    source: str = SOURCE

    def __post_init__(self) -> None:
        if self.state_version != STATE_VERSION:
            raise DeltaStateError(
                f'unsupported state_version {self.state_version!r}; expected {STATE_VERSION!r}')
        if self.source != SOURCE:
            raise DeltaStateError(f'unsupported state source {self.source!r}')

    @classmethod
    def empty(cls) -> 'LocalDeltaState':
        return cls()

    @classmethod
    def from_dict(cls, payload: dict) -> 'LocalDeltaState':
        if not isinstance(payload, dict):
            raise DeltaStateError('local state must be an object')
        version = payload.get('state_version')
        if version != STATE_VERSION:
            raise DeltaStateError(
                f'unsupported state_version {version!r}; expected {STATE_VERSION!r}')
        source = payload.get('source')
        if source != SOURCE:
            raise DeltaStateError(f'unsupported state source {source!r}')
        raw_entries = payload.get('entries')
        if not isinstance(raw_entries, dict):
            raise DeltaStateError('local state entries must be an object')
        entries: dict[str, StateEntry] = {}
        for key, raw in raw_entries.items():
            if not isinstance(raw, dict) or raw.get('external_post_id') != key:
                raise DeltaStateError(f'invalid state entry {key!r}')
            required = ('accepted_canonical_hash', 'accepted_observation_fingerprint',
                        'accepted_source_times', 'accepted_projection',
                        'accepted_resource_descriptors')
            if any(field_name not in raw for field_name in required):
                raise DeltaStateError(f'incomplete state entry {key!r}')
            descriptors = raw['accepted_resource_descriptors']
            if not isinstance(descriptors, list):
                raise DeltaStateError(f'invalid resource descriptors for {key!r}')
            entries[key] = StateEntry(
                source=raw.get('source', SOURCE),
                external_post_id=key,
                accepted_canonical_hash=raw['accepted_canonical_hash'],
                accepted_observation_fingerprint=raw['accepted_observation_fingerprint'],
                accepted_source_times=raw['accepted_source_times'],
                accepted_projection=raw['accepted_projection'],
                accepted_resource_descriptors=tuple(descriptors),
                last_successful_observation_at=raw.get('last_successful_observation_at'),
                last_observation_status=raw.get('last_observation_status', 'COMPLETE'),
            )
            if entries[key].source != SOURCE:
                raise DeltaStateError(f'unsupported source in state entry {key!r}')
        return cls(entries=entries, state_version=version, source=source)

    def as_dict(self) -> dict:
        return {
            'state_version': self.state_version,
            'source': self.source,
            'entries': {key: self.entries[key].as_dict()
                        for key in sorted(self.entries)},
        }

    def fingerprint(self) -> str:
        """Stable accepted-projection fingerprint, excluding observation clocks."""
        semantic_entries = []
        for key in sorted(self.entries):
            entry = self.entries[key]
            semantic_entries.append({
                'source': entry.source,
                'external_post_id': entry.external_post_id,
                'accepted_canonical_hash': entry.accepted_canonical_hash,
                'accepted_observation_fingerprint': entry.accepted_observation_fingerprint,
                'accepted_source_times': entry.accepted_source_times,
                'accepted_projection': entry.accepted_projection,
                'accepted_resource_descriptors': list(entry.accepted_resource_descriptors),
            })
        return _sha256({'state_version': self.state_version,
                        'source': self.source, 'entries': semantic_entries})

    def write(self, path: Path) -> None:
        _atomic_write_json(Path(path), self.as_dict())


def load_delta_state(path: Path | None) -> LocalDeltaState:
    if path is None or not Path(path).exists():
        return LocalDeltaState.empty()
    try:
        payload = json.loads(Path(path).read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        raise DeltaStateError(f'cannot read local state: {type(exc).__name__}') from exc
    return LocalDeltaState.from_dict(payload)


def _entry_for(post: RawPost, plan: PlannedPost, observed_at: str,
               sitemap_lastmod: str | None) -> StateEntry:
    projection = _accepted_projection_from_plan(post, plan, sitemap_lastmod)
    descriptors = tuple(sorted((_resource_descriptor(resource) for resource in plan.resources),
                               key=_resource_key))
    return StateEntry(
        source=SOURCE,
        external_post_id=post.external_post_id,
        accepted_canonical_hash=content_hash(post),
        accepted_observation_fingerprint=safe_observation_fingerprint(
            post, plan, sitemap_lastmod),
        accepted_source_times=_safe_source_times(post, sitemap_lastmod),
        accepted_projection=projection,
        accepted_resource_descriptors=descriptors,
        last_successful_observation_at=observed_at,
    )


def _resource_diff(before: list[dict], after: list[dict]) -> tuple[list[dict], list[dict], list[dict]]:
    before_map = {_resource_key(resource): resource for resource in before}
    after_map = {_resource_key(resource): resource for resource in after}
    added = [after_map[key] for key in sorted(set(after_map) - set(before_map))]
    changed = [after_map[key] for key in sorted(set(after_map) & set(before_map))
               if before_map[key] != after_map[key]]
    absent = [before_map[key] for key in sorted(set(before_map) - set(after_map))]
    return added, changed, absent


def _change_categories(before: dict | None, after: dict, before_resources: list[dict],
                       after_resources: list[dict], observation_fingerprint: str,
                       prior_observation_fingerprint: str | None) -> tuple[list[str], dict]:
    categories: list[str] = []
    if before is None:
        return categories, {'added': [], 'changed': [], 'unconfirmed_absent': []}
    if before.get('title') != after.get('title'):
        categories.append('title_changed')
    if before.get('category') != after.get('category'):
        categories.append('category_changed')
    before_times = before.get('source_times', {})
    after_times = after.get('source_times', {})
    if before_times.get('published_at') != after_times.get('published_at'):
        categories.append('source_published_time_changed')
    if before_times.get('updated_at') != after_times.get('updated_at'):
        categories.append('source_updated_time_changed')
    if before.get('exam') != after.get('exam'):
        categories.append('exam_metadata_changed')
    if before.get('occurrences') != after.get('occurrences'):
        categories.append('subject_mapping_changed')
    if (prior_observation_fingerprint is not None
            and prior_observation_fingerprint != observation_fingerprint
            and before.get('body_fingerprint') != after.get('body_fingerprint')):
        categories.append('body_or_metadata_changed')
    added, changed, absent = _resource_diff(before_resources, after_resources)
    if added:
        categories.append('resource_added')
    if changed:
        categories.append('resource_changed')
    if absent:
        categories.append('resource_unconfirmed_absent')
    return sorted(set(categories)), {
        'added': added,
        'changed': changed,
        'unconfirmed_absent': absent,
    }


@dataclass
class DeltaCandidate:
    source: str
    external_post_id: str
    classification: str
    observation_status: str
    source_times: dict
    safe_metadata: dict
    change_categories: list[str] = field(default_factory=list)
    resource_change_summary: dict = field(default_factory=lambda: {
        'added': [], 'changed': [], 'unconfirmed_absent': [],
    })
    review_flags: list[str] = field(default_factory=list)
    before_fingerprint: str | None = None
    after_fingerprint: str | None = None
    safe_error_kind: str | None = None
    _accepted_entry: StateEntry | None = field(default=None, repr=False, compare=False)
    _observed_entry: StateEntry | None = field(default=None, repr=False, compare=False)

    def as_dict(self) -> dict:
        result = {
            'source': self.source,
            'external_post_id': self.external_post_id,
            'classification': self.classification,
            'observation_status': self.observation_status,
            'source_times': self.source_times,
            'safe_metadata': self.safe_metadata,
            'change_categories': self.change_categories,
            'resource_change_summary': self.resource_change_summary,
            'review_flags': self.review_flags,
            'before_fingerprint': self.before_fingerprint,
            'after_fingerprint': self.after_fingerprint,
        }
        if self.safe_error_kind:
            result['safe_error_kind'] = self.safe_error_kind
        return result


@dataclass
class DeltaRun:
    candidates: list[DeltaCandidate]
    state_before: LocalDeltaState
    state_after: LocalDeltaState
    generated_at: str
    failed: int = 0

    def summary(self) -> dict:
        counts = {key: 0 for key in (
            'observed', 'new', 'modified', 'unchanged', 'malformed', 'ambiguous',
            'source_missing', 'failed', 'skipped', 'skipped_by_budget',
        )}
        counts['observed'] = len(self.candidates)
        for candidate in self.candidates:
            name = candidate.classification.lower()
            if name in counts:
                counts[name] += 1
            if candidate.observation_status == 'FETCH_FAILED':
                counts['failed'] += 1
        counts['failed'] = max(counts['failed'], self.failed)
        return {
            'schema_version': ARTIFACT_SCHEMA_VERSION,
            'parser_version': PARSER_VERSION,
            'mapping_rule_version': MAPPING_RULE_VERSION,
            'dry_run': True,
            'generated_at': self.generated_at,
            'counts': counts,
            'source_budget': {
                'mode': 'offline-only',
                'max_requests': 0,
                'requests_used': 0,
            },
            'candidate_selection_order': [c.external_post_id for c in self.candidates],
            'input_state_version': self.state_before.state_version,
            'input_state_fingerprint': self.state_before.fingerprint(),
            'output_state_version': self.state_after.state_version,
            'output_state_fingerprint': self.state_after.fingerprint(),
            'production_mutation': 0,
            'database_migration': 0,
            'scheduler_created': 0,
            'publication': 0,
        }


def _safe_metadata(plan: PlannedPost) -> dict:
    exam = plan.exam or {}
    counts = Counter((resource.get('provider'), resource.get('resource_type'))
                     for resource in plan.resources)
    return {
        'content_type': (plan.content_item or {}).get('content_type'),
        'exam_summary': {key: exam.get(key) for key in (
            'year', 'academic_year', 'exam_month', 'grade_level', 'exam_type')},
        'attachment_counts_by_provider_and_kind': {
            f"{provider}:{kind}": count
            for (provider, kind), count in sorted(
                counts.items(), key=lambda item: (str(item[0][0]), str(item[0][1])))
        },
    }


def _candidate_for(post: RawPost, plan: PlannedPost, state: LocalDeltaState,
                   observed_at: str, *, sitemap_lastmod: str | None = None,
                   observation_status: str = 'COMPLETE',
                   force_classification: str | None = None,
                   review_flags: Iterable[str] = ()) -> DeltaCandidate:
    post_id = post.external_post_id
    after_projection = _safe_projection(post, plan, sitemap_lastmod)
    evidence_complete = observation_status in {
        'COMPLETE', 'COMPLETE_BUT_UNSAFE_IDENTITY', 'COMPLETE_BUT_CONFLICTING',
    }
    after_fingerprint = (safe_observation_fingerprint(post, plan, sitemap_lastmod)
                         if evidence_complete else None)
    observed_entry = _entry_for(post, plan, observed_at, sitemap_lastmod)
    accepted = state.entries.get(post_id)
    if force_classification:
        classification = force_classification
    elif observation_status != 'COMPLETE':
        classification = 'MALFORMED'
    elif accepted is None:
        classification = 'NEW'
    elif accepted.accepted_observation_fingerprint == after_fingerprint:
        classification = 'UNCHANGED'
    else:
        classification = 'MODIFIED'
    before_projection = _entry_projection(accepted.as_dict()) if accepted else None
    before_resources = list(accepted.accepted_resource_descriptors) if accepted else []
    if evidence_complete:
        categories, resource_summary = _change_categories(
            before_projection, after_projection,
            before_resources, list(observed_entry.accepted_resource_descriptors),
            after_fingerprint or '',
            accepted.accepted_observation_fingerprint if accepted else None,
        )
    else:
        # Incomplete/malformed observations are not semantic evidence. In
        # particular, omitted resources and partial subject facts must not
        # become resource absence or mapping-change claims.
        categories = []
        resource_summary = {'added': [], 'changed': [], 'unconfirmed_absent': []}
    return DeltaCandidate(
        source=SOURCE,
        external_post_id=post_id,
        classification=classification,
        observation_status=observation_status,
        source_times=_safe_source_times(post, sitemap_lastmod),
        safe_metadata=_safe_metadata(plan),
        change_categories=categories,
        resource_change_summary=resource_summary,
        review_flags=sorted(set(review_flags)),
        before_fingerprint=(accepted.accepted_observation_fingerprint if accepted else None),
        after_fingerprint=after_fingerprint,
        _accepted_entry=accepted,
        _observed_entry=observed_entry,
    )


def classify_delta(post: RawPost, accepted_state: LocalDeltaState | dict | None,
                   observed_at: str, *, sitemap_lastmod: str | None = None,
                   observation_status: str = 'COMPLETE',
                   ambiguous_reason: str | None = None,
                   map_subjects: bool = False) -> DeltaCandidate:
    """Classify one complete local observation deterministically."""
    state = (accepted_state if isinstance(accepted_state, LocalDeltaState)
             else LocalDeltaState.from_dict(accepted_state)
             if accepted_state is not None else LocalDeltaState.empty())
    try:
        plan = normalize(post, observed_at, map_subjects=map_subjects)
    except Exception as exc:
        accepted = state.entries.get(post.external_post_id)
        return DeltaCandidate(
            source=SOURCE,
            external_post_id=post.external_post_id,
            classification='MALFORMED',
            observation_status='COMPLETE_BUT_INVALID',
            source_times=_safe_source_times(post, sitemap_lastmod),
            safe_metadata={},
            review_flags=['parser_invariant_failure'],
            before_fingerprint=(accepted.accepted_observation_fingerprint
                                if accepted else None),
            safe_error_kind=type(exc).__name__,
            _accepted_entry=accepted,
        )
    if ambiguous_reason:
        return _candidate_for(post, plan, state, observed_at,
                              sitemap_lastmod=sitemap_lastmod,
                              observation_status='COMPLETE_BUT_UNSAFE_IDENTITY',
                              force_classification='AMBIGUOUS',
                              review_flags=(ambiguous_reason,))
    if not post.external_post_id.isdigit() or not post.title or not post.category:
        return _candidate_for(post, plan, state, observed_at,
                              sitemap_lastmod=sitemap_lastmod,
                              observation_status='COMPLETE_BUT_INVALID',
                              force_classification='MALFORMED',
                              review_flags=('required_source_fact_missing',))
    return _candidate_for(post, plan, state, observed_at,
                          sitemap_lastmod=sitemap_lastmod,
                          observation_status=observation_status)


def source_missing_candidate(external_post_id: str, state: LocalDeltaState,
                             observed_at: str) -> DeltaCandidate:
    accepted = state.entries.get(external_post_id)
    return DeltaCandidate(
        source=SOURCE,
        external_post_id=external_post_id,
        classification='SOURCE_MISSING',
        observation_status='OBSERVATION_ONLY',
        source_times=(accepted.accepted_source_times if accepted else {
            'published_at': None, 'updated_at': None, 'sitemap_lastmod': None}),
        safe_metadata={},
        review_flags=['source_absent_from_complete_inventory'],
        before_fingerprint=(accepted.accepted_observation_fingerprint if accepted else None),
        after_fingerprint=None,
        _accepted_entry=accepted,
    )


def fetch_failed_candidate(external_post_id: str, state: LocalDeltaState,
                           observed_at: str, reason_kind: str = 'transport_failure') -> DeltaCandidate:
    accepted = state.entries.get(external_post_id)
    return DeltaCandidate(
        source=SOURCE,
        external_post_id=external_post_id,
        classification='FETCH_FAILED',
        observation_status='FETCH_FAILED',
        source_times=(accepted.accepted_source_times if accepted else {
            'published_at': None, 'updated_at': None, 'sitemap_lastmod': None}),
        safe_metadata={},
        review_flags=['last_known_good_preserved'],
        before_fingerprint=(accepted.accepted_observation_fingerprint if accepted else None),
        safe_error_kind=reason_kind,
        _accepted_entry=accepted,
    )


def run_delta(posts: Iterable[RawPost], accepted_state: LocalDeltaState | dict | None = None,
              observed_at: str = '1970-01-01T00:00:00+00:00', *,
              source_missing_ids: Iterable[str] = (),
              fetch_failed_ids: Iterable[str] = (),
              partial_ids: Iterable[str] = (),
              ambiguous_ids: Iterable[str] = (),
              subject_ambiguous_ids: Iterable[str] = (),
              map_subjects: bool = False) -> DeltaRun:
    state = (accepted_state if isinstance(accepted_state, LocalDeltaState)
             else LocalDeltaState.from_dict(accepted_state)
             if accepted_state is not None else LocalDeltaState.empty())
    posts = list(posts)
    partial_ids = set(str(value) for value in partial_ids)
    ambiguous_ids = set(str(value) for value in ambiguous_ids)
    subject_ambiguous_ids = set(str(value) for value in subject_ambiguous_ids)
    by_id: dict[str, list[RawPost]] = {}
    for post in posts:
        by_id.setdefault(post.external_post_id, []).append(post)
    candidates: list[DeltaCandidate] = []
    for post_id in sorted(by_id, key=_post_id_sort_key):
        observations = by_id[post_id]
        first = observations[0]
        if len(observations) > 1:
            # Conflicting duplicate observations never use last-writer-wins.
            plans = [normalize(item, observed_at, map_subjects=map_subjects)
                     for item in observations]
            fingerprints = {safe_observation_fingerprint(item, plan)
                            for item, plan in zip(observations, plans)}
            if len(fingerprints) > 1:
                candidate = classify_delta(first, state, observed_at,
                                           ambiguous_reason='duplicate_observation',
                                           map_subjects=map_subjects)
                candidates.append(candidate)
                continue
        candidate = classify_delta(
            first, state, observed_at,
            observation_status='PARTIAL' if post_id in partial_ids else 'COMPLETE',
            ambiguous_reason=(
                'subject_mapping_conflict' if post_id in subject_ambiguous_ids else
                'unknown_provider_query_change' if post_id in ambiguous_ids else None),
            map_subjects=map_subjects)
        candidates.append(candidate)
    for post_id in sorted(set(source_missing_ids), key=lambda value: str(value)):
        candidates.append(source_missing_candidate(str(post_id), state, observed_at))
    for post_id in sorted(set(fetch_failed_ids), key=lambda value: str(value)):
        candidates.append(fetch_failed_candidate(str(post_id), state, observed_at))
    candidates.sort(key=lambda candidate: (
        candidate.source, _post_id_sort_key(candidate.external_post_id),
        candidate.classification))
    after = LocalDeltaState.from_dict(state.as_dict())
    for candidate in candidates:
        if candidate.classification in ('NEW', 'MODIFIED') and candidate._observed_entry:
            after.entries[candidate.external_post_id] = candidate._observed_entry
        elif candidate.classification == 'UNCHANGED' and candidate._accepted_entry:
            old = candidate._accepted_entry
            after.entries[candidate.external_post_id] = StateEntry(
                source=old.source,
                external_post_id=old.external_post_id,
                accepted_canonical_hash=old.accepted_canonical_hash,
                accepted_observation_fingerprint=old.accepted_observation_fingerprint,
                accepted_source_times=old.accepted_source_times,
                accepted_projection=old.accepted_projection,
                accepted_resource_descriptors=old.accepted_resource_descriptors,
                last_successful_observation_at=observed_at,
                last_observation_status='COMPLETE',
            )
    return DeltaRun(candidates, state, after, observed_at,
                    failed=sum(1 for candidate in candidates
                               if candidate.classification == 'FETCH_FAILED'))


def _atomic_write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f'.{path.name}.', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as handle:
            json.dump(payload, handle, ensure_ascii=False, sort_keys=True, indent=2)
            handle.write('\n')
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def write_delta_artifacts(result: DeltaRun, output_dir: Path,
                          state_path: Path | None = None) -> tuple[Path, Path, Path | None]:
    """Finalize both redacted artifacts, then atomically advance local state."""
    output_dir = Path(output_dir)
    parent = output_dir.parent
    parent.mkdir(parents=True, exist_ok=True)
    temp_dir = Path(tempfile.mkdtemp(prefix=f'.{output_dir.name}.', dir=str(parent)))
    try:
        summary_path = temp_dir / 'delta-run-summary.json'
        summary_path.write_text(_canonical_json(result.summary()) + '\n', encoding='utf-8')
        candidates_path = temp_dir / 'delta-candidates.jsonl'
        with candidates_path.open('w', encoding='utf-8') as handle:
            for candidate in result.candidates:
                handle.write(_canonical_json(candidate.as_dict()) + '\n')
            handle.flush()
            os.fsync(handle.fileno())
        backup_dir = None
        if output_dir.exists():
            backup_dir = Path(tempfile.mkdtemp(prefix=f'.{output_dir.name}.old.',
                                                dir=str(parent)))
            backup_dir.rmdir()
            os.replace(output_dir, backup_dir)
        try:
            os.replace(temp_dir, output_dir)
        except Exception:
            if backup_dir is not None and not output_dir.exists():
                os.replace(backup_dir, output_dir)
            raise
        if backup_dir is not None:
            if backup_dir.is_dir():
                shutil.rmtree(backup_dir)
            else:
                backup_dir.unlink()
    except Exception as exc:
        shutil.rmtree(temp_dir, ignore_errors=True)
        raise ArtifactWriteError(type(exc).__name__) from exc
    final_state = None
    if state_path is not None:
        final_state = Path(state_path)
        result.state_after.write(final_state)
    return (output_dir / 'delta-run-summary.json',
            output_dir / 'delta-candidates.jsonl', final_state)
