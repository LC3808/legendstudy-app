#!/usr/bin/env python3
"""legendstudy.com ingestion CLI. Dry-run by default; never writes to Supabase.

    python3 tool/ingest_legendstudy.py                      # offline dry-run
    python3 tool/ingest_legendstudy.py --source network     # live dry-run
    python3 tool/ingest_legendstudy.py --network-smoke 3    # structure check

`--apply` writes the approved Pilot C to production and is refused unless the
project ref matches LegendStudy exactly, Owner approval is given and the plan
came from a live dry-run. The DB password is hidden terminal input and is never
written to the repository, the wiki, an artifact or stdout. No credential,
cookie or signed query is written to any artifact.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion import PARSER_VERSION  # noqa: E402
from ingestion.crawler import (  # noqa: E402
    DEFAULT_DELAY_SECONDS, DEFAULT_MAX_RETRIES, DEFAULT_TIMEOUT_SECONDS,
    FetchError, NetworkSource, PoliteFetcher, SampleSource,
)
from ingestion.pipeline import DryRunResult, load_state, next_state, run  # noqa: E402
from ingestion.normalizer import BLOCKING, is_advisory  # noqa: E402
from ingestion.apply import (  # noqa: E402
    ApplyAborted, PsycopgSession, apply_pilot, apply_quarantine, postflight,
    preflight, resolve,
)
from ingestion.writer import (  # noqa: E402
    LEGENDSTUDY_PROJECT_REF, PILOT_C, ApplyRefused, ScopeViolation,
    approved_scope, assert_apply_allowed, assert_in_scope, assert_no_collisions,
    expected_rows, plan_statements,
)

REPO = Path(__file__).resolve().parent.parent
DEFAULT_SAMPLES = (REPO / 'tool/ingestion/samples/day9b_exam_posts.jsonl',)
PILOT_C_POST_IDS = (
    1709, 1708, 1707, 1706, 1705, 1704, 1703, 1702, 1700, 1695, 1694, 1693,
    1686, 1685, 1684, 1668, 1667, 1666, 1665, 1664, 1663, 1662, 1661,
)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def _report_retry(request_label: str, attempt: int, reason: str) -> None:
    target = (f'post={request_label}' if request_label.isdigit()
              else f'target={request_label}')
    detail = (f'status={reason.removeprefix("HTTP ")}'
              if reason.startswith('HTTP ') else f'kind={reason}')
    print(f'INGEST retry {target} attempt={attempt} {detail}', flush=True)


def _network_post_ids(ids: list[int], pilot: str | None,
                      limit: int | None,
                      post_ids: list[int] | None = None) -> list[int]:
    if post_ids:
        # Explicit operator-approved controlled apply set (A3-1). Every approved
        # id must exist on the sitemap; nothing else is fetched.
        available = set(ids)
        missing = [post_id for post_id in post_ids if post_id not in available]
        if missing:
            raise ValueError(f'approved set is missing {len(missing)} sitemap posts')
        selected = list(post_ids)
    elif pilot == 'c':
        available = set(ids)
        missing = [post_id for post_id in PILOT_C_POST_IDS if post_id not in available]
        if missing:
            raise ValueError(f'pilot c sitemap is missing {len(missing)} approved posts')
        selected = list(PILOT_C_POST_IDS)
    else:
        selected = ids
    return selected[:limit] if limit is not None else selected


def _fetch_network_posts(source: NetworkSource, ids: list[int]) -> tuple[list, int]:
    posts = []
    failures = 0
    total = len(ids)
    for index, post_id in enumerate(ids, start=1):
        started = time.monotonic()
        print(f'INGEST fetch {index}/{total} post={post_id}', flush=True)
        try:
            post = source.post(post_id)
        except FetchError as exc:
            failures += 1
            print(f'INGEST error {index}/{total} post={post_id} '
                  f'kind={exc.reason.replace(" ", "_")} '
                  f'transient={str(exc.transient).lower()} '
                  f'elapsed={time.monotonic() - started:.1f}s', flush=True)
            continue
        posts.append(post)
        print(f'INGEST done {index}/{total} post={post_id} '
              f'elapsed={time.monotonic() - started:.1f}s '
              f'attachments={len(post.attachments)}', flush=True)
    return posts, failures


def write_artifacts(result: DryRunResult, out: Path, crawled_at: str) -> list[Path]:
    out.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    summary = {
        'generated_at': crawled_at,
        'parser_version': PARSER_VERSION,
        'counts': result.counts(),
        'merge_candidates': result.merge_candidates,
        'parse_errors': result.parse_errors,
    }
    path = out / 'dryrun-summary.json'
    path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    written.append(path)

    path = out / 'dryrun-posts.csv'
    with path.open('w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh, lineterminator='\n')
        w.writerow(['external_post_id', 'source_url', 'raw_title', 'content_type', 'slug',
                    'calendar_year', 'academic_year', 'exam_month', 'grade_level',
                    'exam_type', 'subjects', 'subject_codes', 'mapping_status',
                    'resource_kinds', 'resource_count',
                    'confidence', 'publish_candidate', 'quarantine_kinds'])
        for p in result.plans:
            ci, ex = p.content_item, p.exam
            kinds = sorted({r['resource_type'] for r in p.resources})
            w.writerow([
                p.external_post_id, p.source_post['url'], p.source_post['title'],
                (ci or {}).get('content_type', ''), (ci or {}).get('slug', ''),
                (ex or {}).get('year', ''), (ex or {}).get('academic_year', ''),
                (ex or {}).get('exam_month', ''), (ex or {}).get('grade_level', ''),
                (ex or {}).get('exam_type', ''),
                '|'.join(o['source_subject_key'] for o in p.occurrences),
                '|'.join(o.get('subject_code') or '-' for o in p.occurrences),
                '|'.join(sorted({o['mapping_status'] for o in p.occurrences})) or '-',
                '|'.join(kinds), len(p.resources), p.confidence,
                'yes' if p.publishable else 'no',
                '|'.join(sorted({c.kind for c in p.quarantine})),
            ])
    written.append(path)

    path = out / 'dryrun-quarantine.csv'
    with path.open('w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh, lineterminator='\n')
        w.writerow(['kind', 'blocking', 'external_post_id', 'note', 'payload'])
        for c in result.quarantine:
            w.writerow([c.kind, 'yes' if c.kind in BLOCKING else 'no',
                        c.external_post_id or '', c.note,
                        json.dumps(c.payload, ensure_ascii=False)])
    written.append(path)

    path = out / 'dryrun-owner-sample.md'
    rows = sorted(result.plans, key=lambda p: -int(p.external_post_id))[:20]
    lines = ['# Day 9-B dry-run — Owner review sample',
             '',
             f'Generated {crawled_at} from {len(result.plans)} parsed posts. '
             'Metadata only; no article text and no attachment bytes.',
             '',
             '| post | 원본 제목 | 학년 | 연도 | 월 | 시험 | 과목 수 | 첨부 | 첨부 종류 | confidence | 검토 |',
             '|---|---|---|---|---|---|---|---|---|---|---|']
    for p in rows:
        ex = p.exam or {}
        kinds = sorted({r['resource_type'] for r in p.resources})
        flags = sorted({c.kind for c in p.quarantine if not is_advisory(c.kind, (p.content_item or {}).get('content_type'))})
        title = p.source_post['title'].replace('|', '/')[:46]
        lines.append(
            f"| [{p.external_post_id}]({p.source_post['url']}) | {title} | "
            f"{ex.get('grade_level', '-')} | {ex.get('year', '-')} | "
            f"{ex.get('exam_month', '-')} | {ex.get('exam_type', '-')} | "
            f"{len(p.occurrences)} | {len(p.resources)} | {', '.join(kinds)} | "
            f"{p.confidence} | {', '.join(flags) or '-'} |")
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    written.append(path)

    path = out / 'dryrun-plan-sample.txt'
    lines: list[str] = []
    for p in result.plans[:3]:
        lines.append(f'--- post {p.external_post_id} ({p.confidence}) ---')
        lines.extend(plan_statements(p)[:14])
        lines.append('')
    path.write_text('\n'.join(lines), encoding='utf-8')
    written.append(path)
    return written


def validated_db_host(host: str) -> str:
    """Only this project's direct host or a Supabase session pooler is accepted."""
    import re
    direct = f'db.{LEGENDSTUDY_PROJECT_REF}.supabase.co'
    pooler = re.fullmatch(r'aws-[0-9]+-[a-z0-9-]+\.pooler\.supabase\.com', host or '')
    if host != direct and pooler is None:
        raise SystemExit(f'refusing: {host!r} is not this project\'s database host')
    return host


def db_settings(args) -> dict:
    """Project-pinned connection. The password is hidden terminal input only.

    Nothing here is written to the repository, the wiki, stdout or an artifact,
    and no caller-supplied libpq options are accepted.
    """
    import getpass

    host = args.db_host
    if not host and args.config and Path(args.config).exists():
        try:
            host = json.loads(Path(args.config).read_text(encoding='utf-8')).get(
                'SUPABASE_SESSION_POOLER_HOST')
        except (OSError, ValueError):
            host = None
    if not host:
        host = input('Supabase session pooler host (blank = direct DB) > ').strip()
    direct = f'db.{LEGENDSTUDY_PROJECT_REF}.supabase.co'
    host = validated_db_host(host or direct)
    password = getpass.getpass('LegendStudy DB password > ')
    if not password:
        raise SystemExit('refusing: empty database password')
    return dict(
        host=host, port=5432, dbname='postgres',
        user='postgres' if host == direct else f'postgres.{LEGENDSTUDY_PROJECT_REF}',
        password=password, sslmode='require', connect_timeout=15,
        application_name='legendstudy_pilot_c_apply',
        options='-c statement_timeout=120000 -c lock_timeout=10000',
    )


def _open_session(args):
    try:
        return PsycopgSession.connect(db_settings(args))
    except ImportError:
        raise SystemExit(
            'psycopg is required for this command: '
            'python3 -m pip install -r tool/requirements-scoring-verifier.txt')


def cmd_apply(args, result) -> int:
    """Controlled production apply. Every gate must pass before a row is sent.

    Two operator paths share this same writer/apply core and safety gates:
    ``--pilot c`` (the fixed Pilot C scope) and ``--post-ids`` (an explicit
    Owner-approved id set, A3-1). Neither is allowed to write outside its scope.
    """
    try:
        assert_apply_allowed(args.project_ref, args.i_have_owner_approval,
                             live_source=(args.source == 'network'))
    except ApplyRefused as exc:
        print(f'APPLY {exc}', flush=True)
        return 3
    if args.post_ids:
        approved = [int(x) for x in args.post_ids.split(',') if x.strip()]
        scope = approved_scope(approved)
    elif args.pilot == 'c':
        scope = PILOT_C
    else:
        print('APPLY refusing: --apply needs --pilot c or an explicit --post-ids set',
              flush=True)
        return 3

    try:
        assert_in_scope(result.plans, scope)
        assert_no_collisions(result.plans)
    except ScopeViolation as exc:
        print(f'APPLY refusing: {exc}', flush=True)
        return 3

    expected = expected_rows(result.plans)
    blocking = len({c.external_post_id for c in result.quarantine if c.kind in BLOCKING})
    posts = [resolve(plan) for plan in result.plans]

    print('\nAPPLY plan:', json.dumps(expected), flush=True)
    print(f'APPLY quarantine rows: {sum(len(p.quarantine) for p in posts)} '
          f'(blocking posts {blocking})', flush=True)

    session = _open_session(args)
    try:
        checks = preflight(session, posts, blocking)
        print(f'APPLY preflight: subjects_v1={checks.subjects_v1} '
              f'existing_posts={checks.existing_posts} existing_slugs={checks.existing_slugs} '
              f'verified={checks.verified_occurrences}', flush=True)
        if checks.already_applied:
            print('APPLY already applied: every pilot post and slug is present; '
                  'nothing to do.', flush=True)
            print(json.dumps(postflight(session), indent=2), flush=True)
            return 0

        def progress(table, inserted, planned):
            print(f'APPLY   {table}: inserted {inserted}/{planned}', flush=True)

        inserted = apply_pilot(session, posts, expected, on_progress=progress)
        print('APPLY committed:', json.dumps(inserted), flush=True)
        quarantined = apply_quarantine(session, posts)
        print(f'APPLY quarantine committed: {quarantined}', flush=True)
        print('\nAPPLY postflight:', flush=True)
        print(json.dumps(postflight(session), indent=2), flush=True)
    except (ApplyAborted, Exception) as exc:  # noqa: B014 - report, never leak params
        print(f'APPLY ABORTED ({type(exc).__name__}): {exc}', flush=True)
        return 4
    finally:
        session.close()
    return 0


def cmd_postflight(args) -> int:
    """Read-only verification of an applied pilot."""
    if args.project_ref != LEGENDSTUDY_PROJECT_REF:
        print(f'refusing: project ref {args.project_ref!r} is not LegendStudy', flush=True)
        return 3
    session = _open_session(args)
    try:
        print(json.dumps(postflight(session), indent=2))
    finally:
        session.close()
    return 0


def cmd_emit_seed(path: Path) -> int:
    """Render the taxonomy seed SQL. Writes a file; never touches a database."""
    from ingestion.subjects import CURRICULUM_VERSION, SUBJECTS_V1, TAXONOMY_VERSION

    def lit(value: str | None) -> str:
        return 'null' if value is None else "'" + value.replace("'", "''") + "'"

    lines = [
        '-- LegendStudy subjects taxonomy seed. NOT APPLIED.',
        '-- Generated by tool/ingest_legendstudy.py --emit-subjects-seed.',
        '-- Owner applies this; see wiki/day-9-subjects-taxonomy.md.',
        '-- Deterministic ids: uuid5(uuid5(URL, "https://legendstudy.com/taxonomy"),',
        '--                         "<taxonomy_version>:<code>").',
        '-- Rerunning is a no-op: ON CONFLICT DO NOTHING never edits a released row.',
        'begin;',
        '',
        'insert into public.subjects',
        '    (id, code, name, category, taxonomy_version, curriculum_version,',
        '     parent_id, is_active, sort_order)',
        'values',
    ]
    rows = []
    for s in SUBJECTS_V1:
        rows.append(
            f"    ('{s.id}', {lit(s.code)}, {lit(s.name)}, {lit(s.category)}, "
            f"{lit(TAXONOMY_VERSION)}, {lit(CURRICULUM_VERSION)}, null, true, {s.sort_order})")
    lines.append(',\n'.join(rows))
    lines += [
        'on conflict (taxonomy_version, code) do nothing;',
        '',
        '-- Expected: 23 rows inserted on a clean run, 0 on a rerun.',
        f"select count(*) as subjects_v1 from public.subjects where taxonomy_version = {lit(TAXONOMY_VERSION)};",
        '',
        'commit;',
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'wrote {path} ({len(SUBJECTS_V1)} subjects, taxonomy_version={TAXONOMY_VERSION})')
    return 0


def cmd_survey(path: Path) -> int:
    """Title-parsing coverage over every surveyed post.

    The survey index keeps only the top-level category, so this measures exam
    identity extraction from titles, not content-type classification.
    """
    from collections import Counter
    from ingestion.parser import parse_title

    stats = Counter()
    gaps: list[tuple[str, str, list[str]]] = []
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        post_id, _pub, cat, _kk, _bx, title = (line.split('|', 5) + [''] * 6)[:6]
        stats['posts'] += 1
        looks_exam = '고1' in cat or '고2' in cat or '고3' in cat
        if not looks_exam:
            stats['non_exam_category'] += 1
            continue
        stats['exam_category'] += 1
        facts = parse_title(title, cat)
        missing = [k for k in ('calendar_year', 'nominal_month', 'grade_level', 'exam_type')
                   if facts[k] is None]
        if facts['nominal_month'] is None and facts['administered_month'] is not None:
            missing = [m for m in missing if m != 'nominal_month']
        if missing:
            stats['incomplete'] += 1
            gaps.append((post_id, title, missing))
        else:
            stats['complete'] += 1
            stats[f"type_{facts['exam_type']}"] += 1
    print(json.dumps(dict(sorted(stats.items())), ensure_ascii=False, indent=2))
    if gaps:
        print(f'\nincomplete exam identity ({len(gaps)}):')
        for post_id, title, missing in gaps:
            print(f'  {post_id}: {",".join(missing):38} {title[:64]}')
    return 0


def cmd_smoke(count: int, delay: float) -> int:
    fetcher = PoliteFetcher(
        delay=delay,
        max_requests=(count + 1) * (DEFAULT_MAX_RETRIES + 1),
        on_retry=_report_retry,
    )
    source = NetworkSource(fetcher)
    try:
        ids = source.post_ids()
    except FetchError as exc:
        print(f'SMOKE FAIL sitemap: {exc}')
        return 2
    print(f'sitemap ok: {len(ids)} post ids, newest {ids[:3]}')
    ok = 0
    for post_id in ids[:count]:
        try:
            post = source.post(post_id)
        except FetchError as exc:
            print(f'  {post_id}: FETCH FAIL {exc}')
            continue
        checks = {
            'id': post.external_post_id == str(post_id),
            'title': bool(post.title),
            'category': bool(post.category),
            'published': bool(post.published_at),
            'attachments': len(post.attachments) >= 0,
        }
        ok += all(checks.values())
        print(f'  {post_id}: {"PASS" if all(checks.values()) else "FAIL"} '
              f'attachments={len(post.attachments)} title={post.title[:44]!r}')
    print(f'smoke: {ok}/{count} posts parsed; requests={fetcher.stats.requests} '
          f'retries={fetcher.stats.retries} failures={fetcher.stats.failures}')
    return 0 if ok == count else 1


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--source', choices=('sample', 'network'), default='sample')
    ap.add_argument('--sample', action='append', type=Path,
                    help='extraction sample JSONL (repeatable)')
    ap.add_argument('--limit', type=int, default=None)
    ap.add_argument('--pilot', choices=('c',), default=None,
                    help="restrict to the approved pilot scope (c = 2025-2026 exams)")
    ap.add_argument('--post-ids', default=None,
                    help='comma-separated explicit external post ids for a general '
                         'controlled apply (A3-1). Only these ids are fetched/applied; '
                         'all Pilot C safety gates still apply.')
    ap.add_argument('--no-taxonomy', action='store_true',
                    help='plan occurrences as unmapped instead of applying taxonomy v1')
    ap.add_argument('--emit-subjects-seed', type=Path, default=None,
                    help='write the subjects taxonomy seed SQL and exit')
    ap.add_argument('--delay', type=float, default=DEFAULT_DELAY_SECONDS)
    ap.add_argument('--out', type=Path, default=REPO / 'build/ingestion-dryrun')
    ap.add_argument('--state', type=Path, default=None,
                    help='previous-run digests, for changed/unchanged detection')
    ap.add_argument('--write-state', action='store_true')
    ap.add_argument('--network-smoke', type=int, nargs='?', const=3, default=None)
    ap.add_argument('--survey', type=Path, default=None,
                    help='title-parsing coverage over the pipe-delimited survey index')
    ap.add_argument('--apply', action='store_true',
                    help='write the pilot to production; every gate must be satisfied')
    ap.add_argument('--project-ref', default=None)
    ap.add_argument('--i-have-owner-approval', action='store_true')
    ap.add_argument('--db-host', default=None,
                    help='Supabase session pooler host; falls back to config, then prompt')
    ap.add_argument('--config', type=Path, default=REPO / 'config/development.json',
                    help='local public config; never holds a password')
    ap.add_argument('--postflight', action='store_true',
                    help='read-only verification of an applied pilot, then exit')
    args = ap.parse_args(argv)

    if args.postflight:
        return cmd_postflight(args)
    if args.network_smoke is not None:
        return cmd_smoke(args.network_smoke, args.delay)
    if args.survey is not None:
        return cmd_survey(args.survey)
    if args.emit_subjects_seed is not None:
        return cmd_emit_seed(args.emit_subjects_seed)

    approved_ids: list[int] | None = None
    if args.post_ids:
        if args.pilot:
            print('INGEST error target=apply kind=pilot_and_post_ids_are_exclusive',
                  flush=True)
            return 2
        try:
            approved_ids = [int(x) for x in args.post_ids.split(',') if x.strip()]
        except ValueError:
            print('INGEST error target=apply kind=post_ids_must_be_integers', flush=True)
            return 2
        if not approved_ids:
            print('INGEST error target=apply kind=empty_post_ids', flush=True)
            return 2

    crawled_at = _now()
    if args.source == 'network':
        anticipated = (len(approved_ids) if approved_ids is not None
                       else min(args.limit, len(PILOT_C_POST_IDS))
                       if args.pilot == 'c' and args.limit is not None
                       else len(PILOT_C_POST_IDS) if args.pilot == 'c'
                       else args.limit)
        request_budget = ((anticipated + 1) * (DEFAULT_MAX_RETRIES + 1)
                          if anticipated is not None else None)
        fetcher = PoliteFetcher(delay=args.delay,
                               max_requests=request_budget,
                               on_retry=_report_retry)
        source = NetworkSource(fetcher)
        sitemap_started = time.monotonic()
        print('INGEST fetch target=sitemap', flush=True)
        try:
            ids = source.post_ids()
        except FetchError as exc:
            print(f'INGEST error target=sitemap '
                  f'kind={exc.reason.replace(" ", "_")} '
                  f'transient={str(exc.transient).lower()} '
                  f'elapsed={time.monotonic() - sitemap_started:.1f}s', flush=True)
            return 2
        print(f'INGEST done target=sitemap elapsed={time.monotonic() - sitemap_started:.1f}s '
              f'posts={len(ids)}', flush=True)
        try:
            selected_ids = _network_post_ids(ids, args.pilot, args.limit, approved_ids)
        except ValueError as exc:
            print(f'INGEST error target=pilot kind={str(exc).replace(" ", "_")}', flush=True)
            return 2
        budget_text = str(request_budget) if request_budget is not None else 'unbounded'
        print(f'INGEST network targets={len(selected_ids)} timeout={DEFAULT_TIMEOUT_SECONDS}s '
              f'retries={DEFAULT_MAX_RETRIES} delay={args.delay:g}s '
              f'request_budget={budget_text}', flush=True)
        posts, failures = _fetch_network_posts(source, selected_ids)
        if (args.pilot == 'c' or approved_ids is not None) and failures:
            print(f'INGEST error target=apply kind=incomplete_fetch failures={failures}',
                  flush=True)
            return 2
    else:
        paths = args.sample or list(DEFAULT_SAMPLES)
        posts = []
        for path in paths:
            posts.extend(SampleSource(path).posts())
        if args.limit:
            posts = posts[: args.limit]

    previous = load_state(args.state)
    result = run(posts, crawled_at, previous, map_subjects=not args.no_taxonomy)
    if args.pilot == 'c':
        keep = {p.external_post_id for p in result.plans
                if p.exam and p.exam['year'] >= 2025}
        result.plans = [p for p in result.plans if p.external_post_id in keep]
        result.quarantine = [c for c in result.quarantine
                             if c.external_post_id in keep or c.external_post_id is None]
        result.changed = [i for i in result.changed if i in keep]
        result.unchanged = [i for i in result.unchanged if i in keep]
    elif approved_ids is not None:
        # General controlled apply: keep only the explicitly approved plans; an
        # unrelated observed post is never carried into the apply set.
        keep = {str(x) for x in approved_ids}
        result.plans = [p for p in result.plans if p.external_post_id in keep]
        result.quarantine = [c for c in result.quarantine
                             if c.external_post_id in keep or c.external_post_id is None]
        result.changed = [i for i in result.changed if i in keep]
        result.unchanged = [i for i in result.unchanged if i in keep]

    written = write_artifacts(result, args.out, crawled_at)
    if args.write_state and args.state:
        args.state.parent.mkdir(parents=True, exist_ok=True)
        args.state.write_text(json.dumps(next_state(result, previous), indent=2) + '\n',
                              encoding='utf-8')

    counts = result.counts()
    print(json.dumps(counts, ensure_ascii=False, indent=2))
    print('\nartifacts:')
    for path in written:
        try:
            print(f'  {path.relative_to(REPO)}')
        except ValueError:
            print(f'  {path}')

    if args.apply:
        return cmd_apply(args, result)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
