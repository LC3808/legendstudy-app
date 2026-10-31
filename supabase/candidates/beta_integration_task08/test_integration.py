"""Local-only combined candidate contract test. Synthetic data; no Provider.
Requires existing local PostgreSQL17 :55439 and psycopg. No production fallback.
"""
import os,pathlib,re,subprocess,json
import psycopg
ROOT=pathlib.Path(__file__).resolve().parents[3]
DB=os.environ.get('TASK08_DB','task08_integration')
assert re.fullmatch(r'task08_[a-z0-9_]+',DB)
conn=psycopg.connect(host='127.0.0.1',port=55439,user='postgres',dbname=DB,autocommit=True)
def sql(s):
 with conn.cursor() as c:
  c.execute(s)
  return c.fetchall() if c.description else []
def file(p):
 text=(ROOT/p).read_text();sql('\n'.join(x for x in text.splitlines() if not x.startswith('\\')))
def ok(name,check=True):
 assert check,name
 print('PASS',name,flush=True)
# Base fixture + real beta functions and concurrency tests, reused rather than copied.
if not sql("select to_regnamespace('essay_beta_private')")[0][0]:
 subprocess.run(['python3',str(ROOT/'supabase/candidates/essay_beta_admin_v1/test_runtime.py')],env={**os.environ,'BETA_TEST_DB':DB},check=True)
# Complete only the legacy schema fixture columns needed by the other candidates.
# This fixture is not a production migration; enum-like columns remain text.
fixture=(ROOT/'supabase/candidates/analytics_admin_reporting_20261030/local_schema_fixture.sql').read_text()
for table,cols in re.findall(r'create table public\."(\w+)" \((.*?)\);',fixture):
 if not sql(f"select to_regclass('public.{table}')")[0][0]:sql(f'create table public.{table} ({cols})')
 else:
  for col,typ in re.findall(r'"(\w+)" ([^,]+)',cols):sql(f'alter table public.{table} add column if not exists {col} {typ}')
if not sql("select to_regclass('public.feedback_submissions')")[0][0]:file('supabase/migrations/20260917000100_feedback_operations.sql')
if not sql("select to_regnamespace('feedback_private')")[0][0]:file('supabase/candidates/essay_feedback_v1/install.sql')
if not sql("select to_regnamespace('essay_ops_private')")[0][0]:file('supabase/candidates/essay_operations_v1/install.sql')
file('supabase/candidates/analytics_admin_reporting_20261030/precheck.sql')
file('supabase/candidates/analytics_admin_reporting_20261030/apply.sql')
file('supabase/candidates/analytics_admin_reporting_20261030/postcheck.sql')
ok('all six candidate packages coexist (notices/beta/admin/feedback/ops/analytics)')
# Restore the synthetic official-admin stub replaced by the legacy feedback migration.
sql("create or replace function public.admin_operator() returns boolean language sql stable as $$select coalesce(nullif(current_setting('test.admin',true),''),'false')::boolean$$")
sql("set test.actor='00000000-0000-4000-8000-000000000002';set test.admin='true';set role authenticated")
for fn in ['analytics_kpi_overview','analytics_funnel','analytics_free_credit','analytics_revenue','analytics_reliability','analytics_api_cost','analytics_university_usage']:
 r=sql(f"select public.{fn}('2026-11-01','2026-11-12')")[0][0]
 ok(fn+' executes with other candidates')
sql('reset role')
# Exact aggregates under mixed currencies, refunds, multiple-answer runs and unknown costs.
sql('begin')
sql("set test.admin='true';set test.actor='00000000-0000-4000-8000-000000000002'")
def report(n):return sql(f"select public.analytics_{n}('2026-11-01','2026-11-12')")[0][0]
base=report('reliability')['requested']
uid='00000000-0000-4000-8000-000000000002'
a=sql(f"select id from public.credit_accounts where user_id='{uid}'")[0][0]
e=sql('select id from public.essay_exams limit 1')[0][0]
r='88000000-0000-4000-8000-000000000001'
sql(f"insert into essay_exam_private.runs(id,account_id,exam_id,request_key,state,snapshot,created_at,completed_at) values('{r}','{a}','{e}',gen_random_uuid(),'completed','{{\"answers\":[{{}},{{}},{{}}]}}','2026-11-02','2026-11-02')")
ok('three-question exam is exactly one request',report('reliability')['requested']==base+1)
# Legacy duplicate identifier must not double count.
sql(f"insert into public.essay_evaluations(id,status,request_kind,requested_at) values('{r}','completed','student','2026-11-02')")
ok('legacy mirror excluded',report('reliability')['requested']==base+1)
sql(f"insert into essay_exam_private.checkpoints values('{r}','q0-a1-receipt-generation',null,'checkpoint','{{\"provider\":\"fixture\",\"model\":\"fixture\",\"input_tokens\":10,\"output_tokens\":20}}')")
old=report('api_cost')
ok('exam receipt included as UNKNOWN and undated',old['unknown_calls']>=1 and old['undated_calls']>=1)
for i,curr,basis,amt in [(1,'USD','provider_reported',2),(2,'USD','estimate',3),(3,'KRW','provider_reported',7000)]:
 sql(f"insert into public.essay_ai_processing_runs(id,evaluation_id,started_at,provider,model_name,run_no,currency,cost_basis,cost_amount,input_tokens,output_tokens) values(gen_random_uuid(),gen_random_uuid(),'2026-11-02','fixture','fixture',1,'{curr}','{basis}',{amt},10,20)")
cost=report('api_cost')
ok('USD actual/estimated separate; KRW is not added',cost['total_reported_cost']==2 and cost['total_estimated_cost']==3 and cost['unknown_calls']==old['unknown_calls']+1)
for i,curr,state,amount,mode in [(1,'KRW','PARTIALLY_CANCELLED',4900,'LIVE'),(2,'KRW','CANCELLED',11900,'LIVE'),(3,'USD','PAID',10,'LIVE'),(4,'KRW','PAID',100,'TEST')]:
 sql(f"insert into public.payment_orders(id,subject_id,currency,state,amount,mode,paid_at,sku) values('99000000-0000-4000-8000-00000000000{i}','{uid}','{curr}','{state}',{amount},'{mode}','2026-11-02','fixture')")
for i,amount in [(1,2000),(2,11900),(3,10)]:
 sql(f"insert into public.payment_operations(id,order_id,kind,state,reason,amount,completed_at) values(gen_random_uuid(),'99000000-0000-4000-8000-00000000000{i}','CANCEL','SUCCEEDED','GENERAL_REFUND',{amount},'2026-11-03')")
rev=report('revenue')
ok('cancelled paid orders retained; successful KRW refunds deducted once',rev['gross_revenue']==16800 and rev['refunded']==13900 and rev['net_revenue']==2900)
ok('TEST excluded; USD explicitly excluded',rev['paid_orders']==2 and rev['excluded_currency_orders']==1)
ok('credit release is units not cash refund','credit_released_units' in rev and 'credit_refunded_units' in rev)
# All read-only reporting preserves source rows and ledger, even though monitor audit is separate.
def fingerprint():return sql("select md5(jsonb_build_array((select jsonb_agg(to_jsonb(r) order by id) from essay_exam_private.runs r),(select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t))::text)")[0][0]
before=fingerprint()
for n in ['kpi_overview','funnel','free_credit','revenue','reliability','api_cost','university_usage']:report(n)
ok('reports preserve run snapshots/results and Credit ledger',fingerprint()==before)
sql('rollback')
# Role checks are executed in PostgreSQL, not merely client UI assertions.
for role,admin in [('anon',True),('service_role',True),('authenticated',False)]:
 for n in ['kpi_overview','funnel','free_credit','revenue','reliability','api_cost','university_usage']:
  sql(f"set role {role};set test.admin='{str(admin).lower()}'")
  try: report(n)
  except psycopg.Error as ex:assert ex.sqlstate in ('42501','PT403'),ex
  else:raise AssertionError((role,n,'must reject'))
  finally:sql('reset role')
ok('21 non-admin/anon/service-role report calls rejected')
# Rollback newest package first, without deleting original state or operational audit.
before=fingerprint()
file('supabase/candidates/analytics_admin_reporting_20261030/rollback.sql')
ok('analytics rollback preserves ledger and runs',fingerprint()==before)
file('supabase/candidates/analytics_admin_reporting_20261030/apply.sql')
ok('analytics reinstallation after rollback')
