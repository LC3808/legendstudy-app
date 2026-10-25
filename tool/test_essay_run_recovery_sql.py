"""Isolated PostgreSQL test: targeted recovery is append-only and never rebills."""
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'supabase/candidates/essay_run_recovery_20261025';PG=Path('/opt/homebrew/opt/postgresql@17/bin')
RID='b2cbc55f-edc7-423d-bfdc-f5d039b215e5';EXAM='d420ef29-218a-57fd-8524-842a0e551714'
env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
def run(args,**kw):return subprocess.run([str(x) for x in args],env=env,capture_output=True,text=True,**kw)
with tempfile.TemporaryDirectory(prefix='essay-recovery-') as tmp:
 p=Path(tmp);(p/'sock').mkdir();assert run([PG/'initdb','-D',p/'db','-U','tester','--auth=trust','--no-locale','--encoding=UTF8']).returncode==0
 assert run([PG/'pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {p/'sock'} -p 5432 -c listen_addresses=''",'-w','start']).returncode==0
 try:
  def sql(s,error=None):
   r=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',p/'sock','-U','tester','-d','postgres'],input=s)
   if error:assert r.returncode and error in r.stderr,r.stderr;return
   assert r.returncode==0,r.stderr;return r.stdout.strip()
  sql('''create schema essay_exam_private;
create table public.credit_accounts(id uuid primary key);
create table public.essay_billing_decisions(id uuid primary key,status text,credits_required int,released_at timestamptz,settled_at timestamptz);
create table public.credit_transactions(account_id uuid,grant_id uuid,decision_id uuid,transaction_type text,balance_delta int,reserved_delta int,idempotency_key text unique,reason_code text);
create table essay_exam_private.runs(id uuid primary key,exam_id uuid,account_id uuid,decision_id uuid,state text,snapshot jsonb,lease_until timestamptz,result jsonb,completed_at timestamptz);
create table essay_exam_private.checkpoints(run_id uuid,key text,writer uuid,state text,payload jsonb,primary key(run_id,key));
create table essay_exam_private.retry_requests(run_id uuid,request_key uuid,generation int,attempts jsonb,created_at timestamptz default clock_timestamp(),lease_until timestamptz default clock_timestamp()+interval '15 minutes',primary key(run_id,request_key),unique(run_id,generation));''')
  text=(ROOT/'supabase/candidates/essay_exam_unit/install.sql').read_text();start=text.index('create function essay_exam_private.finish(');end=text.index('end $$;',start)+len('end $$;');sql(text[start:end])
  sql(f"""insert into credit_accounts values('{RID}');insert into essay_billing_decisions values('{RID}','reserved',1,null,null);
insert into credit_transactions values('{RID}','{RID}','{RID}','reserve',0,1,'original-reserve','existing');
insert into essay_exam_private.runs values('{RID}','{EXAM}','{RID}','{RID}','reserved','{{"answers":[{{"questionId":"a"}},{{"questionId":"b"}},{{"questionId":"c"}}]}}',clock_timestamp()-interval '1 hour',null,null);
insert into essay_exam_private.checkpoints values('{RID}','q0','{RID}','checkpoint','{{"state":"completed","output":{{"preserved":true}}}}'),('{RID}','q1','{RID}','checkpoint','{{"state":"failed"}}'),('{RID}','q2','{RID}','pending',null);""")
  hashes=sql(f"select json_build_array(md5(snapshot::text),(select md5(jsonb_agg(to_jsonb(c) order by key)::text) from essay_exam_private.checkpoints c where c.run_id=r.id),(select md5(b::text) from essay_billing_decisions b where b.id=r.decision_id)) from essay_exam_private.runs r where id='{RID}'")
  vals=json.loads(hashes);old=['d36c1fc9189435f3c38b7b0e127263ba','157146af4de2738b93259a0f4f970e6f','a196fa4509f6dfbdaee6520425d4e423']
  def file(name):
   s=(D/name).read_text()
   for a,b in zip(old,vals):s=s.replace(a,b)
   return s
  def check(name):
   rows=sql(file(name));assert all(v=='t' for v in rows.split('|')),rows
  check('precheck.sql');before=sql('select jsonb_agg(to_jsonb(t)) from credit_transactions t')
  sql(f"update essay_exam_private.runs set lease_until=clock_timestamp()+interval '1 minute' where id='{RID}'")
  sql(file('apply.sql'),'RECOVERY_BASELINE_CHANGED')
  sql(f"update essay_exam_private.runs set lease_until=clock_timestamp()-interval '1 hour' where id='{RID}'")
  sql(file('apply.sql'));check('postcheck.sql');sql(file('apply.sql'),'RECOVERY_ALREADY_STARTED')
  assert before==sql('select jsonb_agg(to_jsonb(t)) from credit_transactions t')
  sql(file('rollback.sql'),'RELEASE_NOT_SAFE')
  sql("update essay_exam_private.retry_requests set lease_until=clock_timestamp()-interval '1 hour'")
  sql(file('rollback.sql'));sql(file('rollback.sql'))
  assert sql("select status from essay_billing_decisions")=='released'
  assert sql("select count(*) from credit_transactions where transaction_type='reserve'")=='1'
  assert sql("select count(*) from credit_transactions where transaction_type='release'")=='1'
  assert sql("select count(*) from credit_transactions where transaction_type='consume'")=='0'
  assert sql("select payload->'output'->>'preserved' from essay_exam_private.checkpoints where key='q0'")=='true'
  assert sql("select state from essay_exam_private.checkpoints where key='q2'")=='pending'
  print(json.dumps({'isolated_postgres':'PASS','prechecks':8,'postchecks':6,'active_lease_blocked':True,'reapply_blocked':True,'old_checkpoints_preserved':True,'new_reservation':0,'fallback_release_idempotent':True,'production_writes':0}))
 finally:run([PG/'pg_ctl','-D',p/'db','-m','immediate','-w','stop'])
