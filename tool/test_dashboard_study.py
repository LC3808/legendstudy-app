"""Disposable local PostgreSQL test: no production connection or user data."""
import json,os,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PG=Path('/opt/homebrew/opt/postgresql@17/bin')
def main():
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 with tempfile.TemporaryDirectory(prefix='dashboard-study-',dir='/private/tmp') as tmp:
  path=Path(tmp);sock=path/'socket';sock.mkdir();db=path/'db'
  def run(args,**kw):return subprocess.run(list(map(str,args)),env=env,text=True,capture_output=True,**kw)
  def command(args):
   p=run(args);assert p.returncode==0,p.stderr
  command([PG/'initdb','-D',db,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  command([PG/'pg_ctl','-D',db,'-l',path/'log','-o',f"-k {sock} -c listen_addresses=''",'-w','start'])
  try:
   def sql(s,error=None):
    p=run([PG/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','postgres'],input=s)
    if error:assert p.returncode and error in p.stderr,p.stderr;return
    assert p.returncode==0,p.stderr
    return p.stdout.strip()
   sql("""
create role anon;create role authenticated;create role service_role;
create schema auth;create schema account_private;
create function public.admin_operator() returns boolean language sql stable as $$select coalesce(current_setting('test.operator',true),'')='yes'$$;
create function auth.uid() returns uuid language sql stable as $$select '00000000-0000-0000-0000-000000000001'::uuid$$;
create function account_private.allowed(uuid) returns boolean language sql stable as $$select $1<>'00000000-0000-0000-0000-000000000099'::uuid and coalesce(current_setting('test.blocked',true),'')<>'yes'$$;
create table profiles(id uuid primary key,grade_level smallint,academic_status text);
create table study_sessions(id uuid default gen_random_uuid(),user_id uuid,mode text,started_at timestamptz,ended_at timestamptz,include_in_study_total boolean,active_segments jsonb);
insert into profiles select ('00000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,1,'student' from generate_series(1,5)n;
-- Five users, one hour spanning KST midnight; only last 30m belongs to selected date.
insert into study_sessions(user_id,mode,started_at,ended_at,include_in_study_total,active_segments)
select id,'study','2026-11-03 23:30+09','2026-11-04 00:30+09',true,'[[0,3600000]]' from profiles;
-- Identical and overlapping device/mock sessions must not double count.
insert into study_sessions(user_id,mode,started_at,ended_at,include_in_study_total,active_segments)
select id,'mock_exam','2026-11-04 00:00+09','2026-11-04 00:30+09',true,'[[0,1800000]]' from profiles;
-- Another 10 active minutes, 20 minute wall span with pause; excluded mock adds nothing.
insert into study_sessions(user_id,mode,started_at,ended_at,include_in_study_total,active_segments)
select id,'study','2026-11-04 01:00+09','2026-11-04 01:20+09',true,'[[0,300000],[900000,1200000]]' from profiles;
insert into study_sessions(user_id,mode,started_at,ended_at,include_in_study_total,active_segments)
select id,'mock_exam','2026-11-04 02:00+09','2026-11-04 03:00+09',false,'[[0,3600000]]' from profiles;
""")
   candidate=ROOT/'supabase/candidates/dashboard_study_20261104'
   sql((candidate/'apply.sql').read_text())
   call="select public.admin_dashboard_study('2026-11-04 00:00+09','2026-11-05 00:00+09');"
   def report():return json.loads(sql("set role authenticated;set test.operator='yes';"+call))
   before=sql("select md5(string_agg(row_to_json(s)::text,'' order by id)) from study_sessions s")
   r=report();assert r['total']=={'users':5,'ms':12000000},r
   assert r['grades_available'] and r['grades']==[{'grade':'1','users':5,'ms':12000000}]
   for role in ['anon','service_role']:sql(f'set role {role};'+call,'permission denied')
   sql('set role authenticated;'+call,'insufficient_privilege')
   sql("set role authenticated;set test.operator='yes';set test.blocked='yes';"+call,'insufficient_privilege')
   sql('set role authenticated;select * from study_sessions;','permission denied')
   for start,end in [('2026-11-05','2026-11-04'),('2020-01-01','2026-11-05'),('infinity','infinity')]:
    sql(f"set role authenticated;set test.operator='yes';select public.admin_dashboard_study('{start}','{end}');",'INVALID_PERIOD')
   assert sql("select md5(string_agg(row_to_json(s)::text,'' order by id)) from study_sessions s")==before
   # Current grade projection changes grouping only; original learning facts remain intact.
   sql("update profiles set grade_level=2 where id::text like '%000001'")
   r=report();assert r['total']['users']==5 and not r['grades_available'] and r['grades']==[]
   sql("insert into profiles values('00000000-0000-0000-0000-000000000099',3,'student');insert into study_sessions(user_id,mode,started_at,ended_at,include_in_study_total,active_segments) values('00000000-0000-0000-0000-000000000099','study','2026-11-04 01:00+09','2026-11-04 02:00+09',true,'[[0,3600000]]');")
   assert report()['total']=={'users':5,'ms':12000000}
   sql("delete from study_sessions where user_id::text like '%000005'")
   r=report();assert r['total']=={'users':None,'ms':None} and r['grades']==[]
   empty=json.loads(sql("set test.operator='yes';select public.admin_dashboard_study('2026-12-01','2026-12-02');"));assert empty['total']['users'] is None
   sql((candidate/'rollback.sql').read_text())
   assert sql("select to_regprocedure('public.admin_dashboard_study(timestamptz,timestamptz)') is null")=='t'
   print('PASS: KST clipping, cross-device/mock overlap, pause/exclusion, distinct denominator, grade/total suppression, current projection, lifecycle, ACL, period limits, source preservation and rollback')
  finally:command([PG/'pg_ctl','-D',db,'-m','immediate','-w','stop'])
if __name__=='__main__':main()
