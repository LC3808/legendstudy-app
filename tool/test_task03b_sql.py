"""Disposable PostgreSQL17 with read-only captured scoring contract. No remote DSN."""
import concurrent.futures,hashlib,json,os,subprocess,tempfile,uuid
from pathlib import Path
from task03a_packages import ROOT,engine_questions,vectors
R=ROOT;D=R/'data/mock_expansion/task03b';O=R/'supabase/candidates/task03b_ready_20261111';PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def read(p):return json.loads(p.read_text())
def quote(v):return "'"+str(v).replace("'","''")+"'"
def lit(v):return quote(json.dumps(v,separators=(',',':')))+'::jsonb'
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 with tempfile.TemporaryDirectory(prefix='task03b-pg-') as tmp:
  d=Path(tmp);sock=d/'s';sock.mkdir();db=d/'db'
  def run(args,**kw):return subprocess.run(list(map(str,args)),text=True,capture_output=True,env=env,**kw)
  for args in [[PG/'initdb','-D',db,'-U','postgres','--auth=trust','--encoding=UTF8'],[PG/'pg_ctl','-D',db,'-l',d/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start']]:
   r=run(args);assert r.returncode==0,r.stderr
  def sql(s=None,file=None,error=None):
   args=[PG/'psql','-XqAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres']
   if file:args+=['-f',file]
   r=run(args,input=s)
   if error:assert r.returncode and error in r.stderr,(error,r.stderr);return r.stderr
   assert r.returncode==0,r.stderr
   return r.stdout.strip()
  def digest(table):return sql(f"select md5(string_agg(to_jsonb(r)::text,E'\\n' order by to_jsonb(r)::text)) from public.{table} r;")
  def uid(s):return str(uuid.uuid5(uuid.NAMESPACE_URL,'isolated-task03b:'+s))
  a,b=uid('user-a'),uid('user-b')
  def rpc(k,aid,answers,who=a):return f"set role authenticated;set request.jwt.claim.sub='{who}';select public.submit_mock_attempt('{aid}',null,'{k}',null,'mixed-v2',{lit([dict(question_number=i+1,choice=v) for i,v in enumerate(answers)])});"
  try:
   sql("create role anon;create role authenticated;create role service_role bypassrls;create schema auth;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema public,auth to anon,authenticated,service_role;grant execute on function auth.uid() to public;")
   for f in sorted((R/'supabase/migrations').glob('*.sql')):
    if f.name<='20260914000200_mock_exam_scoring.sql':sql(f.read_text())
   sql((R/'supabase/candidates/task19_grade_cutoff/app63-production.sql').read_text())
   live=read(D/'production_schema_contract.json')
   # Real account guard functions, minimal synthetic dependency table, no production users.
   sql('create schema account_private;revoke all on schema account_private from public,anon,authenticated,service_role;create table public.account_deletion_requests(subject_id uuid,state text);')
   for f in live['account_dependencies']:
    sql(f['definition']);fn=f['name'] if '.' in f['name'].split('(')[0] else 'public.'+f['name']
    sql('revoke all on function '+fn+' from public,anon,authenticated,service_role;')
    for acl in f['acl'] or []:
     role=acl.split('=')[0]
     if role!='postgres':
      sql('do $$begin if not exists(select 1 from pg_roles where rolname='+quote(role)+') then execute '+quote('create role '+role)+';end if;end$$;')
      sql('grant execute on function '+fn+' to '+role+';')
   # Recreate captured restrictive owner policies; original permissive rules remain.
   for policy in live['policies']:
    if policy['permissive']!='RESTRICTIVE':continue
    sql('create policy '+policy['policyname']+' on public.'+policy['tablename']+' as restrictive for '+policy['cmd']+' to '+','.join(policy['roles'])+' using ('+policy['qual']+') with check ('+policy['with_check']+');')
   # Load actual selected function bodies, preserving captured role ACLs, no production rows.
   for f in live['functions']:
    sql(f['definition'])
    sql('revoke all on function public.'+f['name']+' from public,anon,authenticated,service_role;')
    for acl in f['acl'] or []:
     role=acl.split('=')[0]
     assert role in ['postgres','anon','authenticated','service_role']
     if role!='postgres':sql('grant execute on function public.'+f['name']+' to '+role+';')
   sql(live['fetch'])
   # Confirm all targeted table columns and constraints match the read-only production snapshot.
   current=read(D/'production_preflight.json');sql(file=O/'00_preflight.sql')
   for table in {c['table_name'] for c in live['columns']}:
    actual=json.loads(sql(f"select json_agg(json_build_object('name',column_name,'nullable',is_nullable,'type',udt_name) order by column_name) from information_schema.columns where table_schema='public' and table_name='{table}';"))
    expected=sorted([dict(name=c['column_name'],nullable=c['is_nullable'],type=c['udt_name']) for c in live['columns'] if c['table_name']==table],key=lambda c:c['name']);assert actual==expected,table
   for c in live['constraints']:
    assert sql(f"select pg_get_constraintdef(oid) from pg_constraint where conrelid={quote('public.'+c['table'])}::regclass and conname={quote(c['name'])};")==c['definition'],c
   print('PASS captured production scoring/cutoff function ACL, columns and constraints',flush=True)
   reg=read(R/'data/mock_expansion/task03/registry_snapshot.json');source=uid('source');statements=[f"insert into auth.users values('{a}'),('{b}');insert into source_posts(id,source,external_post_id,url,title) values('{source}','synthetic','task03b','https://example.invalid/task03b','Synthetic fixture');"]
   seen=set()
   for e in reg:
    cid=e['content_item_id'];statements.append(f"insert into content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values('{cid}','{source}','{cid}','{cid}','exam','Isolated official fixture','https://example.invalid/task03b',true);insert into exams(content_item_id,academic_year,exam_month,grade_level,exam_type) values('{cid}',{e['academic_year']},{e['exam_month']},3,{quote(e['exam_type'])});")
    for s in e['subjects']:
     if s['subject_id'] and s['subject_id'] not in seen:
      seen.add(s['subject_id']);statements.append(f"insert into subjects(id,code,name,taxonomy_version,is_active) values('{s['subject_id']}',{quote(s['code'])},{quote(s['label'])},'isolated',true);")
     mapped=bool(s['subject_id']);fields=','.join([quote(s['subject_id']) if mapped else 'null',"'isolated'" if mapped else 'null',"'verified'" if mapped else "'unmapped'","now()" if mapped else 'null'])
     statements.append(f"insert into exam_subjects(id,content_item_id,source_subject_key,raw_subject_label,subject_id,taxonomy_version,mapping_status,verified_at,display_order,is_active) values('{s['id']}','{cid}','{s['id']}',{quote(s['label'])},{fields},{s['display_order']},true);")
   sql('begin;'+''.join(statements)+'commit;')
   old=read(R/'data/grade_cutoffs/task19/reviewed_rows.json');cols=','.join(old[0]);sql(f"insert into grade_cutoff_references({cols}) select {cols} from jsonb_populate_recordset(null::grade_cutoff_references,{lit(old)});update grade_cutoff_references set status='published',is_current=true;")
   old_digest=digest('grade_cutoff_references');reg_digests={t:digest(t) for t in ['content_items','exams','exam_subjects','subjects']}
   sql(file=O/'01_engine.sql');sql(file=O/'00_preflight.sql',error='TASK03B_LIVE_FUNCTION_DRIFT')
   # New draft data only. Repeated seeding is a no-op, with exact conflict detection.
   sql(file=O/'02_seed_drafts.sql');before={t:digest(t) for t in ['answer_key_versions','exam_questions','grade_cutoff_references']};sql(file=O/'02_seed_drafts.sql');assert before=={t:digest(t) for t in before}
   assert sql("set role anon;select count(*) from mock_exam_scoring_availability where availability='scoring_available';")=='0'
   assert sql('set role anon;select count(*) from exam_questions;')=='0'
   load=read(D/'load_data.json');first=load['answer_key_versions'][0];k=first['id'];q=load['exam_questions'][0]
   sql(f"begin;update exam_questions set points=points+1 where answer_key_version_id='{q['answer_key_version_id']}' and question_number={q['question_number']};commit;")
   sql(file=O/'02_seed_drafts.sql',error='TASK03B_DATA_CONFLICT_questions')
   sql(f"update exam_questions set points={q['points']} where answer_key_version_id='{q['answer_key_version_id']}' and question_number={q['question_number']};")
   sql(file=O/'03_publish.sql');published={t:digest(t) for t in before};sql(file=O/'02_seed_drafts.sql');sql(file=O/'03_publish.sql');assert published=={t:digest(t) for t in before}
   sql(file=O/'04_validate.sql')
   assert sql("set role anon;select count(*) from mock_exam_scoring_availability where availability='scoring_available';")==str(len(load['answer_key_versions']))
   # Private references, owner-only results, immutable public key facts.
   for role in ['anon','authenticated']:
    sql(f'set role {role};select * from grade_cutoff_references;',error='permission denied')
    assert sql(f'set role {role};select count(*) from exam_questions;')==str(len(load['exam_questions']))
    sql(f'set role {role};update exam_questions set points=0;',error='permission denied')
    if role=='anon':sql(f'set role {role};delete from mock_exam_attempts;',error='permission denied')
   sql(f"update exam_questions set points=4 where answer_key_version_id='{k}';",error='KEY_IMMUTABLE')
   for e in reg[:6]:
    visible=json.loads(sql(f"set role anon;select grade_cutoff_lookup('{e['content_item_id']}');"));assert len(visible)==sum(r['content_item_id']==e['content_item_id'] for r in load['grade_cutoff_references'])
   ps=read(D/'verified_papers.json')['papers'];keymap={(x['exam_subject_id'],x['paper_variant']):x['id'] for x in load['answer_key_versions']};n=0
   for p in ps:
    kid=keymap[p['exam_subject_id'],p['paper_variant']]
    for name,answers,expected in vectors(p):
     aid=uid(kid+name);result=json.loads(sql(rpc(kid,aid,answers)));assert result['raw_score']==expected and result['grade'] is None,(p['subject_label'],name,result)
     assert result['max_score']==p['max_score'];assert len(result['answers'])==p['question_count'];assert [r['question_id'] for r in result['answers']]==[q['question_id'] for q in p['questions']]
     assert all(r['unit'] is None and r['domain'] is None and r['item_type'] is None for r in result['answers']);n+=1
   p=ps[0];answers=vectors(p)[0][1];aid=uid('parallel-retry');text=rpc(k,aid,answers)
   with concurrent.futures.ThreadPoolExecutor(2) as pool:results=list(pool.map(sql,[text,text]))
   assert results[0]==results[1];assert sql(f"select count(*) from mock_exam_attempts where id='{aid}';")=='1'
   assert sql(text)==results[0];wrong=vectors(p)[1][1];sql(rpc(k,aid,wrong),error='ATTEMPT_CONFLICT');sql(rpc(k,aid,answers,who=b),error='ATTEMPT_CONFLICT')
   assert json.loads(sql(rpc(k,uid('resubmit-new'),answers)))['raw_score']==p['max_score']
   assert sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select count(*) from mock_exam_attempts;")=='0'
   other=json.loads(sql(rpc(k,uid('other-user'),answers,who=b)));assert other['raw_score']==p['max_score']
   assert sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select count(*) from mock_exam_attempts;")=='1'
   # Preserve production lifecycle gate, including retry/read and restrictive owner RLS.
   for state in ['DELETION_PENDING','ERASING']:
    sql(f"insert into account_deletion_requests values('{b}','{state}');")
    sql(rpc(k,uid('other-user'),answers,who=b),error='LOGIN_REQUIRED')
    sql(rpc(k,uid('blocked-new'),answers,who=b),error='LOGIN_REQUIRED')
    sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select fetch_own_mock_attempt('{uid('other-user')}');",error='LOGIN_REQUIRED')
    assert sql(f"set role authenticated;set request.jwt.claim.sub='{b}';select count(*) from mock_exam_attempts;")=='0'
    sql('delete from account_deletion_requests;')
   snapshots={t:digest(t) for t in ['mock_exam_attempts','mock_exam_answers']}
   # Stop still works if Registry becomes inactive. It never drops evidence or snapshots.
   cid=p['content_item_id'];sql(f"update content_items set is_active=false where id='{cid}';")
   sql(file=O/'05_rollback_visibility.sql');sql(file=O/'05_rollback_visibility.sql');assert snapshots=={t:digest(t) for t in snapshots}
   retry=json.loads(sql(text));prior=json.loads(results[0]);prior['key_source']['status']='withdrawn';assert retry==prior
   sql(rpc(k,uid('new-after-stop'),answers),error='KEY_UNAVAILABLE')
   sql(f"update content_items set is_active=true where id='{cid}';")
   sql(file=O/'03_publish.sql',error='TASK03B_WITHDRAWN_REQUIRES_NEW_REVIEW')
   assert all(reg_digests[t]==digest(t) for t in reg_digests if t!='content_items')
   ids=','.join(quote(x['id']) for x in load['grade_cutoff_references']);assert sql(f"select md5(string_agg(to_jsonb(r)::text,E'\\n' order by to_jsonb(r)::text)) from grade_cutoff_references r where id not in ({ids});")==old_digest
   assert sql('select count(*) from grade_cutoff_versions')=='0'
   print(f'PASS {n} stored perfect/wrong/blank submissions, concurrent identical retry, changed payload rejection, new attempt resubmission, owner isolation; rollback preserves attempts/questions/old 2457 references; draft/publish rerun, conflict/RLS/Registry guards',flush=True)
  finally:run([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
