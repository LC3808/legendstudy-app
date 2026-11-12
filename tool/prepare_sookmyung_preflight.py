"""Prepare the approved-review scope; no database connector or remote mutation."""
import copy, hashlib, json
from pathlib import Path
from essay_lab.task20_priority_packages import registration_sql, literal
from essay_lab.natural_candidate_sql import STATE_TABLES
from essay_lab.four_university_connection import ORDER
R=Path(__file__).resolve().parents[1]
BASE=R/'supabase/candidates/natural_expansion_20261111/four-university'
OUT=R/'supabase/candidates/natural_expansion_20261111/production-preflight'
PRIVATE=R/'.local/natural-production-preflight-20261112'

def digest(b):return hashlib.sha256(b).hexdigest()
def dump(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def csv(ids):return ','.join(map(literal,ids))
def fingerprint(table,where='true',key='id'):
 return f"select {literal(table)} name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by {key}),'')) digest from {table} x where {where}"

def build(university=None, output=None, private=None, production_functions=None):
 # Single-university rollout reuses the reviewed data/guards; it never activates content.
 assert university in ('숙명여자대학교',), 'Only the current university is authorized for preparation'
 evidence=R/'supabase/candidates/natural_expansion_20261111/production-preflight'
 OUT=output or evidence
 PRIVATE=private or R/'.local/natural-production-preflight-20261112'
 if university:assert output and private and OUT!=evidence and PRIVATE!=R/'.local/natural-production-preflight-20261112'
 assert '.local' in PRIVATE.resolve().parts
 OUT.mkdir(parents=True,exist_ok=True);PRIVATE.mkdir(parents=True,exist_ok=True)
 review=json.loads((BASE/'question-review.json').read_text())['questions']
 assert len(review)==81
 plan=json.loads((R/'.local/natural-tech-20261112/sookmyung/source-plan.json').read_text())
 pdf=json.loads((R/'.local/natural-tech-20261112/sookmyung/web-pdf-existing-reuse.json').read_text())
 for e in plan['exams']:
  for q in e['questions']:
   review.append(dict(university='숙명여자대학교',university_id=e['university_id'],exam_id=e['exam_id'],registry_id=q['question_id'],registry_key=q['question_key'],admission_year=e['admission_year'],track=e['field_or_division'],question_label=q['label'],display_order=q['display_order'],state='SERVICE READY (LOCAL)',operating_math_bindings=[],student_pdf=next(r for r in pdf if r['questionId']==q['question_id'])))
 assert len(review)==len({q['registry_id'] for q in review})==125
 (OUT/'registry-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n')
 roots={'한국항공대학교':R/'.local/natural-connection-20261111/kau','건국대학교':R/'.local/four-university-20261111/konkuk','경희대학교':R/'.local/four-university-20261111/kyunghee','성균관대학교':R/'.local/four-university-20261111/sungkyunkwan'}
 roots['숙명여자대학교']=R/'.local/natural-tech-20261112/sookmyung'
 selected=[q for q in review if q['state'] in ('SERVICE READY (LOCAL)','DATA READY')]
 assert len(selected)==97
 if university:selected=[q for q in selected if q['university']==university]
 expected={'숙명여자대학교':44}[university]
 assert len(selected)==expected
 if OUT!=evidence:(OUT/'production-functions.json').write_bytes((production_functions or evidence/'production-functions.json').read_bytes())
 packages=[];worker=[];matrix=[]
 for q in review:
  state=q['state'];scope='EXISTING_PRESERVE' if state=='SERVICE READY (OPERATING PRESERVED)' else 'HOLD_EXCLUDED' if state=='HOLD' else 'NOT_READY_EXCLUDED' if state=='NOT READY' else 'NEW_DRAFT_ONLY'
  if scope=='NEW_DRAFT_ONLY' and university and q['university']!=university:scope='DEFERRED_UNIVERSITY'
  matrix.append({k:q[k] for k in ['university','exam_id','registry_id','registry_key','admission_year','track','question_label','state']}|dict(application_scope=scope,pdf_approval_pending=q.get('student_pdf',{}).get('studentDisplay')=='PENDING',kyunghee_partial=state=='DATA READY',partial_exam=scope=='NEW_DRAFT_ONLY' and sum(x['exam_id']==q['exam_id'] for x in selected)<sum(x['exam_id']==q['exam_id'] for x in review),student_pdf=q.get('student_pdf'),math_connection=q.get('math_connection'),operating_math_bindings=q['operating_math_bindings']))
  if scope!='NEW_DRAFT_ONLY':continue
  root=roots[q['university']];qid=q['registry_id'];raw=(root/(qid+'.package.private.json')).read_bytes();p=json.loads(raw)
  manifest=json.loads((R/'supabase/candidates/natural_tech_ready_20261112/sookmyung/manifest.json').read_text())
  assert digest(raw)==next(x['package_sha256'] for x in manifest['packages'] if x['question_id']==qid)
  assert p['state']=='DRAFT' and p['publication_allowed'] is False
  (PRIVATE/(qid+'.package.private.json')).write_bytes(raw);packages.append(p)
  w=json.loads((root/(qid+'.worker.private.json')).read_text());(PRIVATE/(qid+'.worker.private.json')).write_text(json.dumps(w)+'\n')
  values=','.join(literal(w[k])+('::jsonb' if k.endswith('_text') else '') for k in ['question_id','exam_id','manifest_text','images_text','sha256'])
  worker.append('insert into math_private.task20_hanyang_source_pages(question_id,exam_id,manifest,images,content_sha256) values ('+values+');')
 ids={t:[r['id'] for p in packages for r in p['existing_schema_rows'][t]] for t in packages[0]['existing_schema_rows']}
 assert all(len(v)==len(set(v)) for v in ids.values())
 qids=[q['registry_id'] for q in selected]
 functions=json.loads((OUT/'production-functions.json').read_text())
 funcs=[dict(signature=f['schema']+'.'+f['name']+'('+({'release_catalog':'uuid','require_active':'uuid[]','resolve_profile':'uuid','math_catalog':'integer','math_input':'jsonb','math_submit_attempt':'jsonb'}[f['name']])+')',md5=hashlib.md5(f['definition'].encode()).hexdigest()) for f in functions]
 funcs.append(dict(signature='math_private.hanyang_worker_references(jsonb)',md5='54acd2a1914f360e6ecd62e39acc8222'))
 checks=[]
 for f in funcs:checks.append((f['signature'],f"md5(pg_get_functiondef({literal(f['signature'])}::regprocedure))={literal(f['md5'])}"))
 for t in ['public.'+t for t in ids]+['math_private.task20_hanyang_source_pages']:
  checks.append((t+' ACL/RLS',f"(select relrowsecurity from pg_class where oid={literal(t)}::regclass) and not has_table_privilege('anon',{literal(t)},'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') and not has_table_privilege('authenticated',{literal(t)},'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')"))
 checks.append(('private Worker execute',"not has_function_privilege('anon','math_private.hanyang_worker_references(jsonb)','EXECUTE') and not has_function_privilege('authenticated','math_private.hanyang_worker_references(jsonb)','EXECUTE')"))
 for q in review:
  checks.append((q['registry_id']+' Registry',f"exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id={literal(q['registry_id'])} and q.essay_exam_id={literal(q['exam_id'])} and e.university_id={literal(q['university_id'])} and q.question_key={literal(q['registry_key'])} and q.display_order={q['display_order']} and q.is_published=false and e.is_active=false)"))
  if q['state']=='SERVICE READY (OPERATING PRESERVED)':
   leaf=q['operating_math_bindings'][0]['leaf_id']
   checks.append((q['registry_id']+' existing ACTIVE',f"exists(select 1 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id where l.id={literal(leaf)} and s.essay_exam_id={literal(q['exam_id'])} and p.state='ACTIVE' and s.state='ACTIVE' and (l.essay_question_id={literal(q['registry_id'])} or (l.id='3bab07d3-c047-53c2-89ad-9fa20ec7b3f3' and l.essay_question_id is null)))"))
 checks.append(('new leaves outside release allowlist',"not exists(select 1 from unnest(array["+csv([p['ids']['leaf'] for p in packages])+"]) v where position(v in pg_get_functiondef('math_private.release_catalog(uuid)'::regprocedure))>0)"))
 fresh=[(t+' candidate absent',f'not exists(select 1 from public.{t} where id in ({csv(v)}))') for t,v in ids.items()]
 fresh += [('candidate Worker absent',f'not exists(select 1 from math_private.task20_hanyang_source_pages where question_id in ({csv(qids)}))'),('candidate foreign binding absent',f'not exists(select 1 from public.math_subproblems where essay_question_id in ({csv(qids)}))')]
 def query(cs):return '\nunion all\n'.join('select '+literal(name)+' check_name,('+expr+') passed' for name,expr in cs)
 def assertion(cs,label):return 'do $check$ declare failed text;begin select string_agg(check_name,\', \') into failed from ('+query(cs)+") checks where passed is distinct from true;if failed is not null then raise exception '"+label+" %',failed;end if;end $check$;\n"
 preserved=[fingerprint('public.'+t,f'id not in ({csv(v)})') for t,v in ids.items()]
 preserved += [fingerprint('math_private.task20_hanyang_source_pages',f'question_id not in ({csv(qids)})','question_id')]
 preserved += [fingerprint('public.'+t) for t in ['universities','essay_exams','essay_questions','essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']]
 preserved += ["select 'function definitions/owners/ACL' name,count(*) n,md5(coalesce(string_agg(md5(pg_get_functiondef(p.oid)||p.proowner::text||coalesce(p.proacl::text,'')),'' order by p.oid),'')) digest from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.prokind='f' and n.nspname in ('public','math_private','essay_private','account_private')",
 "select 'RLS policies' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' order by schemaname,tablename,policyname),'')) digest from pg_policies p",
 "select 'table owners/RLS/ACL' name,count(*) n,md5(coalesce(string_agg(md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text),'' order by c.oid),'')) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','account_private') and c.relkind in ('r','p')"]
 snapshot='\nunion all\n'.join(preserved)
 compare="do $preserve$ begin if exists(select 1 from ("+snapshot+") now_rows full join _approval_before old_rows using(name) where now_rows.n is distinct from old_rows.n or now_rows.digest is distinct from old_rows.digest) then raise exception 'PRESERVATION_DRIFT';end if;end $preserve$;\n"
 header="-- REVIEW ONLY: Stage 1 DRAFT insert, no activation/publication. Owner approval required.\nbegin isolation level repeatable read;\nset local lock_timeout='5s';\nset local statement_timeout='120s';\nselect pg_advisory_xact_lock(20261112,53);\n"
 applied=[(t+' exact count',f'(select count(*) from public.{t} where id in ({csv(v)}))={len(v)}'+(f" and not exists(select 1 from public.{t} where id in ({csv(v)}) and state<>'DRAFT')" if t in STATE_TABLES else '')) for t,v in ids.items()]
 applied.append(('Worker exact count',f'(select count(*) from math_private.task20_hanyang_source_pages where question_id in ({csv(qids)}))={expected}'))
 for p in packages:
  w=json.loads((PRIVATE/(p['essay_question_id']+'.worker.private.json')).read_text())
  applied.append((p['essay_question_id']+' Worker identity/digest',f"exists(select 1 from math_private.task20_hanyang_source_pages where question_id={literal(w['question_id'])} and exam_id={literal(w['exam_id'])} and content_sha256={literal(w['sha256'])})"))
 ordered=copy.deepcopy(packages)
 for p in ordered:p['existing_schema_rows']={t:p['existing_schema_rows'][t] for t in ORDER}
 reg=registration_sql(ordered).strip();assert reg.startswith('begin;') and reg.endswith('commit;')
 apply=header+assertion(checks+fresh,'PREFLIGHT_FAILED')+'create temp table _approval_before on commit drop as '+snapshot+';\n'+reg[6:-7]+'\n'+'\n'.join(worker)+'\n'+assertion(checks+applied,'POSTCHECK_FAILED')+compare+'commit;\n'
 (PRIVATE/'apply-draft.private.sql').write_text(apply)
 (OUT/'preflight.sql').write_text('begin read only;\n'+query(checks+fresh)+';\n'+snapshot+';\ncommit;\n')
 (OUT/'verify.sql').write_text('begin read only;\n'+query(checks+applied)+';\n'+snapshot+';\ncommit;\n')
 rollback_checks=[(t+' stage1 DRAFT or RETIRED',f'(select count(*) from public.{t} where id in ({csv(ids[t])}))={len(ids[t])} and not exists(select 1 from public.{t} where id in ({csv(ids[t])}) and state not in (\'DRAFT\',\'RETIRED\'))') for t in STATE_TABLES]
 rollback=header.replace('Stage 1 DRAFT insert','Stage 1 DRAFT retirement')+assertion(rollback_checks,'ROLLBACK_SCOPE_CHANGED')+'create temp table _approval_before on commit drop as '+snapshot+';\n'
 for t in STATE_TABLES:rollback+=f"update public.{t} set state='RETIRED' where id in ({csv(ids[t])}) and state='DRAFT';\n"
 rollback+=compare+'commit;\n';(OUT/'rollback-retire.sql').write_text(rollback)
 (OUT/'verify-retired.sql').write_text((OUT/'verify.sql').read_text().replace("state<>'DRAFT'","state<>'RETIRED'"))
 dump(OUT/'scope.json',dict(base_commit='536a2fc22c5fa763d31fa59fe239460cef93d794',questions=matrix,counts=dict(review=125,candidates=102,new_draft=expected,deferred_university=97-expected,existing_preserve=7,hold=5,not_ready=16,pdf_pending_subset=sum(q['pdf_approval_pending'] for q in matrix if q['application_scope']=='NEW_DRAFT_ONLY'),partial_exam_subset=sum(q['partial_exam'] for q in matrix),kyunghee_partial_subset=sum(q['kyunghee_partial'] for q in matrix if q['application_scope']=='NEW_DRAFT_ONLY'),duplicate_excluded=0),selected_exams=len({q['exam_id'] for q in selected}),rows={t:len(v) for t,v in ids.items()},worker_rows=expected,functions=funcs,production_writes=0,publication_allowed=False))
 dump(OUT/'sql-receipt.json',dict(private_apply=str(PRIVATE/'apply-draft.private.sql'),sha256=digest(apply.encode()),bytes=len(apply.encode()),files={f:digest((OUT/f).read_bytes()) for f in ['preflight.sql','verify.sql','rollback-retire.sql','verify-retired.sql']},source_metadata_sha256={str(f.relative_to(R)):digest(f.read_bytes()) for f in [BASE/'question-review.json',BASE/'leaf-contract-candidate.json',BASE/'existing-pdf-reuse-verification.json']},candidate_packages={p['essay_question_id']:digest((PRIVATE/(p['essay_question_id']+'.package.private.json')).read_bytes()) for p in packages}))
 print(json.dumps(dict(selected=len(selected),exams=len({q['exam_id'] for q in selected}),rows={t:len(v) for t,v in ids.items()},worker_rows=expected,apply_bytes=len(apply.encode()))))
if __name__=='__main__':build()
