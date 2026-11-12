import json,pathlib,re,hashlib,sys
A=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(A/'tool'))
from essay_lab.task20_priority_packages import literal
P=A/'.local/soongsil-production-preflight-20261112'
O=A/'supabase/candidates/soongsil_public_20261112';O.mkdir(exist_ok=True)
if len(sys.argv)!=2:raise SystemExit('Usage: prepare_soongsil_public_release.py PRIVATE_LIVE_FUNCTIONS_JSON')
functions=json.loads(pathlib.Path(sys.argv[1]).read_text())
packages=[json.loads(p.read_text()) for p in sorted(P.glob('*.package.private.json'))];assert len(packages)==19
leaves=[p['ids']['leaf'] for p in packages];qs=[p['essay_question_id'] for p in packages]
def arr(ids):return 'array['+','.join(literal(x)+'::uuid' for x in ids)+']'
def guard(expr,msg):return "do $guard$ begin if not ("+expr+") then raise exception '"+msg+"';end if;end $guard$;"
records=[]
for f in functions:
 if f['proname'] not in ('evaluation_admission','release_catalog'):continue
 old=f['definition'];arrays=list(re.finditer(r"array\[(?:'[0-9a-f-]+'::uuid,?)+\]",old));assert len(arrays)==1
 a=arrays[0];before=re.findall(r"'([0-9a-f-]+)'::uuid",a.group());assert len(set(before))==257 and not set(leaves)&set(before)
 new=old[:a.start()]+arr(sorted(before+leaves))+old[a.end():]
 sig='math_private.'+f['proname']+('()' if f['proname']=='evaluation_admission' else '(uuid)')
 records.append(dict(signature=sig,before=old,after=new,before_md5=hashlib.md5(old.encode()).hexdigest(),after_md5=hashlib.md5(new.encode()).hexdigest()))
base=(A/'supabase/candidates/natural_tech_ready_20261112/soongsil-production-preflight/preflight.sql').read_text()
snapshot=base.split(';\n')[2]
assert snapshot.startswith("select 'public.math_")
snapshot=snapshot.replace("where p.prokind='f' and n.nspname", "where p.oid not in ('math_private.evaluation_admission()'::regprocedure,'math_private.release_catalog(uuid)'::regprocedure) and p.prokind='f' and n.nspname")
snapshot+="\nunion all\nselect 'changed functions identity/ACL' name,count(*) n,md5(string_agg(jsonb_build_array(p.oid,p.proowner,p.proacl)::text,'' order by p.oid)) digest from pg_proc p where p.oid in ('math_private.evaluation_admission()'::regprocedure,'math_private.release_catalog(uuid)'::regprocedure)"
compare=guard('not exists(select 1 from ('+snapshot+") n full join _publish_before b using(name) where n.n is distinct from b.n or n.digest is distinct from b.digest)",'PRESERVATION_DRIFT')
header="begin isolation level repeatable read;\nset local lock_timeout='5s';\nset local statement_timeout='120s';\nselect pg_advisory_xact_lock(20261112,53);\n"
apply=[header]+[guard('md5(pg_get_functiondef('+literal(r['signature'])+'::regprocedure))='+literal(r['before_md5']),'FUNCTION_DRIFT') for r in records]
apply+=['create temp table _publish_before on commit drop as '+snapshot+';',"create temp table _catalog_before on commit drop as select value row from jsonb_array_elements(math_private.release_catalog(null));"]
for p in packages:
 for t,rows in p['existing_schema_rows'].items():
  for row in rows:apply.append(guard('exists(select 1 from public.'+t+' where id='+literal(row['id'])+' and to_jsonb('+t+') @> '+literal(json.dumps(row,ensure_ascii=False))+'::jsonb)','PACKAGE_DRIFT'))
 w=json.loads((P/(p['essay_question_id']+'.worker.private.json')).read_text())
 apply.append(guard('exists(select 1 from math_private.task20_hanyang_source_pages where question_id='+literal(p['essay_question_id'])+' and exam_id='+literal(p['exam_id'])+' and content_sha256='+literal(w['sha256'])+')','WORKER_DRIFT'))
for t,key in [('math_problem_sets','set'),('math_problems','problem'),('math_evaluation_profiles','profile'),('math_canonical_solutions','solution')]:
 ids=[p['existing_schema_rows'][t][0]['id'] for p in packages];apply.append("update public."+t+" set state='ACTIVE' where id=any("+arr(ids)+") and state='DRAFT';")
apply += [r['after'].rstrip().rstrip(';')+';' for r in records]
checks=[]
for p in packages:
 leaf=literal(p['ids']['leaf']);qid=literal(p['essay_question_id']);eid=literal(p['exam_id'])
 checks.append((p['essay_question_id']+' public mapping',"(select count(*) from jsonb_array_elements(math_private.release_catalog("+eid+")) x where x->>'leaf_id'="+leaf+" and x->>'essay_question_id'="+qid+")=1"))
 checks.append((p['essay_question_id']+' profile',"(with candidates as(select ep.id,case ep.scope when 'LEAF' then 4 when 'PROBLEM' then 3 when 'EXAM' then 2 else 1 end rank from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id join public.math_problem_sets ps on ps.id=pr.problem_set_id join public.math_evaluation_profiles ep on ep.state='ACTIVE' and ep.response_format=l.response_format and (ep.leaf_id=l.id or ep.problem_id=l.problem_id or ep.essay_exam_id=ps.essay_exam_id or (ep.scope='COMMON_MATH_RUBRIC' and l.allow_common_rubric)) where l.id="+leaf+" and pr.state='ACTIVE' and ps.state='ACTIVE') select count(*)=1 and bool_and(id="+literal(p['existing_schema_rows']['math_evaluation_profiles'][0]['id'])+"::uuid) from candidates where rank=(select max(rank) from candidates))"))
 checks.append((p['essay_question_id']+' Worker evidence',"exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id="+leaf+" and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)"))
verify='\nunion all\n'.join('select '+literal(n)+' check_name,('+e+') passed' for n,e in checks)
apply.append(guard('not exists(select 1 from ('+verify+') c where passed is distinct from true)','RELEASE_POSTCHECK_FAILED'))
apply.append(guard("not exists(select row from _catalog_before except select value from jsonb_array_elements(math_private.release_catalog(null))) and jsonb_array_length(math_private.release_catalog(null))=(select count(*)+19 from _catalog_before)",'OLD_CATALOG_DRIFT'))
apply += [compare,'commit;']
rollback=[header]+[guard('md5(pg_get_functiondef('+literal(r['signature'])+'::regprocedure))='+literal(r['after_md5']),'ROLLBACK_FUNCTION_DRIFT') for r in records]+['create temp table _publish_before on commit drop as '+snapshot+';']+[r['before'].rstrip().rstrip(';')+';' for r in records]+[compare,'commit;']
(P/'activate-public.private.sql').write_text('\n'.join(apply)+'\n')
(O/'rollback-admission.sql').write_text('-- Close only the 19 new leaves. Keep all content, drafts, accepted jobs, results and credit history. Remove the same WEB scope additions first.\n'+'\n'.join(rollback)+'\n')
(O/'verify.sql').write_text('begin read only;\n'+verify+';\ncommit;\n')
(O/'functions-before.json').write_text(json.dumps(records,indent=2)+'\n')
(O/'scope.json').write_text(json.dumps({'exams':sorted({p['exam_id'] for p in packages}),'questions':qs,'leaves':leaves,'new_rows':sum(len(rows) for p in packages for rows in p['existing_schema_rows'].values())+len(packages),'active_state_rows':4*len(packages),'functions':[{'signature':r['signature'],'before':r['before_md5'],'after':r['after_md5']} for r in records],'draft_sql_sha256':hashlib.sha256((P/'apply-draft.private.sql').read_bytes()).hexdigest(),'activate_sql_sha256':hashlib.sha256((P/'activate-public.private.sql').read_bytes()).hexdigest()},indent=2)+'\n')
print({'questions':len(qs),'rows':sum(len(rows) for p in packages for rows in p['existing_schema_rows'].values())+len(packages),'state_updates':4*len(packages),'existing_functions':len(records),'checks':len(checks),'production_writes':0})
