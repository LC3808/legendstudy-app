"""Isolated synthetic PostgreSQL integration; never connects to Supabase."""
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 with tempfile.TemporaryDirectory(prefix='admin-phase2-',dir='/private/tmp') as tmp:
  p=Path(tmp);sock=p/'socket';sock.mkdir()
  def run(args,**kw):return subprocess.run(list(map(str,args)),env=env,text=True,capture_output=True,**kw)
  def command(args):
   r=run(args);assert not r.returncode,r.stderr
  command([PG/'initdb','-D',p/'db','-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  command([PG/'pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start'])
  try:
   def sql(s,error=None):
    r=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
    if error:assert r.returncode and error in r.stderr,r.stderr;return
    assert not r.returncode,r.stderr
    return r.stdout.strip()
   sql("""
create role anon;create role authenticated;create role service_role;
create schema auth;create schema account_private;create schema essay_private;create schema math_private;create schema essay_exam_private;
create table auth.users(id uuid primary key);
insert into auth.users values('00000000-0000-0000-0000-000000000001');
create function auth.uid() returns uuid language sql as $$ select '00000000-0000-0000-0000-000000000001'::uuid $$;
create function public.is_quality_operator() returns boolean language sql as $$select coalesce(current_setting('test.quality',true),'')='yes'$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select coalesce(current_setting('test.blocked',true),'')<>'yes'$$;
create function math_private.require_active(uuid[]) returns void language plpgsql as $$begin if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;end$$;
create table quality_operators(user_id uuid);insert into quality_operators select id from auth.users;
create table essay_evaluations(id uuid primary key);
create table essay_generated_rewrites(id uuid primary key);
create table math_evaluations(id uuid primary key);
create table credit_accounts(id uuid primary key,user_id uuid);
insert into credit_accounts select id,id from auth.users;
create table essay_exam_private.runs(id uuid primary key,account_id uuid,exam_id uuid,parent_id uuid,previous_paid_run_id uuid,submission_index integer,snapshot jsonb,state text,result jsonb,created_at timestamptz,completed_at timestamptz);
create table essay_questions(id uuid primary key,label text);
insert into essay_questions values('00000000-0000-0000-0000-000000000010','공식문제 2');
insert into essay_exam_private.runs values('00000000-0000-0000-0000-000000000020','00000000-0000-0000-0000-000000000001',gen_random_uuid(),null,null,1,
'{"answers":[{"questionId":"00000000-0000-0000-0000-000000000010","body":"synthetic answer","rubricVersion":"r1","evidenceVersion":"e1"}]}','completed','{"questions":[{"questionId":"00000000-0000-0000-0000-000000000010","criteria":[{"id":"synthetic"}],"evaluation":{"verdict":"CORRECT"}}]}','2026-11-04 00:00+09','2026-11-04 00:01+09');
""")
   legacy=(ROOT/'supabase/migrations/20261001000200_human_quality_persistence.sql').read_text()
   # Install canonical validators/table/immutability, not unrelated legacy RPC bodies.
   sql(legacy[:legacy.index('create function public.ql_submit_human_judgment')]+'''alter table human_quality_judgments enable row level security;
alter table human_quality_findings enable row level security;commit;''')
   sql('''alter table human_quality_judgments alter column evaluation_id drop not null;
alter table human_quality_judgments add column math_evaluation_id uuid references math_evaluations(id) on delete cascade;
alter table human_quality_judgments drop constraint human_quality_judgments_rubric_version_check;
alter table human_quality_judgments drop constraint human_quality_judgments_rubric_result_check;
alter table human_quality_judgments add constraint hq_exact_domain check(num_nonnulls(evaluation_id,math_evaluation_id)=1);
alter table human_quality_judgments add constraint hq_domain_rubric check(true);
create function math_private.hq_rubric_valid(jsonb) returns boolean language sql as $$select true$$;
''')
   sql((ROOT/'supabase/migrations/20261104085951_admin_analytics_phase2_quality.sql').read_text())
   prefix="set role authenticated;set test.quality='yes';"
   rid='00000000-0000-0000-0000-000000000020';qid='00000000-0000-0000-0000-000000000010'
   call=f"select ql_exam_detail('{rid}','{qid}');"
   d=json.loads(sql(prefix+call));s=d['subject'];assert s['official_label']=='공식문제 2' and s['result_available']
   original=sql('select md5(row_to_json(r)::text) from essay_exam_private.runs r')
   rubric={k:'OK' for k in ['diagnosis','core_priority','actionability','evidence_adherence','stance_preservation','hallucination_absence']}
   rubric.update({k:'NA' for k in ['sentence_feedback','progression','generated_rewrite']})
   payload=dict(run_id=rid,question_id=qid,expected_snapshot_sha256=s['snapshot_sha256'],client_submission_id='00000000-0000-0000-0000-000000000030',rubric_result=rubric,overall_disposition='PASS',findings=[],official_source_reviewed=True)
   def submit(v,err=None):
    query="select ql_exam_submit('"+json.dumps(v).replace("'","''")+"');"
    r=sql(prefix+query,err);return json.loads(r) if r else None
   a=submit(payload);assert not a['replayed'];assert submit(payload)['replayed']
   submit({**payload,'summary_note':'changed'},'submission key conflict')
   submit({**payload,'client_submission_id':'00000000-0000-0000-0000-000000000031','expected_snapshot_sha256':'0'*64},'stale subject')
   correction={**payload,'client_submission_id':'00000000-0000-0000-0000-000000000032','supersedes_judgment_id':a['judgment_id'],'overall_disposition':'NEEDS_REVIEW'}
   b=submit(correction);submit({**correction,'client_submission_id':'00000000-0000-0000-0000-000000000033'},'invalid correction head')
   for role in ['anon','service_role']:sql(f'set role {role};'+call,'permission denied')
   sql('set role authenticated;'+call,'insufficient_privilege')
   sql(prefix+"set test.blocked='yes';"+call,'insufficient_privilege')
   sql(prefix+'select * from human_quality_judgments','permission denied')
   sql("update human_quality_judgments set summary_note='overwrite'",'immutable judgment')
   assert original==sql('select md5(row_to_json(r)::text) from essay_exam_private.runs r')
   assert len(json.loads(sql(prefix+call))['history'])==2
   listing=json.loads(sql(prefix+"select ql_exam_cases('2026-11-04 00:00+09','2026-11-05 00:00+09');"));assert listing['total']==1 and listing['coverage']['reviewed']==1
   assert json.loads(sql(prefix+"select ql_exam_cases('2026-11-04 00:00+09','2026-11-05 00:00+09',0,true);"))['total']==0
   sql("""create function public.admin_operator() returns boolean language sql as $$select coalesce(current_setting('test.admin',true),'')='yes'$$;
alter table essay_exam_private.runs add column decision_id uuid;
create table essay_billing_decisions(id uuid primary key,reason text,credits_required int);
create table universities(id uuid primary key,name text);
create table essay_exams(id uuid primary key,university_id uuid,exam_name text);
""")
   sql("""create schema essay_ops_private;
create function public.analytics_admin_check() returns boolean language sql as $$select public.admin_operator()$$;
create table essay_ops_private.calls(call_id text,evaluation_id uuid,called_at timestamptz,provider text,model text,input_tokens bigint,output_tokens bigint,attempt int,cost_usd numeric,cost_status text);
insert into essay_ops_private.calls(call_id,called_at,attempt,cost_status) values ('exam/zero','2026-11-04 01:00+09',0,'UNKNOWN'),('exam/first-retry','2026-11-04 01:00+09',1,'UNKNOWN'),('legacy/first','2026-11-04 01:00+09',1,'UNKNOWN'),('legacy/retry','2026-11-04 01:00+09',2,'UNKNOWN');
""")
   sql((ROOT/'supabase/migrations/20261104090610_admin_analytics_phase2_learning.sql').read_text())
   cost=json.loads(sql("set test.admin='yes';select analytics_api_cost('2026-11-04 00:00+09','2026-11-05 00:00+09');"));assert cost['reprocess_calls']==2 and cost['unknown_calls']==4 and cost['total_reported_cost'] is None and cost['by_model'][0]['input_tokens'] is None,cost

   learn="select admin_exam_learning('2026-11-04 00:00+09','2026-11-05 00:00+09');"
   sql('set role authenticated;'+learn,'insufficient_privilege')
   small=json.loads(sql("set role authenticated;set test.admin='yes';"+learn));assert small['metrics'] is None and small['exams']==[]
   sql("insert into auth.users select ('00000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid from generate_series(2,5)n;insert into credit_accounts select id,id from auth.users on conflict do nothing;")
   sql("insert into essay_exam_private.runs select gen_random_uuid(),ca.id,r.exam_id,null,null,1,r.snapshot,r.state,r.result,r.created_at,r.completed_at,null from credit_accounts ca cross join essay_exam_private.runs r where ca.id<>r.account_id;")
   large=json.loads(sql("set role authenticated;set test.admin='yes';"+learn));assert large['metrics']['users']==5 and large['metrics']['runs']==5 and large['metrics']['free_rewrites']==0 and large['exams'][0]['users']==5,large
   sql("set role anon;"+learn,'permission denied')
   sql("delete from essay_exam_private.runs");assert sql('select count(*) from human_quality_judgments')=='0'
   print('PASS: original identity/label, selected detail, same-key replay/conflict, stale hash, correction head conflict, append-only, ACL/lifecycle, source preservation, list/review coverage, source erasure cascade')
  finally:command([PG/'pg_ctl','-D',p/'db','-m','immediate','-w','stop'])
if __name__=='__main__':main()
