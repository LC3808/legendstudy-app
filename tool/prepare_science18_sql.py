"""Exact five-exam science material connection and bounded existing type gates."""
import argparse,json,hashlib
from pathlib import Path
from prepare_ewha_mock_essay_public import REGIME
APP=Path(__file__).resolve().parents[1]
AUTHORITY='Owner science18 implementation/publication instruction 2026-11-12'
def sql_candidates(app, baseline_path):
    root = app/'.local/khu-mock-science-20261112'; dest = app/'supabase/candidates/khu_mock_science_20261112'
    packages = json.loads((root/'science-packages.private.json').read_text())
    docs = json.loads((root/'science-documents.private.json').read_text())
    baseline = json.loads(baseline_path.read_text())
    if isinstance(baseline, dict): baseline = baseline['functions']
    policy = next(f for f in baseline if f.get('proname', f.get('name')) == 'runtime_policy' and f.get('nspname', 'essay_exam_private') == 'essay_exam_private')
    reader = next(f for f in baseline if f.get('proname', f.get('name')) == 'essay_material_runtime_package')
    assert policy['definition'].count('else null::jsonb end') == 1, 'POLICY_FORMAT_CHANGED'
    lit = lambda s: "'" + str(s).replace("'", "''") + "'"
    js = lambda x: lit(json.dumps(x, ensure_ascii=False, separators=(',', ':'))) + '::jsonb'
    ids = ','.join(lit(e)+'::uuid' for e in packages)
    existing_reviews = {r['r']['exam_id']:r['r'] for r in json.loads((baseline_path.parent/'science-existing-reviews.private.json').read_text())}
    existing_revisions = [r['r'] for r in json.loads((baseline_path.parent/'science-existing-revisions.private.json').read_text())]
    revisions = {e:existing_reviews.get(e,{}).get('revision',0)+1 for e in packages}
    assert len(existing_reviews)==2 and all('package' not in r['body'] for r in existing_reviews.values())
    expected = {e: sorted(q['question_id'] for q in p['questions']) for e,p in packages.items()}
    hashes = ','.join(lit(h) for h in docs)
    checks = [
      ('exact_policy_baseline', f"md5(pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure))={lit(policy['md5'])}"),
      ('reader_unchanged', f"md5(pg_get_functiondef('public.essay_material_runtime_package(uuid,text)'::regprocedure))={lit(reader['md5'])}"),
      ('registry_exact',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select coalesce(jsonb_agg(id::text order by id::text),'[]'::jsonb) from public.essay_questions where essay_exam_id=e.key::uuid) is distinct from e.value)"),
      ('review_baseline',f"(select coalesce(jsonb_object_agg(exam_id,to_jsonb(r)),'{{}}'::jsonb) from essay_material_private.reviews r where exam_id in ({ids}))={js(existing_reviews)}"),
      ('revision_baseline',f"(select coalesce(jsonb_agg(to_jsonb(r) order by exam_id,revision),'[]'::jsonb) from essay_material_private.revisions r where exam_id in ({ids}))={js(sorted(existing_revisions,key=lambda r:(r['exam_id'],r['revision'])))}"),
      ('runtime_absent',f"not exists(select 1 from unnest(array[{ids}]) e where essay_exam_private.runtime_policy(e) is not null)"),
      ('no_student_runs',f"not exists(select 1 from essay_exam_private.runs where exam_id in ({ids}))"),
      ('private_bucket',"exists(select 1 from storage.buckets where id='essay-material-originals' and not public)"),
      ('documents_compatible',f"not exists(select 1 from jsonb_each({js(docs)}) d join essay_material_private.documents x on x.sha256=d.key where x.page_count is distinct from (d.value->>'page_count')::int or x.object_key is distinct from d.value->>'object_key')")]
    def select(rows): return 'select '+',\n'.join('('+v+') as '+k for k,v in rows)+';\n'
    (dest/'essay-precheck.sql').write_text(select(checks))
    start = "begin;set local lock_timeout='5s';set local statement_timeout='90s';select pg_advisory_xact_lock(4925261025);\n"
    apply = start + "do $ewha$ declare p jsonb;b jsonb;definition text;clause text;begin\n"
    apply += "if not ("+' and '.join('('+v+')' for k,v in checks)+") then raise exception 'SCIENCE_ESSAY_BASELINE_CHANGED';end if;\n"
    apply += f'perform 1 from public.essay_exams where id in ({ids}) order by id for update;\n'
    for h,d in docs.items():
        apply += f"insert into essay_material_private.documents(sha256,resource_id,title,page_count,object_key) values({lit(h)},null,{lit(d['title'])},{d['page_count']},{lit(d['object_key'])}) on conflict(sha256) do nothing;\n"
    apply += "definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for eid,p in packages.items():
        apply += f'p:={js(p)};\n'
        apply += "if p->>'package_digest' is distinct from encode(sha256(convert_to((p-'package_digest')::text,'UTF8')),'hex') then raise exception 'PACKAGE_DIGEST_MISMATCH';end if;\n"
        revision=revisions[eid]
        prior=existing_reviews.get(eid,{}).get('body',{})
        body = dict(prior,documents=sorted(set(prior.get('documents',[]))|set(p['rights_status'])), runtimeApproval=dict(status='APPROVED',revision=revision,
                     authority=AUTHORITY,question_ids=expected[eid]))
        apply += f"b:={js(body)}||jsonb_build_object('package',p);\n"
        if eid in existing_reviews:
            apply += f"update essay_material_private.reviews set revision={revision},body=b where exam_id={lit(eid)};\n"
        else:
            apply += f"insert into essay_material_private.reviews(exam_id,revision,state,body,approval_requested) values({lit(eid)},{revision},'NEEDS_REVIEW',b,false);\n"
        apply += f"insert into essay_material_private.revisions(exam_id,revision,state,body) values({lit(eid)},{revision},'NEEDS_REVIEW',b);\n"
        policy_value = dict(regime=REGIME,package_digest=p['package_digest'],evaluation_type='science')
        apply += f"clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},{js(policy_value)}::text);\n"
        apply += "definition:=replace(definition,'else null::jsonb end',clause||'else null::jsonb end');\n"
    gates=[]
    for f in baseline:
        if f['proname'] not in ('essay_exam_preflight','essay_exam_submit','essay_exam_submit_cycle') or f['nspname']!='public':continue
        old=f['definition'];needle="not in ('humanities','business')";assert old.count(needle)==1
        new=old.replace(needle,"not in ('humanities','business','science')")
        gates.append(dict(name=f['proname'],before=old,after=new,before_md5=hashlib.md5(old.encode()).hexdigest(),after_md5=hashlib.md5(new.encode()).hexdigest()))
    assert len(gates)==3
    apply += 'execute definition;end $ewha$;\n'
    for g in gates:
        signature=next(f for f in baseline if f['proname']==g['name'] and f['nspname']=='public')
        # The SQL schema snapshot contains function arguments in the declaration;
        # resolve one exact existing name and compare the full body before replacing.
        apply += "do $gate$ begin if (select md5(pg_get_functiondef(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname="+lit(g['name'])+") is distinct from "+lit(g['before_md5'])+" then raise exception 'SCIENCE_GATE_DRIFT';end if;end $gate$;\n"+g['after'].rstrip().rstrip(';')+';\n'
    apply += 'commit;\n'
    (dest/'science-gate-functions.json').write_text(json.dumps(gates,indent=2)+'\n')

    (root/'essay-apply.private.sql').write_text('-- Private copyrighted source payload. Prepared only; do not apply until image adapter is ready.\n'+apply)
    post = [checks[1],checks[2],checks[-2],
      ('exact_reviews',f"(select count(*)=5 and bool_and(revision=({js(revisions)}->>exam_id::text)::int) from essay_material_private.reviews where exam_id in ({ids}))"),
      ('exact_revisions',f"(select count(*)=7 from essay_material_private.revisions where exam_id in ({ids}))"),
      ('packages_readable',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select jsonb_agg(q->>'question_id' order by q->>'question_id') from jsonb_array_elements(public.essay_material_runtime_package(e.key::uuid,essay_exam_private.runtime_policy(e.key::uuid)->>'package_digest')->'questions') q) is distinct from e.value)"),
      ('same_regime',f"(select bool_and(essay_exam_private.runtime_policy(e)->>'regime'={lit(REGIME)}) from unnest(array[{ids}]) e)")]
    (dest/'essay-postcheck.sql').write_text(select(post))
    (dest/'essay-public-readiness.sql').write_text('-- Existing whole-exam public service uses WEB scope, pinned runtime and Worker allowlist. Legacy Registry flags stay false.\n'+select(post))
    rollback = start + "do $ewha$ declare p jsonb;definition text;clause text;begin definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for eid,p in packages.items():
        pv = dict(regime=REGIME,package_digest=p['package_digest'],evaluation_type='science')
        rollback += f"p:=essay_exam_private.runtime_policy({lit(eid)});if p is not null then if p is distinct from {js(pv)} then raise exception 'SCIENCE_ROLLBACK_POLICY_CHANGED';end if;clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},p::text);if position(clause in definition)=0 then raise exception 'SCIENCE_ROLLBACK_FORMAT_CHANGED';end if;definition:=replace(definition,clause,'');end if;\n"
    rollback += 'execute definition;end $ewha$;commit;\n'
    (dest/'essay-rollback.sql').write_text('-- Disable only these 5 runtime routes; retain all materials, revisions and student histories.\n'+rollback)
    return dict(material_rows_maximum=len(docs)+10, scoped_policy_entries=5, prechecks=len(checks),postchecks=len(post),production_writes=0)



if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--baseline-functions',type=Path,required=True);a=p.parse_args();print(sql_candidates(APP,a.baseline_functions))
