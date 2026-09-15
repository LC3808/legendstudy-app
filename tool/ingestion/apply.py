"""Pilot C production apply.

Day 9-B2 deliberately shipped no write path. This module adds one, behind the
gates that were already implemented and tested, and nothing here runs unless
the CLI is given `--apply --project-ref <LegendStudy> --i-have-owner-approval`.

Design decisions, taken against the applied schema rather than inherited:

* **One transaction for the whole pilot, not one per post.** The Day 9-B2
  package suggested per-post transactions. For a bounded 23-post run that is
  the weaker choice: a failure at post 15 would leave 14 posts committed, the
  Owner's expected-delta postflight would fail against a partial database, and
  rollback would have to discover which posts landed. 1,148 rows is trivial for
  a single transaction, so the pilot commits all-or-nothing and the row counts
  are verified *inside* the transaction before COMMIT. Per-post transactions
  remain the right shape for a long unattended crawl, which this is not.
* **Quarantine commits separately, after the canonical rows.** `ingestion.md`
  requires that a rollback of the normalized transaction cannot erase the
  evidence, so quarantine is never part of the same transaction.
* **Deterministic ids.** Every row id is uuid5 over its canonical identity, so
  a re-run produces the same ids, `ON CONFLICT DO NOTHING` degenerates to a
  no-op, quarantine cannot accumulate duplicates, and rollback can name an
  exact id set. This needs no schema change: all five ids are insertable.
* **INSERT-only, fail closed.** No UPDATE and no DELETE is issued. A row that
  already exists is never rewritten, so a manual correction, an activated row
  and a `verified` mapping are all structurally safe. A partially applied
  pilot stops the run instead of being "repaired" by an upsert.
"""
from __future__ import annotations

import json
import uuid
from dataclasses import dataclass, field
from typing import Protocol, Sequence

from .models import PlannedPost
from .subjects import TAXONOMY_VERSION

NAMESPACE = uuid.uuid5(uuid.NAMESPACE_URL, 'https://legendstudy.com/ingest')
SOURCE = 'legendstudy'
EXPECTED_SUBJECT_COUNT = 23


def row_id(*parts: str) -> str:
    return str(uuid.uuid5(NAMESPACE, '\x1f'.join(parts)))


class ApplyAborted(RuntimeError):
    """Raised before or during apply. The transaction is always rolled back."""


class DbSession(Protocol):
    """The minimum a database must offer. Tests supply an in-memory double."""

    def execute(self, statement: str, params: Sequence = ()) -> list[tuple]: ...
    def begin(self) -> None: ...
    def commit(self) -> None: ...
    def rollback(self) -> None: ...


# --- row projection -------------------------------------------------------
# Column lists mirror 20260912000100_initial_content_schema.sql exactly.
# Generated columns (exams.content_type, exams.sort_date,
# content_items.feed_updated_at) are never sent.

SOURCE_POST_COLUMNS = (
    'id', 'source', 'external_post_id', 'url', 'title', 'category',
    'source_published_at', 'source_updated_at', 'raw_excerpt', 'raw_metadata',
    'content_hash', 'parser_version', 'last_crawled_at', 'source_status',
)
CONTENT_ITEM_COLUMNS = (
    'id', 'source_post_id', 'source_content_key', 'slug', 'content_type', 'title',
    'summary', 'source_url', 'published_at', 'source_updated_at', 'thumbnail_url',
    'is_active',
)
EXAM_COLUMNS = (
    'content_item_id', 'year', 'academic_year', 'exam_month', 'exam_date',
    'grade_level', 'raw_grade_label', 'exam_type', 'raw_exam_type', 'exam_round',
    'curriculum_version', 'normalization_note',
)
EXAM_SUBJECT_COLUMNS = (
    'id', 'content_item_id', 'source_subject_key', 'subject_id', 'raw_subject_label',
    'taxonomy_version', 'mapping_status', 'mapping_confidence', 'mapping_note',
    'mapping_rule_version', 'verified_at', 'display_order', 'is_active',
)
RESOURCE_COLUMNS = (
    'id', 'content_item_id', 'exam_subject_id', 'source_post_id', 'source_resource_key',
    'resource_type', 'title', 'source_label', 'source_url', 'link_kind', 'file_url',
    'mime_type', 'file_extension', 'file_size', 'link_status', 'last_checked_at',
    'display_order', 'is_active',
)
QUARANTINE_COLUMNS = ('id', 'source_post_id', 'kind', 'payload', 'status', 'note')

SIGNING_TOKENS = ('credential=', 'signature=', 'expires=')
SIGNED_URL_PATTERNS = [f'%{token}%' for token in SIGNING_TOKENS]


@dataclass
class ResolvedPost:
    """One post's rows with every id resolved. Nothing is sent before this."""
    external_post_id: str
    source_post: dict
    content_item: dict
    exam: dict
    occurrences: list[dict] = field(default_factory=list)
    resources: list[dict] = field(default_factory=list)
    quarantine: list[dict] = field(default_factory=list)


def _pick(row: dict, columns: Sequence[str]) -> dict:
    """Keep only real columns. Plan rows carry extra planning-only keys."""
    return {name: row.get(name) for name in columns}


def resolve(plan: PlannedPost) -> ResolvedPost:
    """Attach deterministic ids and drop planning-only fields."""
    if plan.content_item is None or plan.exam is None:
        raise ApplyAborted(f'{plan.external_post_id}: incomplete plan')

    post_id = row_id('source_post', SOURCE, plan.external_post_id)
    content_id = row_id('content_item', plan.content_item['slug'])

    source_post = _pick({**plan.source_post, 'id': post_id}, SOURCE_POST_COLUMNS)
    source_post['raw_metadata'] = json.dumps(
        plan.source_post.get('raw_metadata') or {}, ensure_ascii=False, sort_keys=True)

    content_item = _pick({**plan.content_item, 'id': content_id,
                          'source_post_id': post_id}, CONTENT_ITEM_COLUMNS)
    exam = _pick({**plan.exam, 'content_item_id': content_id}, EXAM_COLUMNS)

    occurrences, by_subject_key = [], {}
    for occurrence in plan.occurrences:
        occurrence_id = row_id('exam_subject', content_id, occurrence['source_subject_key'])
        by_subject_key[occurrence['source_subject_key']] = occurrence_id
        occurrences.append(_pick({**occurrence, 'id': occurrence_id,
                                  'content_item_id': content_id}, EXAM_SUBJECT_COLUMNS))

    resources = []
    for resource in plan.resources:
        resource_id = row_id('resource', content_id, post_id,
                             resource['source_resource_key'])
        scoped = by_subject_key.get(resource.get('occurrence_subject_key'))
        resources.append(_pick({**resource, 'id': resource_id,
                                'content_item_id': content_id,
                                'source_post_id': post_id,
                                'exam_subject_id': scoped}, RESOURCE_COLUMNS))

    quarantine = []
    for case in plan.quarantine:
        quarantine.append({
            'id': row_id('quarantine', case.kind, plan.external_post_id),
            'source_post_id': post_id,
            'kind': case.kind,
            'payload': json.dumps(case.payload or {}, ensure_ascii=False, sort_keys=True),
            'status': 'open',
            'note': case.note,
        })

    return ResolvedPost(plan.external_post_id, source_post, content_item, exam,
                        occurrences, resources, quarantine)


def assert_no_signing_material(posts: list[ResolvedPost]) -> None:
    """A stored locator must never carry the site's rolling credential."""
    for post in posts:
        for resource in post.resources:
            for field_name in ('source_url', 'file_url'):
                value = resource.get(field_name) or ''
                for token in SIGNING_TOKENS:
                    if token in value:
                        raise ApplyAborted(
                            f'{post.external_post_id}: {field_name} carries {token!r}')


def assert_write_shape(posts: list[ResolvedPost]) -> None:
    """Last barrier before SQL: publication and mapping invariants."""
    for post in posts:
        if post.content_item['is_active']:
            raise ApplyAborted(f'{post.external_post_id}: content_item is_active must be false')
        for occurrence in post.occurrences:
            if occurrence['mapping_status'] == 'verified':
                raise ApplyAborted(
                    f'{post.external_post_id}: ingestion must not write a verified mapping')
            if occurrence['is_active']:
                raise ApplyAborted(f'{post.external_post_id}: exam_subject is_active must be false')
            if occurrence['mapping_status'] == 'provisional':
                if not occurrence['subject_id'] or occurrence['taxonomy_version'] != TAXONOMY_VERSION:
                    raise ApplyAborted(
                        f'{post.external_post_id}: provisional mapping needs a v1 subject pair')
                if occurrence['mapping_confidence'] is None:
                    raise ApplyAborted(
                        f'{post.external_post_id}: provisional mapping needs a confidence')
            if occurrence['verified_at'] is not None:
                raise ApplyAborted(f'{post.external_post_id}: verified_at must be null')
        for resource in post.resources:
            if resource['is_active']:
                raise ApplyAborted(f'{post.external_post_id}: resource is_active must be false')
            if resource['link_status'] != 'unchecked' or resource['file_url'] is not None:
                raise ApplyAborted(
                    f'{post.external_post_id}: ingestion may not claim a verified file')


# --- SQL ------------------------------------------------------------------

def _insert(table: str, columns: Sequence[str]) -> str:
    placeholders = ', '.join(['%s'] * len(columns))
    return (f'insert into public.{table} ({", ".join(columns)}) '
            f'values ({placeholders}) on conflict do nothing returning 1')


INSERTS = {
    'source_posts': _insert('source_posts', SOURCE_POST_COLUMNS),
    'content_items': _insert('content_items', CONTENT_ITEM_COLUMNS),
    'exams': _insert('exams', EXAM_COLUMNS),
    'exam_subjects': _insert('exam_subjects', EXAM_SUBJECT_COLUMNS),
    'resources': _insert('resources', RESOURCE_COLUMNS),
    'ingestion_quarantine': _insert('ingestion_quarantine', QUARANTINE_COLUMNS),
}
# FK order: source_posts -> content_items -> exams -> exam_subjects -> resources.
# resources reference both content_items and exam_subjects, so they are last.
WRITE_ORDER = ('source_posts', 'content_items', 'exams', 'exam_subjects', 'resources')


@dataclass
class Preflight:
    subjects_v1: int
    existing_posts: int
    existing_slugs: int
    verified_occurrences: int
    missing_subject_ids: list[str]
    already_applied: bool


def preflight(session: DbSession, posts: list[ResolvedPost],
              blocking_quarantine: int) -> Preflight:
    """Read-only checks against the live database. Raises rather than guessing."""
    if blocking_quarantine:
        raise ApplyAborted(
            f'refusing: {blocking_quarantine} post(s) carry a blocking quarantine case')

    subjects_v1 = session.execute(
        'select count(*) from public.subjects where taxonomy_version = %s',
        (TAXONOMY_VERSION,))[0][0]
    if subjects_v1 != EXPECTED_SUBJECT_COUNT:
        raise ApplyAborted(
            f'refusing: subjects taxonomy {TAXONOMY_VERSION} has {subjects_v1} rows, '
            f'expected {EXPECTED_SUBJECT_COUNT}. Apply supabase/seed/'
            f'subjects_taxonomy_v1.sql first.')

    referenced = sorted({o['subject_id'] for p in posts for o in p.occurrences
                         if o['subject_id']})
    missing: list[str] = []
    if referenced:
        found = {row[0] for row in session.execute(
            'select id::text from public.subjects '
            'where taxonomy_version = %s and id::text = any(%s)',
            (TAXONOMY_VERSION, referenced))}
        missing = [value for value in referenced if value not in found]
    if missing:
        raise ApplyAborted(
            f'refusing: {len(missing)} mapped subject id(s) are absent from the '
            f'{TAXONOMY_VERSION} taxonomy')

    external_ids = [p.external_post_id for p in posts]
    slugs = [p.content_item['slug'] for p in posts]
    existing_posts = session.execute(
        'select count(*) from public.source_posts '
        'where source = %s and external_post_id = any(%s)', (SOURCE, external_ids))[0][0]
    existing_slugs = session.execute(
        'select count(*) from public.content_items where slug = any(%s)', (slugs,))[0][0]

    content_ids = [p.content_item['id'] for p in posts]
    verified = session.execute(
        'select count(*) from public.exam_subjects '
        'where mapping_status = %s and content_item_id::text = any(%s)',
        ('verified', content_ids))[0][0]
    if verified:
        raise ApplyAborted(
            f'refusing: {verified} verified mapping(s) already exist for these content '
            f'items; automated ingestion must never disturb a verified row')

    total = len(posts)
    if existing_posts == 0 and existing_slugs == 0:
        already = False
    elif existing_posts == total and existing_slugs == total:
        already = True
    else:
        raise ApplyAborted(
            f'refusing: partial pilot state — {existing_posts}/{total} source posts and '
            f'{existing_slugs}/{total} slugs already exist. Resolve by hand; this writer '
            f'will not repair a partial apply.')

    return Preflight(subjects_v1, existing_posts, existing_slugs, verified, missing, already)


def _rows_for(table: str, posts: list[ResolvedPost]) -> list[dict]:
    if table == 'source_posts':
        return [p.source_post for p in posts]
    if table == 'content_items':
        return [p.content_item for p in posts]
    if table == 'exams':
        return [p.exam for p in posts]
    if table == 'exam_subjects':
        return [o for p in posts for o in p.occurrences]
    if table == 'resources':
        return [r for p in posts for r in p.resources]
    raise ApplyAborted(f'unknown table {table!r}')


COLUMNS = {
    'source_posts': SOURCE_POST_COLUMNS,
    'content_items': CONTENT_ITEM_COLUMNS,
    'exams': EXAM_COLUMNS,
    'exam_subjects': EXAM_SUBJECT_COLUMNS,
    'resources': RESOURCE_COLUMNS,
    'ingestion_quarantine': QUARANTINE_COLUMNS,
}


def apply_pilot(session: DbSession, posts: list[ResolvedPost],
                expected: dict, on_progress=None) -> dict:
    """Insert the whole pilot in one transaction. Commits only if counts match."""
    assert_write_shape(posts)
    assert_no_signing_material(posts)

    inserted: dict[str, int] = {}
    session.begin()
    try:
        for table in WRITE_ORDER:
            rows = _rows_for(table, posts)
            statement, columns = INSERTS[table], COLUMNS[table]
            count = 0
            for row in rows:
                count += len(session.execute(
                    statement, tuple(row[name] for name in columns)))
            inserted[table] = count
            if on_progress:
                on_progress(table, count, len(rows))
        for table, want in expected.items():
            if table in inserted and inserted[table] != want:
                raise ApplyAborted(
                    f'refusing to commit: {table} inserted {inserted[table]} rows, '
                    f'expected {want}')
        session.commit()
    except Exception:
        session.rollback()
        raise
    return inserted


def apply_quarantine(session: DbSession, posts: list[ResolvedPost]) -> int:
    """Separate transaction, so a rollback of the pilot cannot erase evidence.

    Ids are deterministic, so a re-run conflicts on the primary key and inserts
    nothing rather than accumulating duplicate advisory rows.
    """
    rows = [case for post in posts for case in post.quarantine]
    statement, columns = INSERTS['ingestion_quarantine'], QUARANTINE_COLUMNS
    session.begin()
    try:
        count = 0
        for row in rows:
            count += len(session.execute(
                statement, tuple(row[name] for name in columns)))
        session.commit()
    except Exception:
        session.rollback()
        raise
    return count


def postflight(session: DbSession) -> dict:
    """Read-back the Owner verifies against the expected delta."""
    counts = {}
    for table in ('source_posts', 'content_items', 'exams', 'subjects',
                  'exam_subjects', 'resources', 'ingestion_quarantine'):
        counts[table] = session.execute(f'select count(*) from public.{table}')[0][0]
    counts['active_content_items'] = session.execute(
        'select count(*) from public.content_items where is_active')[0][0]
    counts['active_exam_subjects'] = session.execute(
        'select count(*) from public.exam_subjects where is_active')[0][0]
    counts['active_resources'] = session.execute(
        'select count(*) from public.resources where is_active')[0][0]
    counts['verified_exam_subjects'] = session.execute(
        "select count(*) from public.exam_subjects where mapping_status = 'verified'")[0][0]
    # The LIKE patterns are parameters, not literals. psycopg scans a statement
    # for placeholders whenever parameters are passed, so a literal '%credential='
    # inside the SQL was read as the placeholder '%c' and raised ProgrammingError.
    counts['signed_resource_urls'] = session.execute(
        'select count(*) from public.resources where source_url ilike any(%s)',
        (SIGNED_URL_PATTERNS,))[0][0]
    return counts


class PsycopgSession:
    """Thin adapter. psycopg is imported lazily so offline tests never need it."""

    def __init__(self, connection) -> None:
        self.connection = connection

    @classmethod
    def connect(cls, settings: dict) -> 'PsycopgSession':
        import psycopg  # noqa: PLC0415 - optional dependency, apply path only
        return cls(psycopg.connect(**settings))

    def execute(self, statement: str, params: Sequence = ()) -> list[tuple]:
        with self.connection.cursor() as cursor:
            # psycopg only parses placeholders when parameters are supplied.
            # Passing None for a parameterless statement keeps any literal '%'
            # in the SQL from being read as a placeholder.
            cursor.execute(statement, tuple(params) if params else None)
            if cursor.description is None:
                return []
            return list(cursor.fetchall())

    def begin(self) -> None:
        self.connection.rollback()

    def commit(self) -> None:
        self.connection.commit()

    def rollback(self) -> None:
        self.connection.rollback()

    def close(self) -> None:
        self.connection.close()
