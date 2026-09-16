"""Fail-closed Pilot C publication package.

This tool is deliberately separate from ingestion.  The default command is a
read-only preflight.  Publication requires the exact LegendStudy project ref,
an explicit owner approval flag, and a live connection; no credentials are
read from stdout, files, or command arguments.

The only production mutation is ``is_active: false -> true`` for the exact
Pilot C rows, in one transaction.  The tool never inserts, deletes, changes
content, or repairs a partial state.
"""
from __future__ import annotations

import argparse
import getpass
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

PROJECT_REF = "stlhijzpjfgwwdgunlsd"
SOURCE = "legendstudy"
PILOT_POST_IDS = (
    "1709", "1708", "1707", "1706", "1705", "1704", "1703", "1702",
    "1700", "1695", "1694", "1693", "1686", "1685", "1684", "1668",
    "1667", "1666", "1665", "1664", "1663", "1662", "1661",
)
EXPECTED = {
    "subjects": 23, "source_posts": 23, "content_items": 23, "exams": 23,
    "exam_subjects": 363, "resources": 739, "ingestion_quarantine": 23,
}
EXPECTED_ACTIVE = {"content_items": 23, "exam_subjects": 363, "resources": 739}
RESOURCE_BREAKDOWN = {"question": 360, "answer_explanation": 356,
                      "listening_audio": 23}


class PublicationRefused(RuntimeError):
    """A fail-closed package gate rejected the current state."""


@dataclass(frozen=True)
class ScopeCounts:
    source_posts: int
    content_items: int
    exams: int
    exam_subjects: int
    resources: int


def assert_project(project_ref: str | None) -> None:
    if project_ref != PROJECT_REF:
        raise PublicationRefused(f"wrong project ref: {project_ref!r}")


def assert_publish_allowed(project_ref: str | None, approved: bool) -> None:
    assert_project(project_ref)
    if not approved:
        raise PublicationRefused("--publish requires --i-have-owner-approval")


def active_mode(active: dict[str, int]) -> str:
    """Return publish/no-op, rejecting every partial or foreign state."""
    if all(active.get(k) == 0 for k in EXPECTED_ACTIVE):
        return "publish"
    if all(active.get(k) == v for k, v in EXPECTED_ACTIVE.items()):
        return "already_published"
    raise PublicationRefused(
        "partial/foreign active state; expected all 0 or exactly 23/363/739")


def validate_preflight(snapshot: dict[str, Any], scope: ScopeCounts) -> None:
    """Validate a normalized read-only snapshot before any UPDATE is issued."""
    for table, want in EXPECTED.items():
        if snapshot.get(table) != want:
            raise PublicationRefused(f"{table} count {snapshot.get(table)!r}, expected {want}")
    if snapshot.get("active_subjects") != 23:
        raise PublicationRefused("active subjects must be exactly 23")
    if scope != ScopeCounts(23, 23, 23, 363, 739):
        raise PublicationRefused(f"Pilot C scope mismatch: {scope}")
    if snapshot.get("provisional") != 363 or snapshot.get("verified") != 0:
        raise PublicationRefused("mapping state is not 363 provisional / 0 verified")
    if snapshot.get("signed_urls") != 0:
        raise PublicationRefused("signed URL material exists")
    if snapshot.get("duplicates") != 0 or snapshot.get("orphans") != 0:
        raise PublicationRefused("duplicates or orphans exist")
    if snapshot.get("blocking_quarantine") != 0:
        raise PublicationRefused("blocking quarantine exists")
    if snapshot.get("resource_breakdown") != RESOURCE_BREAKDOWN:
        raise PublicationRefused("resource breakdown mismatch")
    active_mode({k: snapshot.get(f"active_{k}") for k in EXPECTED_ACTIVE})


SCOPE_CTE = """WITH pilot_posts AS (
    SELECT id FROM public.source_posts
    WHERE source = 'legendstudy' AND external_post_id = ANY(%s)
), pilot_content AS (
    SELECT c.id FROM public.content_items c
    JOIN pilot_posts p ON p.id = c.source_post_id
), pilot_occurrences AS (
    SELECT es.id, es.content_item_id FROM public.exam_subjects es
    JOIN pilot_content c ON c.id = es.content_item_id
), pilot_resources AS (
    SELECT r.id, r.content_item_id FROM public.resources r
    JOIN pilot_content c ON c.id = r.content_item_id
    JOIN pilot_posts p ON p.id = r.source_post_id
)
"""

SCOPE_QUERY = SCOPE_CTE + """SELECT
    (SELECT count(*) FROM pilot_posts),
    (SELECT count(*) FROM pilot_content),
    (SELECT count(*) FROM pilot_content c
       JOIN public.exams e ON e.content_item_id = c.id),
    (SELECT count(*) FROM pilot_occurrences),
    (SELECT count(*) FROM pilot_resources)
"""

# These statements intentionally contain no SET of any column other than
# is_active.  The chain is re-resolved in every statement from the fixed post
# set; no broad slug, year, or table-wide UPDATE is possible.
ACTIVATE_CONTENT = SCOPE_CTE + """UPDATE public.content_items c
SET is_active = true
FROM pilot_content target
WHERE c.id = target.id AND c.is_active = false
RETURNING c.id
"""
ACTIVATE_OCCURRENCES = SCOPE_CTE + """UPDATE public.exam_subjects es
SET is_active = true
FROM pilot_occurrences target
JOIN public.content_items c ON c.id = target.content_item_id
WHERE es.id = target.id AND es.content_item_id = target.content_item_id
  AND c.is_active AND es.is_active = false
RETURNING es.id
"""
ACTIVATE_RESOURCES = SCOPE_CTE + """UPDATE public.resources r
SET is_active = true
FROM pilot_resources target
JOIN public.content_items c ON c.id = target.content_item_id
WHERE r.id = target.id AND r.content_item_id = target.content_item_id
  AND c.is_active AND (r.exam_subject_id IS NULL OR EXISTS (
      SELECT 1 FROM public.exam_subjects es
      WHERE es.id = r.exam_subject_id AND es.content_item_id = r.content_item_id
        AND es.is_active
  )) AND r.is_active = false
RETURNING r.id
"""

ROLLBACK_CONTENT = SCOPE_CTE + """UPDATE public.content_items c SET is_active = false
FROM pilot_content target WHERE c.id = target.id AND c.is_active RETURNING c.id"""
ROLLBACK_OCCURRENCES = SCOPE_CTE + """UPDATE public.exam_subjects es SET is_active = false
FROM pilot_occurrences target WHERE es.id = target.id
  AND es.content_item_id = target.content_item_id AND es.is_active RETURNING es.id"""
ROLLBACK_RESOURCES = SCOPE_CTE + """UPDATE public.resources r SET is_active = false
FROM pilot_resources target WHERE r.id = target.id
  AND r.content_item_id = target.content_item_id AND r.is_active RETURNING r.id"""


def _scope_params() -> tuple[list[str]]:
    return (list(PILOT_POST_IDS),)


def _count(session, sql: str, params: Sequence = ()) -> int:
    return int(session.execute(sql, params)[0][0])


def read_snapshot(session) -> tuple[dict[str, Any], ScopeCounts]:
    """Read all fail-closed gates; this function never mutates the database."""
    snapshot: dict[str, Any] = {}
    for table in EXPECTED:
        snapshot[table] = _count(session, f"select count(*) from public.{table}")
    snapshot["active_subjects"] = _count(
        session, "select count(*) from public.subjects where is_active")
    for table in EXPECTED_ACTIVE:
        snapshot[f"active_{table}"] = _count(
            session, f"select count(*) from public.{table} where is_active")
    snapshot["provisional"] = _count(
        session, "select count(*) from public.exam_subjects where mapping_status = 'provisional'")
    snapshot["verified"] = _count(
        session, "select count(*) from public.exam_subjects where mapping_status = 'verified'")
    snapshot["signed_urls"] = _count(session, """select count(*) from public.resources
        where source_url ilike any(%s) or file_url ilike any(%s)""",
        (["%credential=%", "%signature=%", "%expires=%"],) * 2)
    snapshot["duplicates"] = _count(session, """select count(*) from (
        select source, external_post_id from public.source_posts group by 1,2 having count(*) > 1
        union all select content_item_id::text, source_subject_key from public.exam_subjects
          group by 1,2 having count(*) > 1
        union all select content_item_id::text, source_resource_key from public.resources
          group by 1,2 having count(*) > 1) d""")
    snapshot["orphans"] = _count(session, """select count(*) from public.resources r
        where not exists (select 1 from public.content_items c where c.id=r.content_item_id)
        or (r.exam_subject_id is not null and not exists (
          select 1 from public.exam_subjects es where es.id=r.exam_subject_id
            and es.content_item_id=r.content_item_id))""")
    snapshot["blocking_quarantine"] = _count(session, """select count(*)
        from public.ingestion_quarantine where status = 'open'
        and kind in ('classification_missing_category','classification_unknown_category',
          'exam_year_unknown','exam_month_unknown','exam_grade_unknown','exam_type_unknown',
          'exam_academic_year_conflict','resource_identity_missing',
          'resource_identity_duplicate','source_missing')""")
    rows = session.execute("""select resource_type, count(*) from public.resources
        group by resource_type order by resource_type""")
    snapshot["resource_breakdown"] = {row[0]: int(row[1]) for row in rows}
    scope = ScopeCounts(*map(int, session.execute(SCOPE_QUERY, _scope_params())[0]))
    return snapshot, scope


def activate(session, statement: str, expected: int) -> int:
    ids = session.execute(statement, _scope_params())
    if len(ids) != expected:
        raise PublicationRefused(f"affected rows {len(ids)}, expected {expected}; transaction aborts")
    return len(ids)


def publish(session) -> str:
    """Run preflight, exact activation, and postflight in one transaction."""
    session.begin()
    try:
        snapshot, scope = read_snapshot(session)
        validate_preflight(snapshot, scope)
        mode = active_mode({k: snapshot[f"active_{k}"] for k in EXPECTED_ACTIVE})
        if mode == "already_published":
            session.rollback()
            return mode
        activate(session, ACTIVATE_CONTENT, 23)
        activate(session, ACTIVATE_OCCURRENCES, 363)
        activate(session, ACTIVATE_RESOURCES, 739)
        after, after_scope = read_snapshot(session)
        if after_scope != scope:
            raise PublicationRefused("scope changed during transaction")
        if any(after[f"active_{k}"] != v for k, v in EXPECTED_ACTIVE.items()):
            raise PublicationRefused("postflight active counts mismatch; transaction aborts")
        session.commit()
        return "published"
    except Exception:
        session.rollback()
        raise


def rollback_sql() -> tuple[str, str, str]:
    """Return guarded soft-rollback statements; never deletes rows."""
    return ROLLBACK_RESOURCES, ROLLBACK_OCCURRENCES, ROLLBACK_CONTENT


def anon_acceptance_sql() -> str:
    """Read-only role acceptance, including explicit public projections."""
    return """begin;
set local role anon;
select 'content_items' as object, count(*) from public.content_items
union all select 'exams', count(*) from public.exams
union all select 'exam_subjects', count(*) from public.exam_subjects
union all select 'resources', count(*) from public.resources
union all select 'subjects', count(*) from public.subjects;
select c.id, c.slug, c.content_type, c.title, e.year, e.grade_level,
       es.id as exam_subject_id, s.code as subject_code,
       r.resource_type, r.title as resource_title, r.link_kind, r.source_url, r.file_url
from public.content_items c
join public.exams e on e.content_item_id = c.id
join public.exam_subjects es on es.content_item_id = c.id
join public.subjects s on s.id = es.subject_id and s.taxonomy_version = es.taxonomy_version
left join public.resources r on r.content_item_id = c.id and r.exam_subject_id = es.id
where c.is_active and es.is_active and (r.id is null or r.is_active)
order by e.sort_date desc nulls last, c.id desc, es.display_order, r.display_order;
select count(*) from public.source_posts;
select count(*) from public.ingestion_quarantine;
rollback;"""


def validated_host(host: str) -> str:
    direct = f"db.{PROJECT_REF}.supabase.co"
    if host == direct or re.fullmatch(r"aws-[0-9]+-[a-z0-9-]+\.pooler\.supabase\.com", host or ""):
        return host
    raise PublicationRefused("database host is not an allowed LegendStudy/Supabase pooler host")


def connect(args):
    try:
        import psycopg
    except ImportError as exc:
        raise PublicationRefused("psycopg is required; use the existing verifier venv") from exc
    host = args.db_host
    if not host and args.config.exists():
        try:
            host = json.loads(args.config.read_text(encoding="utf-8")).get("SUPABASE_SESSION_POOLER_HOST")
        except (OSError, ValueError):
            host = None
    host = validated_host(host or input("Supabase session pooler host (blank = direct DB) > ").strip()
                          or f"db.{PROJECT_REF}.supabase.co")
    password = getpass.getpass("LegendStudy DB password > ")
    if not password:
        raise PublicationRefused("empty database password")
    return psycopg.connect(host=host, port=5432, dbname="postgres",
                           user="postgres" if host.startswith("db.") else f"postgres.{PROJECT_REF}",
                           password=password, sslmode="require", connect_timeout=15,
                           application_name="legendstudy_pilot_c_publication",
                           options="-c statement_timeout=120000 -c lock_timeout=10000")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-ref", required=True)
    parser.add_argument("--publish", action="store_true")
    parser.add_argument("--i-have-owner-approval", action="store_true")
    parser.add_argument("--db-host")
    parser.add_argument("--config", type=Path, default=Path("config/development.json"))
    args = parser.parse_args(argv)
    try:
        if args.publish:
            assert_publish_allowed(args.project_ref, args.i_have_owner_approval)
        else:
            assert_project(args.project_ref)
        connection = connect(args)
        class Session:
            def execute(self, statement, params=()):
                with connection.cursor() as cursor:
                    cursor.execute(statement, tuple(params) if params else None)
                    return [] if cursor.description is None else list(cursor.fetchall())
            def begin(self): connection.rollback()
            def commit(self): connection.commit()
            def rollback(self): connection.rollback()
        session = Session()
        if args.publish:
            print(f"publication: {publish(session)}")
        else:
            snapshot, scope = read_snapshot(session)
            validate_preflight(snapshot, scope)
            print("preflight: PASS (read-only; publication not executed)")
        connection.close()
        return 0
    except PublicationRefused as exc:
        print(f"publication: REFUSED: {exc}")
        return 3
    except Exception as exc:
        print(f"publication: ABORTED ({type(exc).__name__}): {exc}")
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
