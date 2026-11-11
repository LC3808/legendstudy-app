import os
assert os.environ.get("TASK04B_ISOLATED") == "1", "Use run_isolated.py; never production"
import subprocess,json,time,pathlib
P=['/opt/homebrew/opt/postgresql@17/bin/psql','-X','-h','127.0.0.1','-p','55450','-U','postgres','-d','postgres','-Atq','-v','ON_ERROR_STOP=1']
def sql(s,ok=True):
 r=subprocess.run(P,input=s,text=True,capture_output=True)
 if ok and r.returncode:raise RuntimeError(r.stderr)
 return r
U='00000000-0000-0000-0000-000000000001';V='00000000-0000-0000-0000-000000000002';Q='00000000-0000-0000-0000-000000000010'
def auth(u=U):return f"set role authenticated;set request.jwt.claim.sub='{u}';"
cfg='{"config_version":1,"cards":[]}'
call=f"select public.save_my_home_configuration('{cfg}',0);"
results={}
sql(f"insert into auth.users values('{U}'),('{V}');create schema account_private;create table public.account_deletion_requests(subject_id uuid,state text);create function account_private.allowed(u uuid) returns boolean language sql stable security definer set search_path='' as $$select u is not null and exists(select 1 from auth.users where id=u) and not exists(select 1 from public.account_deletion_requests where subject_id=u and state in ('DELETION_PENDING','ERASING'))$$;create function account_private.lock_subject(u uuid) returns void language sql volatile security definer set search_path='' as $$select pg_advisory_xact_lock(hashtextextended(u::text,84612))$$;")
for role in ['anon','authenticated']:
 for table in ['home_configuration_revisions','university_official_sources','university_news_revisions']:
  for statement in [f'select * from public.{table}',f'delete from public.{table}',f'insert into public.{table} default values']:
   r=sql(f'set role {role};'+statement+';',False);assert r.returncode and 'permission denied' in r.stderr,(role,statement,r.stderr)
results['direct_client_table_access']='DENIED both roles SELECT/INSERT/DELETE on 3 tables'
r=sql('set role anon;'+call,False);assert r.returncode and 'permission denied' in r.stderr
results['anonymous_rpc']='DENIED'
# Hold the first transaction after its insert. Second save begins while lock held.
p=subprocess.Popen(P,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
p.stdin.write('begin;'+auth()+call+'select pg_sleep(1.2);commit;');p.stdin.close()
first=json.loads(p.stdout.readline());assert first['revision']==1
retry=sql(auth()+call);assert json.loads(retry.stdout)['revision']==1
assert p.wait()==0
results['concurrent_identical_payload']='PASS one revision'
sql('truncate public.home_configuration_revisions;')
p=subprocess.Popen(P,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
p.stdin.write('begin;'+auth()+call+'select pg_sleep(1.2);commit;');p.stdin.close();assert json.loads(p.stdout.readline())['revision']==1
r=sql(auth()+"select public.save_my_home_configuration('{\"config_version\":1,\"cards\":[{\"card_id\":\"dday\",\"visible\":false,\"display_order\":0}]}',0);",False)
assert r.returncode and 'Configuration changed' in r.stderr;assert p.wait()==0
results['concurrent_different_payload']='PASS stale revision rejected'
assert sql(auth(V)+'select public.my_home_configuration() is null;').stdout.strip()=='t'
# Explicit SELECT grant in a local rolled-back transaction isolates the RLS predicate from table grants.
assert sql('begin;grant select on public.home_configuration_revisions to authenticated;grant usage on schema auth to authenticated;'+auth(V)+'select count(*) from public.home_configuration_revisions;rollback;').stdout.strip()=='0'
results['owner_rls']='PASS other user sees zero rows with temporary SELECT grant'
for state in ['DELETION_PENDING','ERASING']:
 sql(f"truncate public.account_deletion_requests;insert into public.account_deletion_requests values('{U}','{state}');")
 allowed=sql(f"select account_private.allowed('{U}');").stdout.strip();assert allowed=='f'
 read=sql(auth()+'select public.my_home_configuration();');assert json.loads(read.stdout)['revision']>=1
 current=json.loads(read.stdout)['revision']
 payload=json.dumps({'config_version':1,'cards':[{'card_id':'dday','visible':state=='DELETION_PENDING','display_order':0}]})
 save=sql(auth()+f"select public.save_my_home_configuration('{payload}',{current});");assert json.loads(save.stdout)['revision']==current+1
 results['original_'+state]='BUG: account allowed=false but own read succeeds and changed config appends a new revision'
sql('truncate public.account_deletion_requests;')
sql(f"insert into public.universities values('{Q}','SYNTHETIC');insert into public.university_official_sources values('{Q}','admission.example.edu',now());")
columns='series_key,revision,university_id,academic_year,scope,kind,event_type,title,precision,source_host,source_title,source_url,source_sha256,source_archive_key,source_locator,verified_at,updated_at,expires_at,status'
values=f"('00000000-0000-0000-0000-'||lpad(i::text,12,'0'))::uuid,1,'{Q}',2027,'university','news','notice','SYNTHETIC','unknown','admission.example.edu','SYNTHETIC','https://admission.example.edu/notice',repeat('a',64),'synthetic','p1',now(),now(),now()+interval '1 day','verified'"
sql(f'insert into public.university_news_revisions({columns}) select {values} from generate_series(10,110) i;')
p=subprocess.Popen(P,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
p.stdin.write(f'begin;insert into public.university_news_revisions({columns}) select {values} from generate_series(1,1) i;select \'READY\';\n');p.stdin.flush();assert p.stdout.readline().strip()=='READY'
page1=json.loads(sql(auth()+f"select public.university_news_feed(array['{Q}'::uuid]);").stdout)
p.stdin.write('commit;\n');p.stdin.close();assert p.wait()==0
snapshot=page1['snapshot_at'];page2=json.loads(sql(auth()+f"select public.university_news_feed(array['{Q}'::uuid],100,'{snapshot}');").stdout)
one={x['series_key'] for x in page1['items']};two={x['series_key'] for x in page2['items']};assert len(one & two)==1
all_again=json.loads(sql(auth()+f"select public.university_news_feed(array['{Q}'::uuid],0,'{snapshot}');").stdout)
assert all_again['items'][0]['series_key'].endswith('000000000001')
results['snapshot_counterexample']={'page1':len(page1['items']),'page2':len(page2['items']),'duplicates':len(one&two),'late_committed_series_missing_from_original_combined_pages':True,'same_snapshot_changed':True}
(pathlib.Path(os.environ['TASK04B_RESULTS'])/'original-local-results.json').write_text(json.dumps(results,indent=2));print(json.dumps(results,indent=2))
