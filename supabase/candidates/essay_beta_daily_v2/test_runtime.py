"""Disposable local PostgreSQL only. Production function bodies; synthetic identities."""
from datetime import datetime,timezone
import concurrent.futures,json,pathlib,subprocess,uuid,os
p=pathlib.Path(__file__).parent
PG='/opt/homebrew/opt/postgresql@17/bin/psql'
cmd=[PG,'-X','-h','127.0.0.1','-p','55439','-U','postgres','-d','beta_v2_test','-v','ON_ERROR_STOP=1','-Atq']
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
manifest=sql("select json_agg(json_build_object('identity',p.oid::regprocedure::text,'digest',md5(pg_get_functiondef(p.oid)),'owner',pg_get_userbyid(proowner),'acl',proacl::text)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='essay_beta_private' or (n.nspname='essay_exam_private' and p.proname in ('reserve','finish')) or (n.nspname='public' and p.proname in ('credit_summary','essay_exam_history','essay_exam_quote','essay_beta_daily_claim','essay_beta_daily_claim_v2','essay_beta_notice_ack'))")
(p/'expected-functions.json').write_text(json.dumps(json.loads(manifest),ensure_ascii=False,indent=2)+'\n')
subprocess.run(['python3',str(p/'build.py')],check=True)
sql((p/'verify.sql').read_text())
ok('install definition owner ACL manifest verification')
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

with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
 claims=list(pool.map(lambda _:json.loads(at('select public.essay_beta_daily_claim_v2()',role='authenticated')),range(60)))
G=claims[0]['grant_id'];A=sql(f"select id from public.credit_accounts where user_id='{U}'")
ok('60 APP/WEB concurrent claims one daily grant',len({x['grant_id'] for x in claims})==1 and all(x['available']==1 for x in claims))
ok('23:59 expiry is next KST midnight',datetime.fromisoformat(claims[0]['expires_at']).astimezone(timezone.utc).isoformat()=='2026-11-09T15:00:00+00:00')
ok('cutoff is November 11 00:00 KST',datetime.fromisoformat(claims[0]['ends_at']).astimezone(timezone.utc).isoformat()=='2026-11-10T15:00:00+00:00')
sql(f"update essay_beta_private.campaigns set ends_on='2026-11-11' where id='{C}'",fail='BETA_ISSUED_POLICY_IMMUTABLE')
at(f"select public.essay_beta_notice_ack('{C}')",role='authenticated')
ok('notice ack sync + idempotency',json.loads(at('select public.essay_beta_daily_claim_v2()',role='authenticated'))['notice_seen'])
at(f"select public.essay_beta_notice_ack('{C}')",role='authenticated')
ok('single notice receipt',sql('select count(*) from essay_beta_private.notice_receipts')=='1')
at('select public.essay_beta_daily_claim_v2()',role='anon',fail='permission denied')
at('select * from essay_beta_private.daily_grants',role='authenticated',fail='permission denied')
at('select public.essay_beta_daily_claim_v2()',role='service_role',fail='permission denied')
ok('anon/service role and raw-table access denied')
for origin,amount in [('purchase',4),('signup_bonus',3)]:at(f"select essay_private.credit_post_grant('{U}',{amount},'{origin}','fixture-{origin}','fixture','fixture',null)")
ok('beta not mixed with spendable/signup/paid',json.loads(at('select public.credit_summary()'))['spendable']==7)
snap=json.dumps({'answers':[{'questionId':Q,'body':'synthetic','revision':0,'rubricVersion':'v','evidenceVersion':'v'}]})
result=json.dumps({'summary':'fixture','questions':[{'questionId':Q,'rubricVersion':'v','evidenceVersion':'v','evaluation':{'fixture':True}}]})
def reserve(key,g=G,parent=None,t='2026-11-09T23:59:00+09',fail=None):
 return at(f"select set_config('legendstudy.confirmed_credit_grant','{g}',false);select essay_exam_private.reserve('{A}','{E}','{key}','{snap}',"+(f"'{parent}'" if parent else 'null')+");",t,fail=fail).splitlines()[-1] if not fail else at(f"select set_config('legendstudy.confirmed_credit_grant','{g}',false);select essay_exam_private.reserve('{A}','{E}','{key}','{snap}',"+(f"'{parent}'" if parent else 'null')+");",t,fail=fail)
key=str(uuid.uuid4());R=reserve(key)
ok('same request replay one reservation',reserve(key)==R and sql("select count(*) from public.credit_transactions where transaction_type='reserve'")=='1')
reserve(str(uuid.uuid4()),fail='CREDIT_SOURCE_CHANGED')
ok('second device cannot spend same daily allowance or silently charge paid')
ok('reserved reports zero',json.loads(at('select public.essay_beta_daily_claim_v2()'))['available']==0)
# Failed/partial question checkpoint alone never releases a whole exam reservation.
ok('pending partial run retains reservation',sql(f"select sum(reserved_delta) from public.credit_transactions where grant_id='{G}'")=='1')
at(f"select essay_exam_private.finish('{R}',null,true);select essay_exam_private.finish('{R}',null,true);")
ok('terminal failure restores exactly once',json.loads(at('select public.essay_beta_daily_claim_v2()'))['available']==1 and sql("select count(*) from public.credit_transactions where transaction_type='release'")=='1')
R=reserve(str(uuid.uuid4()));at(f"select essay_exam_private.finish('{R}','{result}');")
G2=json.loads(at('select public.essay_beta_daily_claim_v2()','2026-11-10T00:00:00+09'))['grant_id']
ok('00:00 renewed, next day reusable, no carryover',G2!=G and json.loads(at('select public.essay_beta_daily_claim_v2()','2026-11-10T00:00:00+09'))['available']==1)
# Unused old balance restored AFTER midnight cannot become current-day credit.
R2=reserve(str(uuid.uuid4()),g=G2,t='2026-11-10T00:00:01+09')
at(f"select essay_exam_private.finish('{R2}',null,true);",'2026-11-11T00:00:01+09')
ok('late failure does not extend beta/grant',json.loads(at('select public.essay_beta_daily_claim_v2()','2026-11-11T00:00:01+09'))['status']=='ended')
quote=json.loads(at(f"select public.essay_exam_quote('{U}','{E}',array['{Q}']::uuid[],'{R}')",'2026-11-10T23:59:59+09'))
ok('quote included zero and cutoff minimum',quote['kind']=='included' and quote['credits']==0 and datetime.fromisoformat(quote['free_rewrite_expires_at'])==datetime.fromisoformat('2026-11-11T00:00:00+09:00'))
at(f"select public.essay_exam_quote('{U}','{E}',array['{Q}']::uuid[],'{R}')",'2026-11-11T00:00:00+09',fail='REEVALUATION_NOT_INCLUDED')
ok('quote and reserve both reject new revision at cutoff')
childkey=str(uuid.uuid4());child=reserve(childkey,parent=R,t='2026-11-10T23:59:59+09')
ok('accepted revision replays after cutoff',reserve(childkey,parent=R,t='2026-11-11T00:00:00+09')==child)
at(f"select essay_exam_private.finish('{child}','{result}');",'2026-11-11T00:01:00+09')
ok('precutoff revision finishes after cutoff',sql(f"select state from essay_exam_private.runs where id='{child}'")=='completed')
reserve(str(uuid.uuid4()),parent=R,t='2026-11-11T00:00:00+09',fail='REEVALUATION_NOT_INCLUDED')
ok('new beta revision blocked at exact cutoff')
ok('history uses same cutoff',not json.loads(at(f"select public.essay_exam_history('{R}')",'2026-11-11T00:00:00+09'))['runs'][0]['free_rewrite_available'])
# Non-beta originals and their old 14-day contract remain valid after beta ends.
paid=sql("select id from public.credit_grants where origin='purchase'")
new=reserve(str(uuid.uuid4()),g=paid,t='2026-11-11T00:00:00+09');at(f"select essay_exam_private.finish('{new}','{result}');",'2026-11-11T00:01:00+09')
rev=reserve(str(uuid.uuid4()),parent=new,t='2026-11-20T00:00:00+09')
ok('purchased original revision still free after beta',sql(f"select credits_required from public.essay_billing_decisions where id=(select decision_id from essay_exam_private.runs where id='{rev}')")=='0')
reserve(str(uuid.uuid4()),parent=new,t='2026-11-26T00:00:00+09',fail='REEVALUATION_NOT_INCLUDED')
ok('non-beta 14day limit retained')
ok('signup untouched and paid charged only explicit original',sql("select string_agg(origin||':'||balance,',' order by origin) from (select g.origin,sum(t.balance_delta) balance from public.credit_grants g join public.credit_transactions t on t.grant_id=g.id where g.origin in ('signup_bonus','purchase') group by g.origin) x")=='purchase:3,signup_bonus:3')
ok('beta original consumed exactly once',sql(f"select sum(balance_delta) from public.credit_transactions where grant_id='{G}'")=='0')
ok('original answer and result preserved',json.loads(sql(f"select snapshot from essay_exam_private.runs where id='{R}'"))==json.loads(snap) and json.loads(sql(f"select result from essay_exam_private.runs where id='{R}'"))==json.loads(result))

# Many accepted submissions share the account lock; only one generation reserves.
claims=json.loads(at('select public.essay_beta_daily_claim_v2()','2026-11-10T12:00:00+09'))
# Test grant was released after end; time travel is confined to this disposable clock.
def simultaneous(_):
 try:return reserve(str(uuid.uuid4()),g=G2,t='2026-11-10T12:00:00+09')
 except AssertionError as error:
  assert 'CREDIT_SOURCE_CHANGED' in str(error),str(error)
  return None
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool: raced=list(pool.map(simultaneous,range(30)))
ok('30 concurrent distinct submissions exactly one reserve',sum(x is not None for x in raced)==1)
reserved=next(x for x in raced if x)
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:list(pool.map(lambda _:at(f"select essay_exam_private.finish('{reserved}',null,true);",'2026-11-10T12:01:00+09'),range(30)))
ok('30 concurrent failure callbacks restore once',json.loads(at('select public.essay_beta_daily_claim_v2()','2026-11-10T12:01:00+09'))['available']==1)
# Scope cannot silently expand to mathematics or another question set.
sql(f"update essay_beta_private.exam_scope set has_math=true,owner_math_qa_reference='synthetic existing QA' where campaign_id='{C}'")
ok('math scope cannot spend beta',at(f"select essay_beta_private.eligible('{G2}','{E}')",'2026-11-10T12:01:00+09')=='f')
sql(f"update essay_beta_private.exam_scope set has_math=false where campaign_id='{C}'")
before=sql('select count(*) from public.credit_transactions')
sql((p/'rollback.sql').read_text())
ok('rollback stops future claim without ledger mutation',json.loads(at('select public.essay_beta_daily_claim_v2()'))['status']=='inactive' and sql('select count(*) from public.credit_transactions')==before)
