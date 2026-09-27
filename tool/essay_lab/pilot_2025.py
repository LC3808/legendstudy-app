"""Bounded 2025 Pilot manifest checks and INSERT-only transaction body.

No credentials, network discovery, classification, upsert or automatic commit.
Operator supplies a project-pinned DB session and commits only after runtime checks.
"""
from __future__ import annotations
import json
from pathlib import Path
from uuid import UUID
from urllib.parse import urlparse

PLAN = Path(__file__).with_name('pilot_2025_phase1_plan.json')
SCOPE = {'yonsei': ('연세대학교', {'1671'}),
         'sungkyunkwan': ('성균관대학교', {'1689'}),
         'kyunghee': ('경희대학교', {'1633', '1682'})}
ROLES = {'question', 'passage', 'exam_intent', 'scoring_criteria', 'model_answer',
         'example_answer', 'high_scoring_answer', 'explanation', 'guidebook', 'other'}
TABLES = ('universities', 'essay_exams', 'essay_exam_resources')
COLUMNS = {
 'universities': ('id', 'slug', 'name', 'is_active'),
 'essay_exams': ('id','university_id','admission_year','exam_key','exam_name','exam_kind',
  'campus','admission_track','field_or_division','session_label','exam_date',
  'duration_minutes','question_count','answer_length_text','exam_format','provenance',
  'metadata_resource_id','official_source_url','evidence_note','verification_status','is_active'),
 'essay_exam_resources': ('essay_exam_id','resource_id','role','provenance',
  'verification_status','source_locator','official_source_url','evidence_note','is_active'),
}

def validate(plan):
    """Fail closed on scope, duplicate, provenance and held-role violations."""
    us = {u['id']: u for u in plan['universities']}
    assert len(us) == len(plan['universities']) == 3, 'University identity collision'
    assert {u['slug'] for u in us.values()} == set(SCOPE), 'University scope'
    es = {e['id']: e for e in plan['exams']}
    assert len(es) == len(plan['exams']), 'Exam UUID collision'
    keys = [(e['university_id'], e['admission_year'], e['exam_key']) for e in es.values()]
    assert len(keys) == len(set(keys)), 'Exam stable-key collision'
    docs = {d['resource_id']: d for d in plan['documents']}
    assert len(docs) == len(plan['documents']) == 38, 'Resource inventory drift'
    mk = [(m['essay_exam_id'], m['resource_id'], m['role']) for m in plan['mappings']]
    assert len(mk) == len(set(mk)), 'Mapping collision'
    hosts = {'yonsei': 'yonsei.ac.kr', 'sungkyunkwan': 'skku.edu', 'kyunghee': 'khu.ac.kr'}
    for u in us.values():
        UUID(u['id']); assert u['name'] == SCOPE[u['slug']][0]
        assert set(u) == set(COLUMNS['universities'])
    for e in es.values():
        UUID(e['id']); assert e['admission_year'] == 2025, 'Year scope'
        assert e['university_id'] in us
        assert e['metadata_resource_id'] in docs
        assert e['exam_kind'] in ('admission','mock')
        assert set(e) == set(COLUMNS['essay_exams'])
        assert docs[e['metadata_resource_id']]['source_post_id'] in SCOPE[us[e['university_id']]['slug']][1]
    for m in plan['mappings']:
        assert set(m) == set(COLUMNS['essay_exam_resources'])
        assert m['essay_exam_id'] in es and m['resource_id'] in docs, 'Manifest orphan'
        assert m['role'] in ROLES and m['source_locator'].strip()
        e = es[m['essay_exam_id']]; u = us[e['university_id']]
        assert docs[m['resource_id']]['source_post_id'] in SCOPE[u['slug']][1], 'Cross-university mapping'
    for row in [*es.values(), *plan['mappings']]:
        e = row if 'university_id' in row else es[row['essay_exam_id']]
        suffix = hosts[us[e['university_id']]['slug']]
        parsed = urlparse(row['official_source_url'])
        assert parsed.scheme == 'https' and (parsed.hostname == suffix or parsed.hostname.endswith('.'+suffix)), 'Official source host'
        assert row['verification_status'] == 'verified' and row['provenance'] == 'official'
        assert row['is_active'] is True and row['evidence_note'].strip()
    for q in plan['review_queue']:
        assert q['status'] == 'OWNER_REVIEW_REQUIRED'
        assert not any(m['resource_id'] == q['resource_id'] and m['role'] in q['held_roles'] for m in plan['mappings']), 'Held role included'
    for r in plan['resolved_reviews']:
        assert r['admission_year'] == 2025 and r['status'] == 'RESOLVED_BY_OWNER'
        affected = [m for m in plan['mappings'] if m['resource_id'] == r['resource_id']]
        assert affected and all(r['evidence_note'] in m['evidence_note'] for m in affected), 'Year conflict evidence lost'
    return plan


def load_plan():
    return validate(json.loads(PLAN.read_text()))


def scope(plan, slug, *, validate_plan=validate):
    validate_plan(plan)
    assert slug in {u["slug"] for u in plan["universities"]}
    u = next(u for u in plan['universities'] if u['slug'] == slug)
    es = sorted((e for e in plan['exams'] if e['university_id'] == u['id']), key=lambda e: e['exam_key'])
    ids = {e['id'] for e in es}
    ms = sorted((m for m in plan['mappings'] if m['essay_exam_id'] in ids), key=lambda m: (m['essay_exam_id'],m['resource_id'],m['role']))
    return dict(zip(TABLES, ([u], es, ms)))


def preflight(session, plan, slug, *, validate_plan=validate):
    rows = scope(plan, slug, validate_plan=validate_plan); u = rows['universities'][0]
    assert session.execute('SELECT count(*) FROM public.universities WHERE id=%s OR slug=%s OR name=%s', (u['id'],u['slug'],u['name']))[0][0] == 0, 'University collision'
    es = rows['essay_exams']; ids = [e['id'] for e in es]
    assert session.execute('SELECT count(*) FROM public.essay_exams WHERE id::text=ANY(%s) OR university_id=%s', (ids,u['id']))[0][0] == 0, 'Exam collision'
    assert session.execute('SELECT count(*) FROM public.essay_exam_resources WHERE essay_exam_id::text=ANY(%s)', (ids,))[0][0] == 0, 'Mapping collision'
    wanted = {m['resource_id'] for m in rows['essay_exam_resources']}
    wanted.update(e['metadata_resource_id'] for e in es)
    docs = {d['resource_id']: d for d in plan['documents']}
    found = session.execute('''SELECT r.id::text,r.content_item_id::text,r.source_resource_key,r.title,
      r.is_active,c.is_active,s.external_post_id
      FROM public.resources r JOIN public.content_items c ON c.id=r.content_item_id
      JOIN public.source_posts s ON s.id=c.source_post_id WHERE r.id::text=ANY(%s)''', (sorted(wanted),))
    assert {r[0] for r in found} == wanted, 'Missing resource FK'
    for rid, cid, key, title, active, parent, post in found:
        d=docs[rid]
        assert (cid,key,title,str(post)) == (d['content_item_id'],d['source_resource_key'],d['title'],d['source_post_id']), 'Resource identity drift'
        assert active and parent, 'Inactive resource/parent'
    for role in ('anon','authenticated'):
        for table in TABLES:
            grants = session.execute("SELECT has_table_privilege(%s,%s,'SELECT'),has_table_privilege(%s,%s,'INSERT,UPDATE,DELETE')", (role,'public.'+table,role,'public.'+table))[0]
            assert grants == (True,False), 'Client privilege drift'
    assert session.execute("SELECT count(*) FROM pg_class WHERE oid=ANY(ARRAY['public.universities'::regclass,'public.essay_exams'::regclass,'public.essay_exam_resources'::regclass]) AND relrowsecurity")[0][0] == 3, 'RLS disabled'
    return {t:len(v) for t,v in rows.items()}


def insert_scope(session, plan, slug, *, validate_plan=validate):
    """Caller must rollback on ANY exception; no implicit transaction commit."""
    assert session.execute('SELECT current_user')[0][0] == 'postgres', 'Operator role required'
    expected = preflight(session, plan, slug, validate_plan=validate_plan)
    rows = scope(plan, slug, validate_plan=validate_plan); actual = {}
    session.execute('SET LOCAL ROLE service_role')
    for table, records in rows.items():
        columns = COLUMNS[table]
        extra = '' if table == 'universities' else ',verified_at'
        values_extra = '' if table == 'universities' else ',transaction_timestamp()'
        query = f"INSERT INTO public.{table} ({','.join(columns)}{extra}) VALUES ({','.join(['%s']*len(columns))}{values_extra}) RETURNING 1"
        actual[table] = sum(len(session.execute(query, tuple(row[c] for c in columns))) for row in records)
    session.execute('SET LOCAL ROLE postgres')
    assert actual == expected, 'Apply count mismatch'
    return actual


def runtime_check(session, plan, slug, *, validate_plan=validate):
    """Exact rows, real SQL-role RLS reads/write denial and existing lookup query.

    Checks run inside the caller transaction. Write-denial probes affect zero rows
    even if privileges drift, and each probe is rolled back to its savepoint.
    SQL-role execution is not an end-user JWT login test.
    """
    rows=scope(plan,slug,validate_plan=validate_plan); ids=[e['id'] for e in rows['essay_exams']]
    uid=rows['universities'][0]['id']
    filters={'universities':('id=%s',(uid,)),
             'essay_exams':('id::text=ANY(%s)',(ids,)),
             'essay_exam_resources':('essay_exam_id::text=ANY(%s)',(ids,))}
    for table,expected in rows.items():
        where,args=filters[table]
        actual=[r[0] for r in session.execute(f'SELECT to_jsonb(t) FROM public.{table} t WHERE {where}',args)]
        keys=COLUMNS[table]
        project=lambda r:{k:r[k] for k in keys}
        ordered=lambda records:sorted((project(r) for r in records),key=lambda r:json.dumps(r,sort_keys=True))
        assert ordered(actual)==ordered(expected), 'Exact row mismatch: '+table
        if table!='universities':assert all(r['verified_at'] for r in actual)
    assert session.execute('''SELECT count(*) FROM public.essay_exam_resources m
        LEFT JOIN public.essay_exams e ON e.id=m.essay_exam_id
        LEFT JOIN public.resources r ON r.id=m.resource_id
        WHERE e.id IS NULL OR r.id IS NULL''')[0][0]==0,'Orphan'
    lookup_path=Path(__file__).parents[2]/'supabase/review/essay_lab/evidence_lookup.sql'
    lookup='\n'.join(line for line in lookup_path.read_text().splitlines() if not line.lstrip().startswith('--')).replace('$1','%s')
    result={}
    for role in ('anon','authenticated'):
        session.execute('SET LOCAL ROLE '+role)
        read_counts={}
        for table in TABLES:
            where,args=filters[table]
            count=session.execute(f'SELECT count(*) FROM public.{table} WHERE {where}',args)[0][0]
            assert count==len(rows[table]),'Public visibility mismatch'
            read_counts[table]=count
            probes=[f'INSERT INTO public.{table} SELECT * FROM public.{table} WHERE false',
                    f'UPDATE public.{table} SET is_active=false WHERE false',
                    f'DELETE FROM public.{table} WHERE false']
            for sql in probes:
                session.execute('SAVEPOINT deny_probe');denied=False
                try:session.execute(sql)
                except Exception as exc:
                    if getattr(exc,'sqlstate',None)!='42501':raise
                    denied=True
                finally:
                    session.execute('ROLLBACK TO SAVEPOINT deny_probe')
                    session.execute('RELEASE SAVEPOINT deny_probe')
                assert denied,'Client write unexpectedly permitted'
        counts=[]
        for eid in ids:
            first=session.execute(lookup,(eid,));second=session.execute(lookup,(eid,))
            assert first==second,'Non-deterministic evidence lookup'
            expected={(m['role'],m['resource_id']) for m in rows['essay_exam_resources'] if m['essay_exam_id']==eid and m['provenance']=='official' and m['verification_status']=='verified'}
            assert {(r[0],str(r[1])) for r in first}==expected,'Evidence set mismatch'
            counts.append(len(first))
        result[role]={'select':read_counts,'insert_update_delete_denied':True,'deterministic_evidence_counts':counts}
        session.execute('SET LOCAL ROLE postgres')
    return result
