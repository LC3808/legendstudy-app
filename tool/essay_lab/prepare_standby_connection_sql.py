"""Prepare additive, digest-pinned whole-exam connections under Owner approval.

Does not execute SQL, reserve Credit, change readers, or replace active policies.
"""
import argparse
import json
from copy import deepcopy
from pathlib import Path

REGIME='essay-v1.3/policy/54412ff80de2f20a2d72b711f7b0798c29d680e82b4621ae56ec2b07479de6c6'


def prepare(root,manifest,assets,output,policy_name):
    if not policy_name.replace('_','').isalnum():raise ValueError('POLICY_NAME')
    read=lambda p:json.loads(p.read_text())
    packages=read(root/'packages.private.json');baseline=read(root/'baseline.private.json')
    rows={r['examId']:r for r in read(manifest)};assets={a['exam_id']:a for a in read(assets)}
    old={r['exam_id']:r for r in baseline['reviews']}
    if set(packages)&set(baseline['runtime']):raise ValueError('ACTIVE_EXAM_MUST_BE_PRESERVED')
    lit=lambda x:"'"+str(x).replace("'","''")+"'"
    js=lambda x:lit(json.dumps(x,ensure_ascii=False,separators=(',',':')))+'::jsonb'
    expected={e:sorted(q['question_id'] for q in p['questions']) for e,p in packages.items()}
    docs={d['sha256']:d for e in packages for d in rows[e]['documents']}
    pdfs=sorted({assets[e]['sha256']+'.pdf' for e in packages})
    ids=','.join(lit(e)+'::uuid' for e in packages)
    coverage=f"not exists(select 1 from jsonb_each({js(expected)}) e where (select coalesce(jsonb_agg(id::text order by id::text),'[]'::jsonb) from public.essay_questions where essay_exam_id=e.key::uuid)<>e.value)"
    preserved=f"not exists(select 1 from jsonb_each({js(baseline['runtime'])}) p where essay_exam_private.runtime_policy(p.key::uuid) is distinct from p.value)"
    checks=[('whole_question_sets',coverage),('existing_runtime_preserved',preserved),('candidate_runtime_absent',f'not exists(select 1 from unnest(array[{ids}]) e where essay_exam_private.runtime_policy(e) is not null)'),('no_active_candidate_runs',f"not exists(select 1 from essay_exam_private.runs where exam_id in ({ids}) and state not in ('completed','failed'))"),('private_bucket',"exists(select 1 from storage.buckets where id='essay-material-originals' and not public)"),('all_objects_present',f"not exists(select 1 from jsonb_array_elements_text({js(sorted(set(pdfs)|{h+'.pdf' for h in docs}))}) x where not exists(select 1 from storage.objects o where o.bucket_id='essay-material-originals' and o.name=x))"),('policy_absent',f"not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(policy_name)})")]
    for f in baseline['functions']:
        checks.append(('function_'+str(len(checks)),f"md5(pg_get_functiondef({lit(f['signature'])}::regprocedure))={lit(f['md5'])}"))
    for e in packages:
        if e in old:
            r=old[e];condition=f"exists(select 1 from essay_material_private.reviews where exam_id={lit(e)} and revision={r['revision']} and md5(body::text)={lit(r['body_md5'])})"
        else:condition=f"not exists(select 1 from essay_material_private.reviews where exam_id={lit(e)})"
        checks.append(('review_'+str(len(checks)),condition))
    checks.append(('document_metadata_compatible',f"not exists(select 1 from jsonb_each({js(docs)}) d join essay_material_private.documents x on x.sha256=d.key where x.page_count<>(d.value->>'page_count')::int)"))
    output.mkdir(parents=True,exist_ok=True)
    select=lambda cs:'select '+',\n'.join(f'({v}) as {k}' for k,v in cs)+';\n'
    (output/'precheck.sql').write_text(select(checks))
    sql="-- Owner continuous STANDBY approval, 2026-10-25. Additive exact exam scope.\nbegin;set local lock_timeout='5s';set local statement_timeout='60s';select pg_advisory_xact_lock(4925261025);\ndo $apply$ declare p jsonb;b jsonb;r essay_material_private.reviews;rev int;definition text;clause text;begin\n"
    sql+='if not ('+' and '.join('('+c+')' for _,c in checks)+") then raise exception 'STANDBY_BASELINE_CHANGED';end if;\n"
    sql+=f'perform 1 from public.essay_exams where id in ({ids}) order by id for update;\n'
    for h,d in docs.items():
        resource=lit(d['resource_id'])+'::uuid' if d['resource_id'] else 'null'
        sql+=f"insert into essay_material_private.documents(sha256,resource_id,title,page_count,object_key) values({lit(h)},{resource},{lit(d['title'])},{d['page_count']},{lit(h+'.pdf')}) on conflict(sha256) do nothing;\n"
    sql+="definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for e,package in packages.items():
        p=deepcopy(package);p.pop('package_digest',None)
        revision=old[e]['revision']+1 if e in old else 1
        p['package_version']=revision
        sql+=f'p:={js(p)};\n'
        sql+="p:=p||jsonb_build_object('package_digest',encode(sha256(convert_to(p::text,'UTF8')),'hex'));\n"
        sql+=f"select * into r from essay_material_private.reviews where exam_id={lit(e)} for update;rev:={revision};\n"
        sql+="b:=coalesce(r.body,'{}'::jsonb)||jsonb_build_object('package',p,'runtimeApproval',jsonb_build_object('status','APPROVED','revision',rev,'authority','Owner continuous STANDBY approval 2026-10-25','question_ids',(select jsonb_agg(q->'question_id' order by q->>'question_id') from jsonb_array_elements(p->'questions') q)));\n"
        sql+="b:=b||jsonb_build_object('documents',(select jsonb_agg(distinct v order by v) from (select jsonb_array_elements_text(coalesce(b->'documents','[]'::jsonb)) v union select key from jsonb_each(p->'rights_status')) d));\n"
        if e in old:
            sql+=f"insert into essay_material_private.revisions(exam_id,revision,state,body,reviewer) values({lit(e)},rev,r.state,b,r.reviewer);update essay_material_private.reviews set revision=rev,body=b,updated_at=now() where exam_id={lit(e)};\n"
        else:
            sql+=f"insert into essay_material_private.reviews(exam_id,revision,state,body,approval_requested) values({lit(e)},rev,'NEEDS_REVIEW',b,false);insert into essay_material_private.revisions(exam_id,revision,state,body) values({lit(e)},rev,'NEEDS_REVIEW',b);\n"
        evaluation_type='business' if any(q.get('evaluation_engine')=='math' for q in package['questions']) else 'humanities'
        sql+=f"clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(e)},jsonb_build_object('regime',{lit(REGIME)},'package_digest',p->>'package_digest','evaluation_type',{lit(evaluation_type)})::text);\n"
        sql+="if position('else null::jsonb end' in definition)=0 then raise exception 'POLICY_FORMAT_CHANGED';end if;definition:=replace(definition,'else null::jsonb end',clause||'else null::jsonb end');\n"
    sql+='execute definition;end $apply$;\n'
    sql+=f"create policy {policy_name} on storage.objects for select to authenticated using ((select public.account_service_allowed()) and bucket_id='essay-material-originals' and name=any(array[{','.join(lit(x) for x in pdfs)}]::text[]));\ncommit;\n"
    (output/'apply.private.sql').write_text(sql)
    reader=next(f for f in baseline['functions'] if 'runtime_package' in f['signature'])
    post=[('whole_question_sets',coverage),('existing_runtime_preserved',preserved),('packages_readable',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select jsonb_agg(q->>'question_id' order by q->>'question_id') from jsonb_array_elements(public.essay_material_runtime_package(e.key::uuid,essay_exam_private.runtime_policy(e.key::uuid)->>'package_digest')->'questions') q) is distinct from e.value)"),('reader_unchanged',f"md5(pg_get_functiondef({lit(reader['signature'])}::regprocedure))={lit(reader['md5'])}"),('exact_binding',f"(select bool_and(essay_exam_private.runtime_policy(e)->>'regime'={lit(REGIME)}) from unnest(array[{ids}]) e)"),('authenticated_select_only',f"exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(policy_name)} and cmd='SELECT' and roles=array['authenticated']::name[])"),('private_bucket',checks[4][1])]
    (output/'postcheck.sql').write_text(select(post))
    rollback="-- Scoped disable only: preserve revisions and all student records.\nbegin;select pg_advisory_xact_lock(4925261025);do $rollback$ declare definition text;clause text;p jsonb;begin definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
    for e in packages:
        rollback+=f"p:=essay_exam_private.runtime_policy({lit(e)});if p is not null then if p->>'regime'<>{lit(REGIME)} or p->>'package_digest' is distinct from (select body->'package'->>'package_digest' from essay_material_private.reviews where exam_id={lit(e)}) then raise exception 'ROLLBACK_SCOPE_CHANGED';end if;clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(e)},p::text);if position(clause in definition)=0 then raise exception 'ROLLBACK_FORMAT_CHANGED';end if;definition:=replace(definition,clause,' ');end if;\n"
    rollback+=f'execute definition;end $rollback$;drop policy if exists {policy_name} on storage.objects;commit;\n'
    (output/'rollback.sql').write_text(rollback)
    (output/'manifest.json').write_text(json.dumps(dict(exams=[dict(exam_id=e,name=rows[e]['name'],questions=expected[e],revision=old[e]['revision']+1 if e in old else 1,student_pdf=assets[e]['sha256']) for e in packages],policy=policy_name,provider_calls=0,production_applied=False),ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(dict(exams=len(packages),questions=sum(map(len,expected.values())),prechecks=len(checks),postchecks=len(post))))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('manifest',type=Path);p.add_argument('assets',type=Path);p.add_argument('output',type=Path);p.add_argument('--policy-name',required=True);a=p.parse_args();prepare(a.root,a.manifest,a.assets,a.output,a.policy_name)
