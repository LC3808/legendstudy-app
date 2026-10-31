"""Disposable local PostgreSQL only. Production function bodies; synthetic identities."""
from datetime import datetime,timezone
import concurrent.futures,json,pathlib,subprocess,uuid,os
p=pathlib.Path(__file__).resolve().parent.parent/'essay_beta_daily_v2'
PG='/opt/homebrew/opt/postgresql@17/bin/psql'
cmd=[PG,'-X','-h','127.0.0.1','-p','55439','-U','postgres','-d',os.environ.get('BETA_TEST_DB','beta_admin_task04c'),'-v','ON_ERROR_STOP=1','-Atq']
def sql(s,fail=None):
 r=subprocess.run(cmd,input=s,text=True,capture_output=True)
 if fail: assert r.returncode and fail in r.stderr,(fail,r.stderr);return ''
 assert r.returncode==0,r.stderr
 return r.stdout.strip()
def ok(n,c=True):
 assert c,n
 print('PASS',n,flush=True)
U='00000000-0000-4000-8000-000000000002';E='10000000-0000-4000-8000-000000000001';Q='20000000-0000-4000-8000-000000000001';C='30000000-0000-4000-8000-000000000001'
def at(s,t='2026-11-09T23:59:00+09',role=None,fail=None):
 return sql(f"set test.actor='{U}';set test.clock='{t}';"+(f'set role {role};' if role else '')+s,fail)
sql("do $$begin if not exists(select 1 from pg_roles where rolname='essay_worker') then create role essay_worker;end if;if not exists(select 1 from pg_roles where rolname='essay_executor') then create role essay_executor;end if;end$$;")
sql((p.parent/'admin_credit_operations_20261027/isolated-fixture.sql').read_text())
sql('''create schema essay_exam_private;create schema math_private;
create table public.universities(id uuid primary key,name text);
create table public.essay_exams(id uuid primary key,university_id uuid,admission_year int,exam_name text);
create table public.essay_questions(id uuid primary key,essay_exam_id uuid);
create table public.payment_orders(grant_id uuid,state text);
create table public.essay_billing_decisions(id uuid primary key,account_id uuid,idempotency_key uuid,policy_key text,policy_version text,reason text,credits_required int,status text,reserved_at timestamptz,included_by_decision_id uuid,released_at timestamptz,settled_at timestamptz);
alter table public.credit_transactions add column decision_id uuid;
create table essay_exam_private.runs(id uuid primary key,account_id uuid,exam_id uuid,parent_id uuid,decision_id uuid,request_key uuid,snapshot jsonb,state text,result jsonb,completed_at timestamptz,created_at timestamptz default now(),previous_paid_run_id uuid,submission_index int default 1,unique(account_id,request_key));
create function essay_exam_private.runtime_policy(uuid) returns jsonb language sql as $$select '{"evaluation_type":"humanities","regime":"fixture","package_digest":"fixture"}'::jsonb$$;
create function math_private.require_active(uuid[]) returns void language plpgsql as $$begin if auth.uid() is null or not account_private.allowed(auth.uid()) then raise exception 'ACCOUNT_REQUIRED';end if;end$$;
create function public.essay_exam_preflight(uuid,uuid) returns void language sql as $$select$$;
create function essay_private.uid() returns uuid language sql as $$select auth.uid()$$;
''')
base=json.loads((p.parent/'essay_beta_credit_runtime_20261027/baseline.private.json').read_text())
sql(next(x['definition'] for x in base if x['name']=='credit_post_grant'))
sql((p.parent/'essay_beta_credit_runtime_20261027/runtime.sql').read_text())
for r in json.loads((p/'baseline.json').read_text()):
 sql('set check_function_bodies=off;'+r['definition'])
 # Reproduce verified ACLs, not PostgreSQL's default public EXECUTE.
 ident=f"{r['schema']}.{r['name']}({','.join(a.split()[-1] for a in r['args'].split(','))})" if r['args'] else f"{r['schema']}.{r['name']}()"
 sql(f'revoke all on function {ident} from public,anon,authenticated,service_role;')
 if 'authenticated=' in r['acl']:sql(f'grant execute on function {ident} to authenticated;')
 if 'essay_worker=' in r['acl']:sql(f'grant execute on function {ident} to essay_worker;')
sql((p/'precheck.sql').read_text());sql((p/'install.sql').read_text());ok('production baseline guard + install')
# Boundary clock injection ONLY in this disposable DB; candidate production functions untouched.
for r in json.loads(sql("select json_agg(json_build_object('definition',pg_get_functiondef(p.oid))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('essay_exam_private','essay_beta_private') or (n.nspname='public' and p.proname in ('essay_exam_quote','essay_exam_history','credit_summary'))")):
 sql(r['definition'].replace('clock_timestamp()','essay_private.clock()').replace('statement_timestamp()','essay_private.clock()'))
ok('inactive does not issue',json.loads(at('select public.essay_beta_daily_claim_v2()'))['status']=='inactive')
sql(f"insert into public.universities values('{E}','Fixture');insert into public.essay_exams values('{E}','{E}',2026,'Fixture');insert into public.essay_questions values('{Q}','{E}');")
sql((p.parent/'notices_v1/install.sql').read_text())
notice=json.loads(at("set test.admin='true';select public.notice_admin_save('{\"title\":\"Beta QA\",\"content\":\"Synthetic policy\",\"category\":\"beta\",\"status\":\"published\",\"published_at\":\"2026-10-31T00:00:00+09\"}')"))['notice_id']
activation=(p/'activate.sql').read_text()
at(activation,fail='OWNER_REVIEWED_CONFIGURATION_REQUIRED')
activation=activation.replace('owner_id uuid := null',f"owner_id uuid := '{U}'").replace('notice uuid := null',f"notice uuid := '{notice}'").replace("approval text := ''","approval text := 'synthetic QA'").replace('starts date := null',"starts date := '2026-11-09'")
scope=json.dumps([{'exam_id':E,'runtime_policy':{'evaluation_type':'humanities','regime':'fixture','package_digest':'fixture'},'question_ids':[Q],'has_math':False}])
activation=activation.replace("scope jsonb := '[]'",f"scope jsonb := '{scope}'").replace('clock_timestamp()','essay_private.clock()')
at(activation,fail='ACTIVE_ADMIN_REQUIRED')
at("set test.admin='true';"+activation)
C=sql('select id from essay_beta_private.campaigns')
at("set test.admin='true';"+activation,fail='CAMPAIGN_ALREADY_EXISTS_REVIEW_INSTEAD_OF_REAPPLY')
ok('activation requires admin notice scope and does not issue credit',sql('select count(*) from public.credit_transactions')=='0')


sql("alter table auth.users add column created_at timestamptz default now();create table essay_exam_private.checkpoints(run_id uuid,key text,writer uuid,state text,payload jsonb);create table essay_exam_private.retry_requests(run_id uuid,request_key uuid,generation integer,attempts jsonb,created_at timestamptz,lease_until timestamptz);")
sql((pathlib.Path(__file__).parent/'install.sql').read_text())
print('SETUP',C,U,E,Q)

def admin(s,fail=None,t='2026-11-09T23:59:00+09'):
 return at("set test.admin='true';"+s,t,role='authenticated',fail=fail)
def save(limit=1,mode='immediate',version=0,enabled=True,end='2026-11-11T00:00:00+09',fail=None,t='2026-11-09T23:59:00+09'):
 value=json.dumps(dict(beta_enabled=enabled,beta_start_at='2026-11-09T00:00:00+09',beta_end_at=end,daily_free_limit=limit,reset_timezone='Asia/Seoul',limit_application=mode))
 return admin(f"select public.admin_essay_beta_save('{C}',{version},'{value}','synthetic test');",fail,t)
at('select public.admin_essay_beta_config()',role='authenticated',fail='BETA_ADMIN_REQUIRED')
save(fail='BETA_ADMIN_REQUIRED')
sql(f"insert into essay_beta_private.settings_editors values('{U}','isolated Owner authorization')")
save();ok('owner capability and official admin both required')
save(version=0,fail='SETTINGS_CHANGED_RELOAD');ok('stale configuration rejected')
for name in ['admin_essay_beta_config()','admin_essay_beta_report(\'usage\')']:
 at('select public.'+name,role='anon',fail='permission denied')
 at('select public.'+name,role='service_role',fail='permission denied')
at('select * from essay_beta_private.settings_audit',role='authenticated',fail='permission denied')
ok('public service and raw tables denied')
ok('before start no allocation',json.loads(at('select public.essay_beta_daily_claim_v2()',t='2026-11-08T23:59:59+09'))['status']=='inactive')
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
 claims=list(pool.map(lambda _:json.loads(at('select public.essay_beta_daily_claim_v2()',role='authenticated')),range(30)))
ok('30 concurrent claims one grant',len({x['grant_id'] for x in claims})==1 and all(x['available']==1 for x in claims))
G=claims[0]['grant_id'];A=sql(f"select id from public.credit_accounts where user_id='{U}'")
save(2,version=1,fail='TODAY_GRANTED_USE_NEXT_RESET')
save(2,'next_reset',1);ok('limit change scheduled and issued amount preserved',json.loads(at('select public.essay_beta_daily_claim_v2()'))['daily_limit']==1)
nextday=json.loads(at('select public.essay_beta_daily_claim_v2()',t='2026-11-10T00:00:00+09'))
ok('KST midnight allocates 2 without rollover',nextday['available']==2 and nextday['daily_limit']==2 and nextday['grant_id']!=G)
G=nextday['grant_id']
# Reuse real reserve/finish with synthetic input, never Provider.
snap=json.dumps({'answers':[{'questionId':Q,'body':'synthetic','revision':0,'rubricVersion':'v','evidenceVersion':'v'}]})
def reserve(key,g=G,parent=None,t='2026-11-10T01:00:00+09',fail=None):
 return at(f"select set_config('legendstudy.confirmed_credit_grant','{g}',false);select essay_exam_private.reserve('{A}','{E}','{key}','{snap}',"+(f"'{parent}'" if parent else 'null')+");",t,fail=fail).splitlines()[-1] if not fail else at(f"select set_config('legendstudy.confirmed_credit_grant','{g}',false);select essay_exam_private.reserve('{A}','{E}','{key}','{snap}',"+(f"'{parent}'" if parent else 'null')+");",t,fail=fail)
key=str(uuid.uuid4());R=reserve(key)
ok('same request idempotent',reserve(key)==R)
print('RUN',R)
ok('usage query executes',len(json.loads(admin("select public.admin_essay_beta_report('usage')",t='2026-11-10T01:00:00+09'))['rows'])==2)
sql(f"update essay_exam_private.runs set state='failed' where id='{R}'") # Synthetic fixture only.
ok('pending recovery truthfully reported',json.loads(admin("select public.admin_essay_beta_report('failures')"))['rows'][0]['operation_status']=='recovery_pending')
sql(f"update essay_exam_private.runs set state='reserved' where id='{R}'")
at(f"select essay_exam_private.finish('{R}',null,true)",t='2026-11-10T01:00:00+09')
at(f"select essay_exam_private.finish('{R}',null,true)",t='2026-11-10T01:00:00+09')
ok('one release after repeated finish',sql("select count(*) from public.credit_transactions where transaction_type='release'")=='1')
ok('automatic recovery reported',json.loads(admin("select public.admin_essay_beta_report('failures')"))['rows'][0]['recovery_method']=='automatic')
before=sql("select md5(string_agg(row_to_json(t)::text,'' order by id)) from public.credit_transactions t")
save(2,version=2,enabled=False,t='2026-11-10T01:00:00+09')
ok('disabled claim does not allocate',json.loads(at('select public.essay_beta_daily_claim_v2()',t='2026-11-10T01:00:00+09'))['status']=='inactive')
ok('settings and reports do not modify ledger',before==sql("select md5(string_agg(row_to_json(t)::text,'' order by id)) from public.credit_transactions t"))
ok('audit exactly successful changes',sql('select count(*) from essay_beta_private.settings_audit')=='3')
sql('delete from essay_beta_private.settings_audit',fail='BETA_GRANT_BINDING_IMMUTABLE')
save(2,version=3,enabled=True,t='2026-11-10T01:00:00+09')
ok('end exclusive',json.loads(at('select public.essay_beta_daily_claim_v2()',t='2026-11-11T00:00:00+09'))['status']=='ended')

# Settlement and free-child completion remain valid after the current cutoff.
R3=reserve(str(uuid.uuid4()));result=json.dumps({'summary':'fixture','questions':[{'questionId':Q,'rubricVersion':'v','evidenceVersion':'v','evaluation':{'fixture':True}}]})
at(f"select essay_exam_private.finish('{R3}','{result}');")
parent_before=sql(f"select md5(row_to_json(r)::text) from essay_exam_private.runs r where id='{R3}'")
quote=json.loads(at(f"select public.essay_exam_quote('{U}','{E}',array['{Q}']::uuid[],'{R3}')",'2026-11-10T23:59:59+09'))
ok('free revision included zero',quote['kind']=='included' and quote['credits']==0)
key=str(uuid.uuid4());child=reserve(key,parent=R3,t='2026-11-10T23:59:59+09')
ok('accepted child replay after end',reserve(key,parent=R3,t='2026-11-11T00:00:00+09')==child)
at(f"select essay_exam_private.finish('{child}','{result}');",'2026-11-11T00:01:00+09')
ok('accepted child finishes after end',sql(f"select state from essay_exam_private.runs where id='{child}'")=='completed')
at(f"select public.essay_exam_quote('{U}','{E}',array['{Q}']::uuid[],'{R3}')",'2026-11-11T00:00:00+09',fail='REEVALUATION_NOT_INCLUDED')
ok('existing parent answer result digest unchanged',parent_before==sql(f"select md5(row_to_json(r)::text) from essay_exam_private.runs r where id='{R3}'"))
for origin,amount in [('purchase',4),('signup_bonus',3)]:at(f"select essay_private.credit_post_grant('{U}',{amount},'{origin}','fixture-{origin}','fixture','fixture',null)")
ok('paid/signup balance separate',json.loads(at('select public.credit_summary()'))['spendable']==7)
paid=sql("select id from public.credit_grants where origin='purchase'")
paidrun=reserve(str(uuid.uuid4()),g=paid,t='2026-11-11T00:00:00+09');at(f"select essay_exam_private.finish('{paidrun}','{result}');",'2026-11-11T00:01:00+09')
rev=reserve(str(uuid.uuid4()),parent=paidrun,t='2026-11-20T00:00:00+09')
ok('paid 14 day revision unaffected by beta end',sql(f"select credits_required from public.essay_billing_decisions where id=(select decision_id from essay_exam_private.runs where id='{rev}')")=='0')
# Feature-off rollback audits and keeps all ledger/history rows.
ledger_before=sql("select md5(string_agg(row_to_json(t)::text,'' order by id)) from public.credit_transactions t")
at("set test.admin='true';"+(pathlib.Path(__file__).parent/'rollback.sql').read_text().replace('begin;','').replace('commit;',''))
ok('rollback disables without ledger mutation',ledger_before==sql("select md5(string_agg(row_to_json(t)::text,'' order by id)) from public.credit_transactions t") and json.loads(at('select public.essay_beta_daily_claim_v2()'))['status']=='inactive')
