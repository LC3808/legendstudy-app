"""Generate a scoped, guarded candidate; never connects to Production.

Input root holds private reviewed packages and read-only function/review snapshots.
Execution still requires Owner approval; publication requires subsequent runtime QA.
"""
import argparse
import json
from copy import deepcopy
from pathlib import Path


def generate(root):
    read = lambda p: json.loads(p.read_text())
    packages = read(root / 'packages.private.json')
    reviews = read(root.parent / 'expansion-live-reviews.private.json')
    functions = read(root / 'functions.private.json')
    assert set(packages) == {r['exam_id'] for r in reviews}
    assert all(r['revision'] == 1 and 'package' not in r['body'] for r in reviews)
    out = root / 'owner-sql'
    out.mkdir(exist_ok=True)
    lit = lambda x: "'" + str(x).replace("'", "''") + "'"
    js = lambda x: lit(json.dumps(x, ensure_ascii=False, separators=(',', ':'))) + '::jsonb'
    ids = ','.join(lit(x) + '::uuid' for x in packages)
    expected = {e: sorted(q['question_id'] for q in p['questions']) for e, p in packages.items()}
    checks = []
    for f in functions:
        signature = 'essay_exam_private.runtime_policy(uuid)' if f['name'] == 'runtime_policy' else 'public.essay_material_runtime_package(uuid,text)'
        checks.append((f['name'] + '_baseline', f'md5(pg_get_functiondef({lit(signature)}::regprocedure))={lit(f["md5"])}'))
    for i, row in enumerate(reviews):
        eid = row['exam_id']
        hashes = {m['sourceHash'] for q in packages[eid]['questions'] for m in q['source_page_references']}
        assert hashes <= set(row['body']['documents'])
        checks.append((f'review_{i+1}_baseline', f"exists(select 1 from essay_material_private.reviews where exam_id={lit(eid)} and revision=1 and md5(body::text)={lit(row['body_md5'])})"))
    coverage = f"not exists(select 1 from jsonb_each({js(expected)}) e where (select coalesce(jsonb_agg(id::text order by id::text),'[]'::jsonb) from public.essay_questions where essay_exam_id=e.key::uuid)<>e.value)"
    checks += [('whole_question_sets', coverage),
               ('no_existing_runtime', f'not exists(select 1 from unnest(array[{ids}]) e where essay_exam_private.runtime_policy(e) is not null)'),
               ('no_active_runs', f"not exists(select 1 from essay_exam_private.runs where exam_id in ({ids}) and state not in ('completed','failed'))")]
    pdf = '7acf8c7c396ac1ad8b05f071592c184c37c32bd2ece9f2f697346733845c5cb4.pdf'
    policy = 'essay_group1a_skku2027_language_read'
    checks += [('existing_private_pdf', f"exists(select 1 from storage.objects o join storage.buckets b on b.id=o.bucket_id where b.id='essay-material-originals' and not b.public and o.name={lit(pdf)})"),
               ('new_storage_policy_absent', f"not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(policy)})")]
    select_checks = lambda rows: 'select ' + ',\n'.join(f'({expr}) as {name}' for name, expr in rows) + ';\n'
    (out / 'precheck.sql').write_text(select_checks(checks))
    regime = 'essay-v1.3/policy/54412ff80de2f20a2d72b711f7b0798c29d680e82b4621ae56ec2b07479de6c6'
    sql = "-- Candidate only. Owner approval required before Production execution.\nbegin;\nset local lock_timeout='5s';set local statement_timeout='60s';\nselect pg_advisory_xact_lock(4925261025);\ndo $apply$ declare r essay_material_private.reviews;p jsonb;b jsonb;definition text;clause text;begin\n"
    sql += 'if not (' + ' and '.join(f'({c})' for _, c in checks) + ") then raise exception 'GROUP1A_BASELINE_CHANGED';end if;\n"
    sql += f'perform 1 from essay_material_private.reviews where exam_id in ({ids}) order by exam_id for update;\n'
    sql += "definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    post = []
    for i, row in enumerate(reviews):
        eid = row['exam_id']
        p = deepcopy(packages[eid]);p.pop('package_digest', None)
        sql += f"select * into strict r from essay_material_private.reviews where exam_id={lit(eid)};\n"
        sql += f"if md5(r.body::text)<>{lit(row['body_md5'])} then raise exception 'GROUP1A_REVIEW_CHANGED';end if;\n"
        sql += f'p:={js(p)};\n'
        sql += "p:=p||jsonb_build_object('package_digest',encode(sha256(convert_to(p::text,'UTF8')),'hex'));\n"
        sql += "b:=r.body||jsonb_build_object('package',p,'runtimeApproval',jsonb_build_object('status','APPROVED','revision',2,'authority','Owner approved 1-A whole-exam SQL scope','question_ids',(select jsonb_agg(q->'question_id' order by q->>'question_id') from jsonb_array_elements(p->'questions') q)));\n"
        sql += "insert into essay_material_private.revisions(exam_id,revision,state,body,reviewer) values(r.exam_id,2,r.state,b,r.reviewer);update essay_material_private.reviews set revision=2,body=b,updated_at=now() where exam_id=r.exam_id;\n"
        # New cases only. Every pre-existing case remains byte-for-byte unchanged.
        sql += f"clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},jsonb_build_object('regime',{lit(regime)},'package_digest',p->>'package_digest','evaluation_type','humanities')::text);\n"
        sql += "if position('else null::jsonb end' in definition)=0 then raise exception 'POLICY_FORMAT_CHANGED';end if;definition:=replace(definition,'else null::jsonb end',clause||'else null::jsonb end');\n"
        post += [(f'exam_{i+1}_all_readable', f"jsonb_array_length(public.essay_material_runtime_package({lit(eid)},essay_exam_private.runtime_policy({lit(eid)})->>'package_digest')->'questions')={len(p['questions'])}"),
                 (f'exam_{i+1}_metadata_preserved', f"(select revision=2 and state={lit(row['state'])} and body-'package'-'runtimeApproval'={js(row['body'])} from essay_material_private.reviews where exam_id={lit(eid)})"),
                 (f'exam_{i+1}_binding_preserved', f"essay_exam_private.runtime_policy({lit(eid)})->>'regime'={lit(regime)}")]
    sql += 'execute definition;end $apply$;\n'
    sql += f"create policy {policy} on storage.objects for select to authenticated using ((select public.account_service_allowed()) and bucket_id='essay-material-originals' and name={lit(pdf)});\ncommit;\n"
    (out / 'apply.private.sql').write_text(sql)
    reader = next(f for f in functions if f['name'] == 'essay_material_runtime_package')
    post += [('whole_question_sets', coverage), ('reader_unchanged', f"md5(pg_get_functiondef('public.essay_material_runtime_package(uuid,text)'::regprocedure))={lit(reader['md5'])}"),
             ('exact_storage_select', f"exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(policy)} and cmd='SELECT' and roles=array['authenticated']::name[] and qual like '%'||{lit(pdf)}||'%')")]
    (out / 'postcheck.sql').write_text(select_checks(post))
    # Remove only the exact new clauses. Keep reviews, historical packages/results.
    rollback = "begin;set local lock_timeout='5s';set local statement_timeout='30s';select pg_advisory_xact_lock(4925261025);\ndo $rollback$ declare definition text;clause text;p jsonb;begin definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for eid in packages:
        rollback += f"p:=essay_exam_private.runtime_policy({lit(eid)});if p is not null then if p->>'regime'<>{lit(regime)} or p->>'package_digest' is distinct from (select body->'package'->>'package_digest' from essay_material_private.revisions where exam_id={lit(eid)} and revision=2) then raise exception 'ROLLBACK_SCOPE_CHANGED';end if;clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},p::text);if position(clause in definition)=0 then raise exception 'ROLLBACK_FORMAT_CHANGED';end if;definition:=replace(definition,clause,'');end if;\n"
    rollback += f'execute definition;end $rollback$;drop policy if exists {policy} on storage.objects;commit;\n'
    (out / 'rollback.sql').write_text(rollback)
    return {'exams': len(packages), 'questions': sum(len(p['questions']) for p in packages.values()), 'prechecks': len(checks), 'postchecks': len(post), 'production_executed': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__);parser.add_argument('root', type=Path)
    print(json.dumps(generate(parser.parse_args().root)))
