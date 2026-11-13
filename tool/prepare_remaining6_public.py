"""Prepare exact KAU2 resolved Registry/Math publication; never connects to any database."""
import hashlib,json,pathlib,re,sys
R=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'tool'))
from essay_lab.task20_priority_packages import literal,registration_sql
from essay_lab.four_university_connection import ORDER
SOURCE=R/'.local/remaining6-20261113'
OUT=R/'supabase/candidates/remaining6_20261113'
PRIVATE=R/'.local/remaining6-20261113'

def arr(ids):return 'array['+','.join(literal(x)+'::uuid' for x in ids)+']'
def guard(expr,msg):return "do $guard$ begin if not ("+expr+") then raise exception '"+msg+"';end if;end $guard$;"
def query(checks):return '\nunion all\n'.join('select '+literal(n)+' check_name,('+e+') passed' for n,e in checks)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,body,private=False):
 p=(PRIVATE if private else OUT)/name;p.write_text(body+'\n');return p

def build(snapshot_path):
 OUT.mkdir(parents=True,exist_ok=True);PRIVATE.mkdir(parents=True,exist_ok=True)
 functions=json.loads(pathlib.Path(snapshot_path).read_text())
 packs=[json.loads(p.read_text()) for p in sorted(SOURCE.glob('*.package.private.json'))]
 assert len(packs)==2
 for p in packs:p['existing_schema_rows']={t:p['existing_schema_rows'][t] for t in ORDER}
 leaves=[p['ids']['leaf'] for p in packs];qs=[p['essay_question_id'] for p in packs];eids=sorted({p['exam_id'] for p in packs})
 all_eids=eids;all_qids=qs;assert len(eids)==2
 rows={'essay_exams':[],'essay_questions':[]}
 records=[]
 for f in functions:
  if f['nspname']!='math_private' or f['proname'] not in ('evaluation_admission','release_catalog'):continue
  old=f['definition'];a=list(re.finditer(r"array\[(?:'[0-9a-f-]+'::uuid,?)+\]",old));assert len(a)==1;a=a[0]
  before=re.findall(r"'([0-9a-f-]+)'::uuid",a.group());assert len(set(before))==451 and not set(leaves)&set(before)
  new=old[:a.start()]+arr(sorted(before+leaves))+old[a.end():]
  sig='math_private.'+f['proname']+('()' if f['proname']=='evaluation_admission' else '(uuid)')
  records.append(dict(signature=sig,before=old,after=new,before_md5=hashlib.md5(old.encode()).hexdigest(),after_md5=hashlib.md5(new.encode()).hexdigest()))
 assert len(records)==2
 ids={t:[row['id'] for p in packs for row in p['existing_schema_rows'][t]] for t in ORDER}
 snapshots=[]
 def table_snapshot(t,key,exclude=None):
  predicate='true' if not exclude else key+' <> all('+arr(exclude)+')'
  snapshots.append("select "+literal(t)+" name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by "+key+"),'')) digest from "+t+' x where '+predicate)
 for t in ORDER:table_snapshot('public.'+t,'id',ids[t])
 table_snapshot('math_private.task20_hanyang_source_pages','question_id',qs)
 table_snapshot('public.universities','id')
 table_snapshot('public.essay_exams','id')
 table_snapshot('public.essay_questions','id')
 for t in ['essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']:table_snapshot('public.'+t,'id')
 excluded=','.join(literal(r['signature'])+'::regprocedure' for r in records)
 snapshots += ["select 'function definitions/owners/ACL' name,count(*) n,md5(coalesce(string_agg(md5(pg_get_functiondef(p.oid)||p.proowner::text||coalesce(p.proacl::text,'')),'' order by p.oid),'')) digest from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.oid not in ("+excluded+") and p.prokind='f' and n.nspname in ('public','math_private','essay_private','account_private')",
 "select 'RLS policies' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' order by schemaname,tablename,policyname),'')) digest from pg_policies p",
 "select 'table owners/RLS/ACL' name,count(*) n,md5(coalesce(string_agg(md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text),'' order by c.oid),'')) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','account_private') and c.relkind in ('r','p')",
 "select 'changed functions identity/ACL' name,count(*) n,md5(string_agg(jsonb_build_array(p.oid,p.proowner,p.proacl)::text,'' order by p.oid)) digest from pg_proc p where p.oid in ("+excluded+")"]
 snapshot='\nunion all\n'.join(snapshots)
 compare=guard('not exists(select 1 from ('+snapshot+") n full join _khu_math_before b using(name) where n.n is distinct from b.n or n.digest is distinct from b.digest)",'KHU_PRESERVATION_DRIFT')
 header="begin isolation level repeatable read;\nset local lock_timeout='5s';\nset local statement_timeout='120s';\nselect pg_advisory_xact_lock(20261112,58);"
 capture='create temp table _khu_math_before on commit drop as '+snapshot+';'
 fresh=[(t+' IDs absent','not exists(select 1 from public.'+t+' where id=any('+arr(ids[t])+'))') for t in ORDER]
 fresh += [('Worker rows absent','not exists(select 1 from math_private.task20_hanyang_source_pages where question_id=any('+arr(qs)+'))'),('question binding absent','not exists(select 1 from public.math_subproblems where essay_question_id=any('+arr(qs)+'))'),('Worker implementation unchanged',"md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure))='54acd2a1914f360e6ecd62e39acc8222'"),('old public catalog exact count','jsonb_array_length(math_private.release_catalog(null))=451')]
 fresh += [(r['signature']+' unchanged','md5(pg_get_functiondef('+literal(r['signature'])+'::regprocedure))='+literal(r['before_md5'])) for r in records]
 for row in rows['essay_exams']+rows['essay_questions']:
  if row['id'] not in qs+eids:continue
  t='essay_exams' if row['id'] in eids else 'essay_questions'
  fresh.append((row['id']+' Registry exact unpublished','exists(select 1 from public.'+t+' t where id='+literal(row['id'])+' and to_jsonb(t) @> '+literal(json.dumps(row,ensure_ascii=False))+'::jsonb)'))
 receipt=json.loads((OUT/'package-receipt.json').read_text())
 for q in receipt['questions']:
  fresh.append((q['question_id']+' existing Registry exact',"exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id="+literal(q['question_id'])+" and e.id="+literal(q['exam_id'])+" and q.question_key="+literal(q['source_key'])+")"))
 apply=[header]+[guard(e,'KHU_MATH_PREFLIGHT_'+str(i)) for i,(_,e) in enumerate(fresh)]+[capture,'create temp table _khu_math_catalog_before on commit drop as select value row from jsonb_array_elements(math_private.release_catalog(null));']
 insert=registration_sql(packs).strip();assert insert.startswith('begin;') and insert.endswith('commit;');apply.append(insert[6:-7])
 for p in packs:
  w=json.loads((SOURCE/(p['essay_question_id']+'.worker.private.json')).read_text());assert hashlib.sha256((w['manifest_text']+w['images_text']).encode()).hexdigest()==w['sha256']
  apply.append('insert into math_private.task20_hanyang_source_pages(question_id,exam_id,manifest,images,content_sha256) values('+','.join([literal(w['question_id']),literal(w['exam_id']),literal(w['manifest_text'])+'::jsonb',literal(w['images_text'])+'::jsonb',literal(w['sha256'])])+');')
 for t in ['math_problem_sets','math_problems','math_evaluation_profiles','math_canonical_solutions']:apply.append('update public.'+t+" set state='ACTIVE' where id=any("+arr(ids[t])+") and state='DRAFT';")
 apply += [r['after'].rstrip().rstrip(';')+';' for r in records]
 checks=[]
 for p in packs:
  leaf=literal(p['ids']['leaf']);qid=literal(p['essay_question_id']);eid=literal(p['exam_id'])
  checks.append((p['essay_question_id']+' public mapping',"(select count(*) from jsonb_array_elements(math_private.release_catalog("+eid+")) x where x->>'leaf_id'="+leaf+" and x->>'essay_question_id'="+qid+")=1"))
  checks.append((p['essay_question_id']+' unique profile',"(with candidates as(select ep.id,case ep.scope when 'LEAF' then 4 when 'PROBLEM' then 3 when 'EXAM' then 2 else 1 end rank from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id join public.math_problem_sets ps on ps.id=pr.problem_set_id join public.math_evaluation_profiles ep on ep.state='ACTIVE' and ep.response_format=l.response_format and (ep.leaf_id=l.id or ep.problem_id=l.problem_id or ep.essay_exam_id=ps.essay_exam_id or (ep.scope='COMMON_MATH_RUBRIC' and l.allow_common_rubric)) where l.id="+leaf+" and pr.state='ACTIVE' and ps.state='ACTIVE') select count(*)=1 and bool_and(id="+literal(p['existing_schema_rows']['math_evaluation_profiles'][0]['id'])+"::uuid) from candidates where rank=(select max(rank) from candidates))"))
  w=json.loads((SOURCE/(p['essay_question_id']+'.worker.private.json')).read_text())
  checks.append((p['essay_question_id']+' Worker exact evidence',"exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id join math_private.task20_hanyang_source_pages w on w.question_id=l.essay_question_id where l.id="+leaf+" and w.exam_id="+eid+' and w.content_sha256='+literal(w['sha256'])+" and math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images'=w.images)"))
  checks.append((p['essay_question_id']+' Registry identity',"exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id="+qid+' and e.id='+eid+' and not q.is_published and not e.is_active)'))
 for t in ORDER:
  checks.append((t+' exact new row count','(select count(*) from public.'+t+' where id=any('+arr(ids[t])+'))='+str(len(ids[t]))))
 apply += [guard('not exists(select 1 from ('+query(checks)+') q where passed is distinct from true)','KHU_MATH_POSTCHECK'),guard('not exists(select row from _khu_math_catalog_before except select value from jsonb_array_elements(math_private.release_catalog(null))) and jsonb_array_length(math_private.release_catalog(null))=(select count(*)+2 from _khu_math_catalog_before)','KHU_OLD_CATALOG_DRIFT'),compare,'commit;']
 rollback=[header]+[guard('md5(pg_get_functiondef('+literal(r['signature'])+'::regprocedure))='+literal(r['after_md5']),'KHU_ROLLBACK_FUNCTION_DRIFT') for r in records]+[capture]+[r['before'].rstrip().rstrip(';')+';' for r in records]+[compare,'commit;']
 save('math-apply-public.private.sql','\n'.join(apply),True)
 save('math-preflight.sql','begin read only;\n'+query(fresh)+';\ncommit;')
 save('math-verify.sql','begin read only;\n'+query(checks)+';\ncommit;')
 save('math-preservation.sql','begin read only;\n'+snapshot+';\ncommit;')
 save('math-rollback-admission.sql','-- Non-destructive: close only new 2 Math allowlist entries; preserve packages, Registry, histories and credit. Remove matching WEB scope first. No delete or policy change.\n'+'\n'.join(rollback))
 save('math-functions-before.json',json.dumps(records,indent=2))
 scope=dict(exams=eids,questions=qs,leaves=leaves,new_rows={t:len(ids[t]) for t in ORDER},worker_rows=2,total_new_math_rows=sum(len(ids[t]) for t in ORDER)+2,registry_new_rows=0,state_updates=8,registry_public_updates=0,existing_public_preserved=451,new_public_count=453,preflight_checks=len(fresh),postflight_checks=len(checks),preservation_groups=len(snapshots),functions=[{k:r[k] for k in ['signature','before_md5','after_md5']} for r in records],apply_sql_sha256=sha(PRIVATE/'math-apply-public.private.sql'),rollback_sql_sha256=sha(OUT/'math-rollback-admission.sql'),provider_calls=0,production_writes=0)
 save('math-scope.json',json.dumps(scope,indent=2));print(json.dumps({k:v for k,v in scope.items() if k not in ['exams','questions','leaves','functions']},indent=2))

# Root-only orchestration helpers: SELECTs and validation; this module never applies SQL.
def production_capture(connection):
 """Call inside the root's single REPEATABLE READ transaction, before/after SQL."""
 tables={**{'public.'+t:'id::text' for t in ORDER},
  'math_private.task20_hanyang_source_pages':'question_id::text',
  **{'public.'+t:'id::text' for t in ['universities','essay_exams','essay_questions','essay_attempts','essay_evaluations','credit_transactions','math_attempts','math_evaluations']},
  'essay_material_private.documents':'sha256',
  'essay_material_private.reviews':'exam_id::text',
  'essay_material_private.revisions':"exam_id::text||':'||revision::text"}
 result={'tables':{}}
 for table,key in tables.items():
  rr=connection.execute('select '+key+' k,md5(to_jsonb(x)::text) digest from '+table+' x').fetchall()
  result['tables'][table]={r['k']:r['digest'] for r in rr}
 # All application namespaces, including exam/material/beta/account scopes.
 rr=connection.execute("select n.nspname||'.'||p.proname||'('||oidvectortypes(p.proargtypes)||')' k,md5(pg_get_functiondef(p.oid)) body,md5(jsonb_build_array(p.oid,p.proowner,p.proacl)::text) identity from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.prokind='f' and n.nspname in ('public','math_private','essay_private','essay_exam_private','essay_material_private','essay_beta_private','essay_ops_private','account_private')").fetchall()
 result['functions']={r['k']:{'body':r['body'],'identity':r['identity']} for r in rr}
 rr=connection.execute("select schemaname||'.'||tablename||'.'||policyname k,to_jsonb(p) definition,md5(to_jsonb(p)::text) digest from pg_policies p").fetchall()
 result['policies']={r['k']:{'digest':r['digest'],'definition':r['definition']} for r in rr}
 rr=connection.execute("select n.nspname||'.'||c.relname k,md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','essay_exam_private','essay_material_private','essay_beta_private','essay_ops_private','account_private','storage') and c.relkind in ('r','p')").fetchall()
 result['relations']={r['k']:r['digest'] for r in rr}
 # Whole-exam submissions/results/checkpoints and Math session/coaching history.
 # Hash multisets support composite-key/private tables without guessing their schemas.
 from psycopg import sql
 result['private_history']={}
 names=connection.execute("select schemaname,tablename from pg_tables where schemaname in ('essay_exam_private','essay_private','math_private') and not (schemaname='math_private' and tablename='task20_hanyang_source_pages') order by 1,2").fetchall()
 for row in names:
  statement=sql.SQL("select count(*) n,md5(coalesce(string_agg(h,'' order by h),'')) digest from(select md5(to_jsonb(x)::text) h from {}.{} x) hashes").format(sql.Identifier(row['schemaname']),sql.Identifier(row['tablename']))
  result['private_history'][row['schemaname']+'.'+row['tablename']]=dict(connection.execute(statement).fetchone())
 return result

def assert_production_preserved(before,after):
 packs=[json.loads(p.read_text()) for p in SOURCE.glob('*.package.private.json')]
 permitted={**{'public.'+t:{r['id'] for p in packs for r in p['existing_schema_rows'][t]} for t in ORDER},'math_private.task20_hanyang_source_pages':{p['essay_question_id'] for p in packs}}
 report={}
 for table,old in before['tables'].items():
  current=after['tables'][table]
  assert all(current.get(k)==v for k,v in old.items()),'EXISTING_DATA_DRIFT:'+table
  added=set(current)-set(old);assert added==permitted.get(table,set()),'UNEXPECTED_INSERTS:'+table
  report[table]=dict(old_rows_preserved=len(old),new_rows=len(added))
 for key in ['private_history','relations','policies']:assert before[key]==after[key],key+'_DRIFT'
 assert set(before['functions'])==set(after['functions'])
 changed={r['signature']:r for r in json.loads((OUT/'math-functions-before.json').read_text())}
 for sig,old in before['functions'].items():
  current=after['functions'][sig];assert old['identity']==current['identity']
  if sig not in changed:assert old['body']==current['body'],sig
  else:assert old['body']==changed[sig]['before_md5'] and current['body']==changed[sig]['after_md5'],sig
 return dict(tables=report,functions_preserved=len(before['functions'])-2,policies_preserved=len(before['policies']),relations_preserved=len(before['relations']),private_history_tables_preserved=len(before['private_history']))

def transaction_sql(path,expected_sha256):
 """Return reviewed SQL body for root execution inside ONE outer transaction."""
 path=pathlib.Path(path);assert sha(path)==expected_sha256,'SQL_FILE_SHA_DRIFT:'+str(path)
 text=path.read_text()
 # Only strip known outer statements. PL/pgSQL BEGIN blocks are untouched.
 stripped,n=re.subn(r'(?im)^begin(?: isolation level repeatable read)?;','',text,count=1)
 assert n==1,'OUTER_BEGIN_NOT_FOUND'
 stripped,n=re.subn(r'commit;\s*$','',stripped,count=1,flags=re.I)
 assert n==1,'OUTER_COMMIT_NOT_FOUND'
 assert not re.search(r'(?im)^\s*(?:begin isolation|commit;|rollback;)',stripped),'UNEXPECTED_TRANSACTION_BOUNDARY'
 return stripped

if __name__=='__main__':
 if len(sys.argv)!=2:raise SystemExit('Usage: prepare_khu_math_public.py PRIVATE_LIVE_FUNCTIONS_JSON')
 build(sys.argv[1])
