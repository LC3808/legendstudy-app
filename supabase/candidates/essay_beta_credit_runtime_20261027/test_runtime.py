"""LOCAL disposable Postgres only. Synthetic accounts; no Provider or remote DB."""
import concurrent.futures,json,pathlib,re,subprocess,uuid,os
root=pathlib.Path(__file__).parent
port=os.environ.get('BETA_TEST_PORT','55449')
assert port!='5432'
cmd=['/opt/homebrew/bin/psql','-X','-h','127.0.0.1','-p',port,'-d',os.environ.get('BETA_TEST_DB','postgres'),'-v','ON_ERROR_STOP=1','-Atq']
def sql(s,fail=None):
 p=subprocess.run(cmd,input=s,text=True,capture_output=True)
 if fail:
  assert p.returncode and fail in p.stderr,(fail,p.stderr)
  return
 assert p.returncode==0,p.stderr
 return p.stdout.strip()
def ok(name,cond):
 assert cond,name
 print('PASS',name,flush=True)
def actor(s,u='00000000-0000-4000-8000-000000000002',clock=None):
 return sql(f"set test.actor='{u}';"+(f"set test.clock='{clock}';" if clock else '')+s)
U='00000000-0000-4000-8000-000000000002'
E='10000000-0000-4000-8000-000000000001'; Q='20000000-0000-4000-8000-000000000001'
C='30000000-0000-4000-8000-000000000001'
sql("do $$begin if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated;create role anon;create role service_role;create role essay_worker;end if;end $$;")
sql((root.parent/'admin_credit_operations_20261027/isolated-fixture.sql').read_text())
sql('''create schema essay_exam_private;create schema math_private;
create table public.essay_exams(id uuid primary key);
create table public.essay_questions(id uuid primary key,essay_exam_id uuid references public.essay_exams);
create table public.essay_billing_decisions(id uuid primary key,account_id uuid,idempotency_key uuid,policy_key text,policy_version text,reason text,credits_required int,status text,reserved_at timestamptz,included_by_decision_id uuid,released_at timestamptz,settled_at timestamptz);
alter table public.credit_transactions add column decision_id uuid;
create table essay_exam_private.runs(id uuid primary key,account_id uuid,exam_id uuid,parent_id uuid,decision_id uuid,request_key uuid,snapshot jsonb,state text,result jsonb,completed_at timestamptz,unique(account_id,request_key));
create function essay_exam_private.runtime_policy(uuid) returns jsonb language sql as $$select '{"evaluation_type":"humanities","regime":"fixture","package_digest":"fixture"}'::jsonb$$;
''')
base=json.loads((root/'baseline.private.json').read_text())
for row in base:
 if row['name'] in ('credit_post_grant','finish'): sql(row['definition'])
# Install all actual allocator definitions without invoking unrelated engines.
sql('set check_function_bodies=off;'+(root/'allocators-baseline.sql').read_text())
sql('set check_function_bodies=off;'+(root/'apply.sql').read_text())
ok('all eleven initial postchecks', all(v=='t' for v in sql((root/'postcheck.sql').read_text()).split('|')))
ok('guarded apply rejects duplicate schema/modified baseline', sql("select to_regnamespace('essay_beta_private') is not null")=='t')
sql('set check_function_bodies=off;'+(root/'apply.sql').read_text(),fail='BASELINE_CHANGED')
ok('inactive campaign does not issue grants',json.loads(actor('select public.essay_beta_daily_claim()'))['active']==False)
sql(f"insert into public.essay_exams values('{E}');insert into public.essay_questions values('{Q}','{E}');insert into essay_beta_private.campaigns values('{C}',(clock_timestamp() at time zone 'Asia/Seoul')::date,(clock_timestamp() at time zone 'Asia/Seoul')::date+4,true,'{U}',clock_timestamp());insert into essay_beta_private.exam_scope values('{C}','{E}',essay_exam_private.runtime_policy('{E}'),array['{Q}'::uuid],false,null,'synthetic QA');")
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
 responses=list(pool.map(lambda _:json.loads(actor('select public.essay_beta_daily_claim()')),range(100)))
G=responses[0]['grant_id']
ok('100 concurrent claims produce one grant',len({x['grant_id'] for x in responses})==1)
ok('exactly two credits posted',sql(f"select sum(balance_delta) from public.credit_transactions where grant_id='{G}'")=='2')
ok('KST next midnight exclusive',sql(f"select expires_at=((created_at at time zone 'Asia/Seoul')::date+1)::timestamp at time zone 'Asia/Seoul' from public.credit_grants where id='{G}'")=='t')
A=sql(f"select id from public.credit_accounts where user_id='{U}'")
ok('scope accepts full approved exam',sql(f"select essay_beta_private.eligible('{G}','{E}')")=='t')
ok('scope rejects other exam',sql(f"select essay_beta_private.eligible('{G}','{uuid.uuid4()}')")=='f')
sql(f"insert into public.essay_questions values('{uuid.uuid4()}','{E}');")
ok('whole exam change blocks beta',sql(f"select essay_beta_private.eligible('{G}','{E}')")=='f')
sql(f"delete from public.essay_questions where id<>'{Q}';")
sql(f"update essay_beta_private.exam_scope set has_math=true,owner_math_qa_reference=null where exam_id='{E}'",fail='check constraint')
ok('mixed scope requires Owner QA',True)
sql(f"update essay_beta_private.daily_grants set grant_day=grant_day+1 where grant_id='{G}'",fail='BETA_GRANT_BINDING_IMMUTABLE')
ok('grant binding immutable',True)
# Existing paid grant expires SOONER than beta: beta must nevertheless be selected first.
actor(f"select essay_private.credit_post_grant('{U}',3,'purchase','fixture-paid','fixture','fixture',clock_timestamp()+interval '10 minutes');")
snap={'answers':[{'questionId':Q,'body':'synthetic fixture','revision':0,'rubricVersion':'fixture','evidenceVersion':'fixture'}]}
S=json.dumps(snap); key=str(uuid.uuid4())
R=sql(f"select essay_exam_private.reserve('{A}','{E}','{key}','{S}');")
ok('beta precedes earlier-expiring purchased grant',sql(f"select grant_id from public.credit_transactions where decision_id=(select decision_id from essay_exam_private.runs where id='{R}')")==G)
ok('same request replay uses original reservation',sql(f"select essay_exam_private.reserve('{A}','{E}','{key}','{S}');")==R)
ok('replay has no additional reserve',sql("select count(*) from public.credit_transactions where transaction_type='reserve'")=='1')
# Exercise existing finish, including complete output membership and immutable history.
result={'summary':'fixture','questions':[{'questionId':Q,'rubricVersion':'fixture','evidenceVersion':'fixture','evaluation':{'fixture':True}}]}
sql(f"select essay_exam_private.finish('{R}','{json.dumps(result)}');")
sql(f"select essay_exam_private.finish('{R}','{json.dumps(result)}');")
ok('finish consumes exactly one',sql(f"select sum(balance_delta) from public.credit_transactions where grant_id='{G}'")=='1')
R2=sql(f"select essay_exam_private.reserve('{A}','{E}','{uuid.uuid4()}','{S}','{R}');")
ok('free rewrite reserves no credit',sql(f"select count(*) from public.credit_transactions where decision_id=(select decision_id from essay_exam_private.runs where id='{R2}')")=='0')
sql(f"select essay_exam_private.reserve('{A}','{E}','{uuid.uuid4()}','{S}','{R}');",fail='REEVALUATION_ALREADY_USED')
ok('free rewrite allowance unchanged',True)
sql(f"select essay_exam_private.finish('{R2}',null,true);")
R3=sql(f"select essay_exam_private.reserve('{A}','{E}','{uuid.uuid4()}','{S}');")
sql(f"select essay_exam_private.finish('{R3}',null,true);select essay_exam_private.finish('{R3}',null,true);")
ok('failure releases once',sql(f"select sum(reserved_delta) from public.credit_transactions where grant_id='{G}'")=='0')
ok('failure preserves remaining beta balance',sql(f"select sum(balance_delta) from public.credit_transactions where grant_id='{G}'")=='1')
ok('paid grant untouched',sql("select sum(t.balance_delta) from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id where g.origin='purchase'")=='3')
# Exercise the precise changed SELECTs in all five legacy/Math allocators.
for row in base:
 if row['name'] not in ('credit_request_v2','scaffold_request_v13','scaffold_legacy_essay_request_evaluation','authorize_billing','math_session_submit'): continue
 after=(root/'allocators.sql').read_text(); start=after.index('FUNCTION '+row['schema']+'.'+row['name']+'(')
 segment=after[start:]; m=re.search(r'select g.id into (?:grant_id|selected_grant) from public.credit_grants.*?;',segment,re.S)
 query=re.sub(r' into (grant_id|selected_grant)','',m[0]).replace('g.account_id=account',f"g.account_id='{A}'")
 ok(row['name']+' excludes beta',sql(query)!=G)
sql("set role anon;select public.essay_beta_daily_claim();",fail='permission denied')
sql("set role authenticated;select public.essay_beta_daily_claim();",fail='ACCOUNT_REQUIRED')
sql(f"set role authenticated;set test.actor='{U}';select * from essay_beta_private.daily_grants;",fail='permission denied')
ok('unauthenticated and private-table access blocked',True)
sql(f"set test.actor='{U}';set test.allowed='false';select public.essay_beta_daily_claim();",fail='ACCOUNT_REQUIRED')
ok('restricted account blocked',True)
# A reserved grant may expire before finalization. Alter fixture expiry only;
# production grants and finance history are never edited by the implementation.
R4=sql(f"select essay_exam_private.reserve('{A}','{E}','{uuid.uuid4()}','{S}');")
sql(f"update public.credit_grants set expires_at=clock_timestamp()-interval '1 second' where id='{G}';")
sql(f"select essay_exam_private.finish('{R4}','{json.dumps(result)}');")
ok('reserved credit settles after expiry',sql(f"select sum(balance_delta) from public.credit_transactions where grant_id='{G}'")=='0')
ok('expired beta never selectable',sql(f"select essay_beta_private.eligible('{G}','{E}')")=='f')
# Clock injection is LOCAL fixture only: actual production clock function is unchanged.
nowday=responses[0]['day']; day2=sql(f"select '{nowday}'::date+1")
g2=json.loads(actor('select public.essay_beta_daily_claim()',clock=day2+' 00:00:00+09'))
ok('next KST day grants a distinct two',g2['grant_id']!=G and g2['available']==2)
ok('old-day beta blocked',sql(f"set test.clock='{day2} 00:00:00+09';select essay_beta_private.eligible('{G}','{E}');")=='f')
sql((root/'rollback.sql').read_text())
ok('safe shutdown stops claims',json.loads(actor('select public.essay_beta_daily_claim()'))['active']==False)
ok('shutdown retains completed history',sql(f"select state from essay_exam_private.runs where id='{R}'")=='completed')
ok('shutdown preserves grants',sql('select count(*) from essay_beta_private.daily_grants')=='2')
print('LOCAL INTEGRATION COMPLETE; Production untouched.')
