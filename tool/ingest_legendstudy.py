#!/usr/bin/env python3
"""legendstudy.com ingestion CLI. Dry-run by default; never writes to Supabase.

    python3 tool/ingest_legendstudy.py                      # offline dry-run
    python3 tool/ingest_legendstudy.py --source network     # live dry-run
    python3 tool/ingest_legendstudy.py --network-smoke 3    # structure check

`--apply` exists so the gate is testable. It always refuses in Day 9-B.
No credential, cookie or signed query is written to any artifact.
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
from ingestion.normalizer import ADVISORY, BLOCKING  # noqa: E402
from ingestion.writer import ApplyRefused, assert_apply_allowed, plan_statements  # noqa: E402

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
                      limit: int | None) -> list[int]:
    if pilot == 'c':
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
        w = csv.writer(fh)
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
        w = csv.writer(fh)
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
        flags = sorted({c.kind for c in p.quarantine if c.kind not in ADVISORY})
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
                    help='refused in Day 9-B; the gate is kept testable')
    ap.add_argument('--project-ref', default=None)
    ap.add_argument('--i-have-owner-approval', action='store_true')
    args = ap.parse_args(argv)

    if args.network_smoke is not None:
        return cmd_smoke(args.network_smoke, args.delay)
    if args.survey is not None:
        return cmd_survey(args.survey)
    if args.emit_subjects_seed is not None:
        return cmd_emit_seed(args.emit_subjects_seed)

    crawled_at = _now()
    if args.source == 'network':
        anticipated = (min(args.limit, len(PILOT_C_POST_IDS))
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
            selected_ids = _network_post_ids(ids, args.pilot, args.limit)
        except ValueError as exc:
            print(f'INGEST error target=pilot kind={str(exc).replace(" ", "_")}', flush=True)
            return 2
        budget_text = str(request_budget) if request_budget is not None else 'unbounded'
        print(f'INGEST network targets={len(selected_ids)} timeout={DEFAULT_TIMEOUT_SECONDS}s '
              f'retries={DEFAULT_MAX_RETRIES} delay={args.delay:g}s '
              f'request_budget={budget_text}', flush=True)
        posts, failures = _fetch_network_posts(source, selected_ids)
        if args.pilot == 'c' and failures:
            print(f'INGEST error target=pilot kind=incomplete_fetch failures={failures}',
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

    if args.apply:
        try:
            assert_apply_allowed(args.project_ref, args.i_have_owner_approval)
        except ApplyRefused as exc:
            print(f'APPLY {exc}')
            return 3

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
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
