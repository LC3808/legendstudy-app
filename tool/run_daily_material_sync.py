#!/usr/bin/env python3
"""Owner-gated daily runner. No student, evaluation or payment tables used."""
from __future__ import annotations
import argparse
from collections import Counter
from dataclasses import asdict
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import sys
import uuid
from urllib.robotparser import RobotFileParser
from xml.etree import ElementTree

from ingestion.apply import COLUMNS, WRITE_ORDER
from ingestion.crawler import PoliteFetcher, ACCEPT_XML, sitemap_entries, USER_AGENT
from ingestion.daily_sync import ReviewRequired, observe, reconcile, require, timestamp
from ingestion.writer import LEGENDSTUDY_PROJECT_REF

TABLES = WRITE_ORDER

def now():
    return datetime.now(timezone.utc).isoformat()


def load_current(conn, post_id, lock=False):
    suffix = " for update" if lock else ""
    sources = conn.execute("select * from public.source_posts where source='legendstudy' and external_post_id=%s"+suffix, (post_id,)).fetchall()
    if not sources:
        return None
    source = sources[0]
    parents = conn.execute('select * from public.content_items where source_post_id=%s'+suffix, (source['id'],)).fetchall()
    ids = [p['id'] for p in parents]
    return {'source_posts': sources, 'content_items': parents,
            'exams': conn.execute('select * from public.exams where content_item_id=any(%s)', (ids,)).fetchall(),
            'exam_subjects': conn.execute('select * from public.exam_subjects where content_item_id=any(%s)', (ids,)).fetchall(),
            'resources': conn.execute('select * from public.resources where source_post_id=%s'+suffix, (source['id'],)).fetchall()}


def apply_changes(conn, run_id, post_id, changes):
    from psycopg import sql
    from psycopg.types.json import Jsonb
    for change in changes:
        require(change.table in TABLES, 'table_not_allowed')
        row = dict(change.after)
        for k in ('raw_metadata',):
            if k in row:
                row[k] = Jsonb(json.loads(row[k]) if isinstance(row[k], str) else row[k])
        table = sql.Identifier('public', change.table)
        if change.before is None:
            require(set(row) <= set(COLUMNS[change.table]), 'column_not_allowed')
            conn.execute(sql.SQL('insert into {} ({}) values ({})').format(table,
                         sql.SQL(',').join(map(sql.Identifier, row)),
                         sql.SQL(',').join(sql.Placeholder() for _ in row)), list(row.values()))
        else:
            key = 'content_item_id' if change.table == 'exams' else 'id'
            stmt = sql.SQL('update {} set {} where {}=%s').format(table,
                   sql.SQL(',').join(sql.SQL('{}=%s').format(sql.Identifier(k)) for k in row),
                   sql.Identifier(key))
            result = conn.execute(stmt, [*row.values(), change.key])
            require(result.rowcount == 1, 'update_row_missing')
        # JSON contains only source content metadata, never raw HTML/signatures/users.
        conn.execute('insert into ingestion_ops.changes(run_id,post_id,table_name,row_id,before_row,after_row) values (%s,%s,%s,%s,%s,%s)',
                     (run_id, post_id, change.table, change.key,
                      Jsonb(json.loads(json.dumps(change.before, default=str))),
                      Jsonb(json.loads(json.dumps(change.after, default=str)))))


def run(conn, *, apply=False, only=(), fetcher=None, output=Path('daily-sync-report.json')):
    from psycopg.types.json import Jsonb
    conn.execute("set statement_timeout='30s'")
    conn.execute("set lock_timeout='5s'")
    # Session pooler/direct only: session advisory lock spans per-post commits.
    require(conn.execute('select pg_try_advisory_lock(178431, 18) as locked').fetchone()['locked'], 'run_already_active')
    run_id = str(uuid.uuid4())
    report = {'run_id': run_id, 'mode': 'apply' if apply else 'dry_run', 'started_at': now(), 'posts': []}
    counts = Counter()
    try:
        if apply:
            conn.execute("update ingestion_ops.runs set status='interrupted',finished_at=now() where status='running'")
            conn.execute("insert into ingestion_ops.runs(id,trigger_name,status) values (%s,%s,'running')", (run_id, os.getenv('GITHUB_EVENT_NAME','operator')))
        config = conn.execute('select * from ingestion_ops.config where singleton').fetchone()
        require(bool(config), 'configuration_missing')
        if apply:
            require(config['enabled'], 'sync_disabled')
        fetcher = fetcher or PoliteFetcher(max_requests=4000)
        robots = RobotFileParser()
        robots.parse(fetcher.get('https://legendstudy.com/robots.txt', request_label='robots').splitlines())
        require(robots.can_fetch(USER_AGENT, 'https://legendstudy.com/sitemap.xml'), 'robots_denied')
        xml = fetcher.get('https://legendstudy.com/sitemap.xml', accept=ACCEPT_XML, request_label='sitemap')
        require(ElementTree.fromstring(xml).tag.rsplit('}',1)[-1] == 'urlset', 'sitemap_incomplete')
        inventory = {e.external_post_id:e.lastmod for e in sitemap_entries(xml)}
        require(len(inventory) >= 100, 'sitemap_inventory_suspicious')
        existing = {r['external_post_id'] for r in conn.execute("select external_post_id from public.source_posts where source='legendstudy'")}
        prior = {r['post_id']:r for r in conn.execute('select * from ingestion_ops.observations')}
        new = [i for i in inventory if i not in existing and
               (i not in prior or prior[i]['status']=='failed' or prior[i]['lastmod'] != inventory[i])]
        # Numeric Tistory identities prioritize genuinely new posts over old edits.
        # Every registered post is reconciled separately regardless of lastmod.
        new.sort(key=int, reverse=True)
        candidates = sorted(existing, key=int) + new[:30]
        if only:
            require(set(only) <= (set(inventory)|existing), 'unknown_requested_source')
            candidates = list(only)
        require(len(candidates) <= 1000, 'source_budget_requires_review')
        report['discovered'] = len(inventory)
        report['new_deferred'] = max(0, len(new)-30)
        for post_id in candidates:
            if apply:
                require(conn.execute('select enabled from ingestion_ops.config where singleton').fetchone()['enabled'], 'sync_disabled')
            status, code, changes = 'ok', None, []
            try:
                url = f'https://legendstudy.com/{post_id}'
                require(robots.can_fetch(USER_AGENT,url), 'robots_denied')
                post = observe(post_id, fetcher.get(url, request_label=post_id), now())
                # Independent repeat is mandatory for deletions. Compare canonical
                # hash, not rotating credentials. Fetch before taking row locks.
                with conn.transaction():
                    before = load_current(conn,post_id)
                removed = before and any(r['is_active'] and r['source_resource_key'] not in
                             {x['source_resource_key'] for x in post.resources} for r in before['resources'])
                confirm = None
                if removed:
                    confirm = observe(post_id,fetcher.get(url,request_label=post_id+'-confirm'),now()).source_post['content_hash']
                with conn.transaction():
                    current = load_current(conn,post_id,lock=apply)
                    if post.exam and current is None:
                        e=post.exam
                        duplicate=conn.execute('select 1 from public.exams where year=%s and exam_month=%s and grade_level=%s and exam_type=%s limit 1',
                                               (e['year'],e['exam_month'],e['grade_level'],e['exam_type'])).fetchone()
                        require(not duplicate, 'existing_exam_identity')
                    managed={str(r['row_id']) for r in conn.execute("select distinct on (row_id) row_id, after_row from ingestion_ops.changes where table_name='resources' and post_id=%s and after_row ? 'is_active' order by row_id,id desc", (post_id,)) if r['after_row'].get('is_active') is False}
                    changes=reconcile(post,current,new_since=config['new_since'],confirmed_hash=confirm,managed_removed=managed)
                    if apply:
                        apply_changes(conn,run_id,post_id,changes)
            except ReviewRequired as exc:
                status, code = 'review', str(exc)
            except Exception as exc:
                # Never serialize exceptions which can include SQL, DSNs or HTML.
                status, code = 'failed', type(exc).__name__
            counts[status] += 1
            summary={'post_id':post_id,'status':status,'code':code,
                     'changes':dict(Counter(c.table for c in changes)) if status=='ok' else {}}
            report['posts'].append(summary)
            if apply:
                conn.execute('insert into ingestion_ops.observations(post_id,lastmod,status,error_code,observed_at,last_success_at) values (%s,%s,%s,%s,now(),case when %s then now() else null end) on conflict(post_id) do update set lastmod=excluded.lastmod,status=excluded.status,error_code=excluded.error_code,observed_at=excluded.observed_at,last_success_at=coalesce(excluded.last_success_at,ingestion_ops.observations.last_success_at)',
                             (post_id,inventory.get(post_id),status,code,status=='ok'))
            print(json.dumps(summary,ensure_ascii=False),flush=True)
        report['status']='partial' if counts['failed'] or counts['review'] else 'success'
    except Exception as exc:
        report['status']='failed'
        report['error_code']=type(exc).__name__
    finally:
        report['finished_at']=now()
        report['counts']=dict(counts)
        output.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
        if apply:
            conn.execute('update ingestion_ops.runs set status=%s,finished_at=now(),summary=%s where id=%s',
                         (report['status'],Jsonb(report),run_id))
        conn.execute('select pg_advisory_unlock(178431,18)')
    return report


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--apply',action='store_true')
    parser.add_argument('--post',action='append',default=[])
    parser.add_argument('--output',type=Path,default=Path('daily-sync-report.json'))
    args=parser.parse_args()
    import psycopg
    from psycopg.rows import dict_row
    from psycopg.conninfo import conninfo_to_dict
    dsn=os.environ['MATERIAL_SYNC_DATABASE_URL']
    info=conninfo_to_dict(dsn)
    require(info.get('port','5432')=='5432', 'session_connection_required')
    require(info.get('sslmode')=='verify-full', 'verified_tls_required')
    require(info.get('user') in ('legendstudy_material_sync',f'legendstudy_material_sync.{LEGENDSTUDY_PROJECT_REF}'), 'dedicated_role_required')
    host=info.get('host','')
    require(host==f'db.{LEGENDSTUDY_PROJECT_REF}.supabase.co' or
            (host.endswith('.pooler.supabase.com') and info.get('user','').endswith('.'+LEGENDSTUDY_PROJECT_REF)), 'target_project_mismatch')
    with psycopg.connect(dsn,autocommit=True,row_factory=dict_row,connect_timeout=20) as conn:
        if not args.apply:
            conn.execute('set default_transaction_read_only=on')
        result=run(conn,apply=args.apply,only=args.post,output=args.output)
    return 0 if result['status']=='success' else 1


if __name__=='__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print(json.dumps({'status':'failed','error_code':type(exc).__name__}),file=sys.stderr)
        sys.exit(1)
