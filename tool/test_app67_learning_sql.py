"""Disposable local PostgreSQL only; no remote connection option or production mutations."""
import json, os, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PG=Path('/opt/homebrew/opt/postgresql@17/bin')
C=ROOT/'supabase/candidates/app67_learning_20261111'
A='00000000-0000-0000-0000-000000000001'; B='00000000-0000-0000-0000-000000000002'; U='00000000-0000-0000-0000-000000000010'
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 checks=0
 with tempfile.TemporaryDirectory(prefix='learning-sql-',dir='/private/tmp') as tmp:
  root=Path(tmp);sock=root/'socket';sock.mkdir();data=root/'db'
  def run(args,**kw): return subprocess.run([str(a) for a in args],env=env,text=True,capture_output=True,**kw)
  def command(args):
   p=run(args);assert p.returncode==0,p.stderr
  command([PG/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  command([PG/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -c listen_addresses=''",'-w','start'])
  args=[str(PG/'psql'),'-X','-qAt','-v','ON_ERROR_STOP=1','-h',str(sock),'-U','postgres']
  def sql(s,error=None):
   nonlocal checks
   p=run(args,input=s)
   if error: assert p.returncode and error in p.stderr,p.stderr
   else: assert p.returncode==0,p.stderr
   checks+=1
   return p.stdout.strip()
  def call(key,division='수학과',season='수시',track='논술',year=2027,id='null',revision=0):
   return f"select public.my_application_save({id},{revision},{year},'{U}','{division}','{season}','{track}','00000000-0000-0000-0001-{key:012d}');"
  def auth(user=A): return f"set role authenticated;set request.jwt.claim.sub='{user}';"
  try:
   sql(f"""
   create role anon;create role authenticated;
   create schema auth;create schema account_private;
   create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
   create function account_private.allowed(u uuid) returns boolean language sql stable as $$select u is not null$$;
   create function account_private.lock_subject(u uuid) returns void language sql as $$select pg_advisory_xact_lock(hashtextextended(u::text,84612))$$;
   create function public.account_service_allowed() returns boolean language sql stable as $$select auth.uid() is not null$$;
   grant usage on schema auth to authenticated;
   create table public.profiles(id uuid primary key);
   create table public.universities(id uuid primary key,name text,is_active boolean);
   insert into public.profiles values('{A}'),('{B}');
   insert into public.universities values('{U}','격리 테스트대',true);
   create table public.study_sessions(user_id uuid,started_at timestamptz,ended_at timestamptz,active_segments jsonb,include_in_study_total boolean);
   """)
   sql((ROOT/'supabase/migrations/20261008000600_student_application_foundation.sql').read_text())
   sql((ROOT/'supabase/migrations/20261008000700_shared_study_summary.sql').read_text())
   baseline=json.loads((C/'baseline.json').read_text())
   sql('\n'.join(d['definition']+';' for d in baseline))
   sql(f"""insert into public.study_sessions values
   ('{A}','2020-01-01 00:00Z','2020-01-01 01:00Z','[[0,3600000]]',true),
   ('{A}','2026-11-11 00:00Z','2026-11-11 01:00Z','[[0,3600000]]',true),
   ('{A}','2026-11-11 00:30Z','2026-11-11 01:30Z','[[0,3600000]]',true),
   ('{A}','2026-11-10 00:00Z','2026-11-10 01:00Z','[[0,3600000]]',false),
   ('{B}','2026-11-11 00:00Z','2026-11-11 01:00Z','[[0,3600000]]',true);""")
   fingerprint="select md5(coalesce(jsonb_agg(to_jsonb(s) order by user_id,started_at)::text,'')) from public.study_sessions s;"
   before=sql(fingerprint)
   summary_before=json.loads(sql(f"select student_private.study_summary('{A}','2026-11-11 03:00Z');"))
   acl="select jsonb_agg(jsonb_build_array(n.nspname,p.proname,p.proacl) order by n.nspname,p.proname) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where (n.nspname='student_private' and p.proname='study_summary') or (n.nspname='public' and p.proname='my_application_save');"
   acl_before=sql(acl)
   sql((C/'apply.sql').read_text());assert sql(acl)==acl_before
   after=json.loads(sql(f"select student_private.study_summary('{A}','2026-11-11 03:00Z');"))
   assert after.pop('all_time_ms')==9000000;assert after.pop('all_time_source')=='completed_synced_sessions';assert after==summary_before
   assert sql(fingerprint)==before
   sql('set role anon;select public.my_study_summary();','permission denied')
   sql('set role authenticated;select student_private.study_summary(null,now());','permission denied')
   own=json.loads(sql(auth()+"select public.my_study_summary();").splitlines()[-1]);assert own['all_time_ms']==int(sql(f"select (student_private.study_summary('{A}',now())->>'all_time_ms')::bigint;"))
   other=json.loads(sql(auth(B)+"select public.my_study_summary();").splitlines()[-1]);assert other['all_time_ms']==int(sql(f"select (student_private.study_summary('{B}',now())->>'all_time_ms')::bigint;"))
   first=sql(auth()+call(1)).splitlines()[-1]
   assert sql(auth()+call(1)).splitlines()[-1]==first
   sql(auth()+call(2),'APPLICATION_ALREADY_EXISTS')
   for key,kw in [(3,{'division':'물리학과'}),(4,{'season':'정시'}),(5,{'track':'학생부'}),(6,{'year':2028})]: sql(auth()+call(key,**kw))
   second=sql(f"select id from public.student_applications where intended_division='물리학과';")
   sql(auth()+call(7,id=f"'{second}'",revision=1),'APPLICATION_ALREADY_EXISTS')
   sql(auth(B)+call(8))
   sql(auth()+call(1,track='다른전형'),'REQUEST_KEY_REUSED')
   sql(auth()+call(9,id=f"'{first}'",revision=99),'APPLICATION_CHANGED')
   sql('set role anon;'+call(10),'permission denied')
   sql(auth()+f"insert into public.student_applications(user_id) values('{A}');",'permission denied')
   # Two independent sessions race for the same semantic application.
   p1=subprocess.Popen(args,env=env,text=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
   p1.stdin.write(auth()+"begin;"+call(20,division='동시성학과')+"select pg_sleep(0.3);commit;\n");p1.stdin.close()
   p2=run(args,input=auth()+call(21,division='동시성학과'))
   o1=p1.stdout.read();e1=p1.stderr.read();p1.wait()
   assert sorted([p1.returncode,p2.returncode])==[0,3],(e1,p2.stderr)
   assert 'APPLICATION_ALREADY_EXISTS' in e1+p2.stderr
   assert sql("select count(*) from public.student_applications where intended_division='동시성학과';")=='1'
   events_before=sql('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.student_application_events e;')
   sql((C/'apply.sql').read_text(),'BASELINE_CHANGED')
   sql((C/'rollback.sql').read_text());assert sql(acl)==acl_before
   assert sql(fingerprint)==before
   assert sql('select md5(jsonb_agg(to_jsonb(e) order by id)::text) from public.student_application_events e;')==events_before
   assert json.loads(sql(f"select student_private.study_summary('{A}','2026-11-11 03:00Z');"))==summary_before
   for d in baseline:
    digest=sql(f"select md5(pg_get_functiondef(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='{d['nspname']}' and p.proname='{d['proname']}';")
    assert digest==d['digest'],(digest,d['digest'])
   print(f'PASS: {checks} SQL checks + overlap/owner/privacy/idempotency/concurrency/ACL/data-preservation/rollback assertions')
  finally: command([PG/'pg_ctl','-D',data,'-m','fast','-w','stop'])
if __name__=='__main__': main()
