"""Prepare exact existing Central exam connections; no network or Production execution."""
import argparse,json
from pathlib import Path
from copy import deepcopy

REGIME='essay-v1.3/policy/54412ff80de2f20a2d72b711f7b0798c29d680e82b4621ae56ec2b07479de6c6'
POLICY='essay_group1a_central_humanities_question_read'
def generate(root):
 read=lambda n:json.loads((root/n).read_text())
 packages=read('central-packages.private.json');baseline=read('central-baseline.private.json')
 assert not baseline['central_reviews']
 locators=json.loads((root.parent/'central-whole-exam-source-locators.json').read_text())
 rows=[r for r in locators if r['exam_id'] in packages];assert len(rows)==len(packages)==10
 docs={d['source_hash']:dict(d,exam_id=r['exam_id'],title=f"중앙 {r['year']} {r['kind']} {r['track']} {d['role']}") for r in rows for d in r['documents']}
 lit=lambda x:"'"+str(x).replace("'","''")+"'"
 js=lambda x:lit(json.dumps(x,ensure_ascii=False,separators=(',',':')))+'::jsonb'
 ids=','.join(lit(x)+'::uuid' for x in packages)
 expected={e:sorted(q['question_id'] for q in p['questions']) for e,p in packages.items()}
 coverage=f"not exists(select 1 from jsonb_each({js(expected)}) e where (select coalesce(jsonb_agg(id::text order by id::text),'[]'::jsonb) from public.essay_questions where essay_exam_id=e.key::uuid)<>e.value)"
 checks=[]
 for f in baseline['functions']:
  sig='essay_exam_private.runtime_policy(uuid)' if f['name']=='runtime_policy' else 'public.essay_material_runtime_package(uuid,text)'
  checks.append((f['name']+'_baseline',f'md5(pg_get_functiondef({lit(sig)}::regprocedure))={lit(f["md5"])}'))
 checks += [('whole_question_sets',coverage),('no_existing_reviews',f'not exists(select 1 from essay_material_private.reviews where exam_id in ({ids}))'),('no_existing_runtime',f'not exists(select 1 from unnest(array[{ids}]) e where essay_exam_private.runtime_policy(e) is not null)'),('no_active_runs',f"not exists(select 1 from essay_exam_private.runs where exam_id in ({ids}) and state not in ('completed','failed'))"),('private_bucket',"exists(select 1 from storage.buckets where id='essay-material-originals' and not public)"),('all_existing_resources',f"not exists(select 1 from jsonb_each({js(docs)}) d where not exists(select 1 from public.resources r where r.id=(d.value->>'resource_id')::uuid))"),('all_pdf_objects',f"not exists(select 1 from jsonb_each({js(docs)}) d where not exists(select 1 from storage.objects o where o.bucket_id='essay-material-originals' and o.name=d.key||'.pdf'))"),('document_metadata_compatible',f"not exists(select 1 from jsonb_each({js(docs)}) d join essay_material_private.documents x on x.sha256=d.key where x.page_count<>(d.value->>'page_count')::int or x.resource_id is distinct from (d.value->>'resource_id')::uuid)"),('new_policy_absent',f"not exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(POLICY)})")]
 out=root/'central-owner-sql';out.mkdir(exist_ok=True)
 select=lambda rows:'select '+',\n'.join(f'({v}) as {k}' for k,v in rows)+';\n'
 (out/'precheck.sql').write_text(select(checks))
 sql="-- Candidate: requires Owner approval including exact question-PDF SELECT policy.\nbegin;set local lock_timeout='5s';set local statement_timeout='60s';select pg_advisory_xact_lock(4925261025);\ndo $apply$ declare p jsonb;b jsonb;definition text;clause text;begin\n"
 sql+='if not ('+' and '.join('('+v+')' for _,v in checks)+") then raise exception 'CENTRAL_BASELINE_CHANGED';end if;\n"
 sql+=f'perform 1 from public.essay_exams where id in ({ids}) order by id for update;\n'
 for h,d in docs.items():
  sql+=f"insert into essay_material_private.documents(sha256,resource_id,title,page_count,object_key) values({lit(h)},{lit(d['resource_id'])},{lit(d['title'])},{d['page_count']},{lit(h+'.pdf')}) on conflict(sha256) do nothing;\n"
 sql+="definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
 for eid,original in packages.items():
  p=deepcopy(original);p.pop('package_digest',None)
  for rights in p['rights_status'].values():rights['purpose']='Owner-approved exact-exam official evidence connection; existing resource IDs preserved'
  sql+=f'p:={js(p)};\n'
  sql+="p:=p||jsonb_build_object('package_digest',encode(sha256(convert_to(p::text,'UTF8')),'hex'));\n"
  sql+="b:=jsonb_build_object('documents',(select jsonb_agg(key order by key) from jsonb_each(p->'rights_status')),'mappings',(select jsonb_agg(m) from jsonb_array_elements(p->'questions') q cross join lateral jsonb_array_elements(q->'source_page_references') m),'checks','{}'::jsonb,'package',p,'runtimeApproval',jsonb_build_object('status','APPROVED','revision',1,'authority','Owner scoped Central whole-exam batch','question_ids',(select jsonb_agg(q->'question_id' order by q->>'question_id') from jsonb_array_elements(p->'questions') q)));\n"
  sql+=f"insert into essay_material_private.reviews(exam_id,revision,state,body,approval_requested) values({lit(eid)},1,'NEEDS_REVIEW',b,false);insert into essay_material_private.revisions(exam_id,revision,state,body) values({lit(eid)},1,'NEEDS_REVIEW',b);\n"
  sql+=f"clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},jsonb_build_object('regime',{lit(REGIME)},'package_digest',p->>'package_digest','evaluation_type','humanities')::text);\n"
  sql+="if position('else null::jsonb end' in definition)=0 then raise exception 'POLICY_FORMAT_CHANGED';end if;definition:=replace(definition,'else null::jsonb end',clause||'else null::jsonb end');\n"
 sql+='execute definition;end $apply$;\n'
 pdfs=sorted(h+'.pdf' for h,d in docs.items() if d['role']=='question')
 sql+=f"create policy {POLICY} on storage.objects for select to authenticated using ((select public.account_service_allowed()) and bucket_id='essay-material-originals' and name=any(array[{','.join(lit(x) for x in pdfs)}]::text[]));\ncommit;\n"
 (out/'apply.private.sql').write_text(sql)
 post=[('whole_question_sets',coverage),('all_ten_packages_readable',f"not exists(select 1 from jsonb_each({js(expected)}) e where (select jsonb_agg(q->>'question_id' order by q->>'question_id') from jsonb_array_elements(public.essay_material_runtime_package(e.key::uuid,essay_exam_private.runtime_policy(e.key::uuid)->>'package_digest')->'questions') q)<>e.value)"),('exact_bindings',f"(select count(*)=10 and bool_and(essay_exam_private.runtime_policy(e)->>'regime'={lit(REGIME)}) from unnest(array[{ids}]) e)"),('ten_initial_revisions',f"(select count(*)=10 and bool_and(revision=1) from essay_material_private.revisions where exam_id in ({ids}))"),('reader_unchanged',checks[1][1] if baseline['functions'][1]['name']=='essay_material_runtime_package' else checks[0][1]),('private_bucket',checks[6][1]),('documents_connected',f"not exists(select 1 from jsonb_each({js(docs)}) d where not exists(select 1 from essay_material_private.documents x where x.sha256=d.key and x.resource_id=(d.value->>'resource_id')::uuid and x.page_count=(d.value->>'page_count')::int))"),('question_select_only',f"exists(select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname={lit(POLICY)} and cmd='SELECT' and roles=array['authenticated']::name[])")]
 (out/'postcheck.sql').write_text(select(post))
 rollback="begin;set local lock_timeout='5s';select pg_advisory_xact_lock(4925261025);do $rollback$ declare definition text;clause text;p jsonb;begin definition:=pg_get_functiondef('essay_exam_private.runtime_policy(uuid)'::regprocedure);\n"
 for eid in packages:
  rollback+=f"p:=essay_exam_private.runtime_policy({lit(eid)});if p is not null then if p->>'regime'<>{lit(REGIME)} or p->>'package_digest' is distinct from (select body->'package'->>'package_digest' from essay_material_private.revisions where exam_id={lit(eid)} and revision=1) then raise exception 'ROLLBACK_SCOPE_CHANGED';end if;clause:=format(' when p_exam=%L::uuid then %L::jsonb ',{lit(eid)},p::text);if position(clause in definition)=0 then raise exception 'ROLLBACK_FORMAT_CHANGED';end if;definition:=replace(definition,clause,'');end if;\n"
 rollback+=f'execute definition;end $rollback$;drop policy if exists {POLICY} on storage.objects;commit;\n'
 (out/'rollback.sql').write_text(rollback)
 (out/'manifest.json').write_text(json.dumps({'exams':[dict(exam_id=r['exam_id'],year=r['year'],kind=r['kind'],track=r['track'],question_count=len(packages[r['exam_id']]['questions'])) for r in rows],'documents':docs,'question_pdf_objects':pdfs,'production_applied':False},ensure_ascii=False,indent=2))
 return dict(exams=len(packages),questions=sum(map(len,expected.values())),documents=len(docs),prechecks=len(checks),postchecks=len(post),production_applied=False)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('root',type=Path);print(json.dumps(generate(p.parse_args().root)))
