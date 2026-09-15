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
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ingestion import PARSER_VERSION  # noqa: E402
from ingestion.crawler import (  # noqa: E402
    DEFAULT_DELAY_SECONDS, FetchError, NetworkSource, PoliteFetcher, SampleSource,
)
from ingestion.pipeline import DryRunResult, load_state, next_state, run  # noqa: E402
from ingestion.normalizer import ADVISORY, BLOCKING  # noqa: E402
from ingestion.writer import ApplyRefused, assert_apply_allowed, plan_statements  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
DEFAULT_SAMPLES = (REPO / 'tool/ingestion/samples/day9b_exam_posts.jsonl',)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


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
                    'exam_type', 'subjects', 'resource_kinds', 'resource_count',
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
    fetcher = PoliteFetcher(delay=delay, max_requests=count + 1)
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

    crawled_at = _now()
    if args.source == 'network':
        fetcher = PoliteFetcher(delay=args.delay,
                               max_requests=(args.limit + 1) if args.limit else None)
        source = NetworkSource(fetcher)
        try:
            ids = source.post_ids()
        except FetchError as exc:
            print(f'cannot enumerate sitemap: {exc}')
            return 2
        posts = []
        for post_id in ids[: args.limit or len(ids)]:
            try:
                posts.append(source.post(post_id))
            except FetchError as exc:
                print(f'skip {post_id}: {exc}')
    else:
        paths = args.sample or list(DEFAULT_SAMPLES)
        posts = []
        for path in paths:
            posts.extend(SampleSource(path).posts())
        if args.limit:
            posts = posts[: args.limit]

    previous = load_state(args.state)
    result = run(posts, crawled_at, previous)

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
