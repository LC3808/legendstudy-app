import os
assert os.environ.get("TASK04B_ISOLATED") == "1", "Use run_isolated.py; never production"
import subprocess,json,pathlib,time
PG='/opt/homebrew/opt/postgresql@17/bin/'
subprocess.run([PG+'createdb','-h','127.0.0.1','-p','55450','-U','postgres','task04b_home'],check=True)
P=[PG+'psql','-X','-h','127.0.0.1','-p','55450','-U','postgres','-d','task04b_home','-Atq','-v','ON_ERROR_STOP=1']
def sql(s,ok=True):
 r=subprocess.run(P,input=s,text=True,capture_output=True)
 if ok and r.returncode:raise RuntimeError(r.stderr)
 return r
root=pathlib.Path(__file__).resolve().parents[3];out=pathlib.Path(__file__).resolve().parent
bootstrap=(root/'supabase/candidates/task04_home_20261111/isolated_bootstrap.sql').read_text().split('\n',1)[1]
lifecycle=(root/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text();functions=lifecycle[lifecycle.index('create function account_private.lock_subject'):lifecycle.index('create function account_private.guard_request')]
sql(bootstrap+"create schema account_private;create table public.account_deletion_requests(subject_id uuid,state text);"+functions+"alter default privileges in schema public grant all on tables to anon,authenticated,service_role;alter default privileges in schema public grant execute on functions to anon,authenticated,service_role;")
print(sql("select md5(pg_get_functiondef('account_private.allowed(uuid)'::regprocedure)),md5(pg_get_functiondef('account_private.lock_subject(uuid)'::regprocedure));").stdout)
sql((out/'apply_a_home.sql').read_text())
U='00000000-0000-0000-0000-000000000001';V='00000000-0000-0000-0000-000000000002';D='00000000-0000-0000-0000-000000000003'
def auth(u=U):return f"set role authenticated;set request.jwt.claim.sub='{u}';"
call="select public.save_my_home_configuration('{\"config_version\":1,\"cards\":[]}',0);"
checks={};sql(f"insert into auth.users values('{U}'),('{V}');")
assert sql(auth()+'select public.my_home_configuration() is null;').stdout.strip()=='t'
assert json.loads(sql(auth()+call).stdout)['revision']==1
assert json.loads(sql(auth()+call).stdout)['revision']==1
assert sql(auth(V)+'select public.my_home_configuration() is null;').stdout.strip()=='t'
checks['normal_new_and_existing_accounts']='PASS unset -> first save -> identical retry, cross-account read null'
for state in ['DELETION_PENDING','ERASING']:
 sql(f"truncate public.account_deletion_requests;insert into public.account_deletion_requests values('{U}','{state}');")
 for cmd in [call,'select public.my_home_configuration();']:
  r=sql(auth()+cmd,False);assert r.returncode and 'insufficient_privilege' in r.stderr,r.stderr
 checks[state]='PASS read and save rejected'
for uid in ['',D]:
 r=sql(auth(uid)+call,False);assert r.returncode
checks['missing_or_deleted_user']='PASS rejected'
for role in ['anon','authenticated']:
 for stmt in ['select * from','insert into','update','delete from','truncate']:
  tail={'select * from':'','insert into':' default values','update':" set config_version=1",'delete from':'','truncate':''}[stmt]
  r=sql(f'set role {role};{stmt} public.home_configuration_revisions{tail};',False);assert r.returncode and 'permission denied' in r.stderr,r.stderr
checks['table_crud_and_truncate']='PASS denied both client roles'
r=sql('set role anon;'+call,False);assert r.returncode and 'permission denied' in r.stderr
checks['anonymous_rpc']='PASS denied'
# With a local, rolled-back SELECT grant, pending owner sees 0; active owner sees 1; other owner sees 0.
def rls(uid):return sql('begin;grant select on public.home_configuration_revisions to authenticated;grant usage on schema auth to authenticated;'+auth(uid)+'select count(*) from public.home_configuration_revisions;rollback;').stdout.strip()
assert rls(U)=='0';sql('truncate public.account_deletion_requests;');assert rls(U)=='1' and rls(V)=='0'
checks['rls_predicate']='PASS owner plus lifecycle gate independently tested'
# Lifecycle commits pending while saver is waiting on the exact existing subject lock.
p=subprocess.Popen(P,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
p.stdin.write(f"begin;select account_private.lock_subject('{U}');insert into public.account_deletion_requests values('{U}','DELETION_PENDING');select 'READY';select pg_sleep(1.2);commit;\n");p.stdin.close()
while p.stdout.readline().strip()!='READY': pass
r=sql(auth()+call,False);assert r.returncode and 'insufficient_privilege' in r.stderr;assert p.wait()==0
checks['lifecycle_concurrent_commit']='PASS waiting save observes pending state and refuses write'
sql('truncate public.account_deletion_requests;truncate public.home_configuration_revisions;')
for same in [True,False]:
 sql('truncate public.home_configuration_revisions;')
 p=subprocess.Popen(P,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 p.stdin.write('begin;'+auth()+call+'select pg_sleep(1.2);commit;');p.stdin.close();assert json.loads(p.stdout.readline())['revision']==1
 other=call if same else "select public.save_my_home_configuration('{\"config_version\":1,\"cards\":[{\"card_id\":\"dday\",\"visible\":false,\"display_order\":0}]}',0);"
 r=sql(auth()+other,False)
 assert (r.returncode==0 and json.loads(r.stdout)['revision']==1) if same else (r.returncode!=0 and 'Configuration changed' in r.stderr)
 assert p.wait()==0
checks['concurrent_cas_and_idempotence']='PASS same payload one revision; different payload stale rejected'
before=sql('select md5(jsonb_agg(to_jsonb(h) order by user_id,revision)::text) from public.home_configuration_revisions h;').stdout
sql((out/'disable_a_home.sql').read_text());r=sql(auth()+call,False);assert r.returncode and 'permission denied' in r.stderr
assert before==sql('select md5(jsonb_agg(to_jsonb(h) order by user_id,revision)::text) from public.home_configuration_revisions h;').stdout
sql((out/'restore_a_home.sql').read_text());assert json.loads(sql(auth()+'select public.my_home_configuration();').stdout)['revision']==1
checks['soft_rollback_restore']='PASS execute revoked/restored, complete row digest unchanged'
sql(f"delete from auth.users where id='{U}';");assert sql('select count(*) from public.home_configuration_revisions;').stdout.strip()=='0'
checks['auth_deletion_cascade']='PASS all own revisions erased'
for f in ['preflight_readonly.sql','verify_a_readonly.sql']:
 sql((out/f).read_text())
checks['readonly_validation_sql']='PASS parsed and ran on isolated candidate database'
(pathlib.Path(os.environ['TASK04B_RESULTS'])/'revised-a-local-results.json').write_text(json.dumps(checks,indent=2));print(json.dumps(checks,indent=2))
