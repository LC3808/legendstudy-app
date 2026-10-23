from pathlib import Path
import os,subprocess,tempfile,json
pg=Path('/opt/homebrew/opt/postgresql@17/bin');env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C';root=Path(__file__).resolve().parent;h='582f370e73f3d4b96e374f0596e4ae204e6f79e750ca07ff2c752244826fd7eb'
def run(args,**kw):return subprocess.run(list(map(str,args)),env=env,text=True,capture_output=True,**kw)
with tempfile.TemporaryDirectory(dir='/private/tmp',prefix='skku-pdf-') as tmp:
 p=Path(tmp);(p/'sock').mkdir();assert run([pg/'initdb','-D',p/'db','-U','local_admin','--auth=trust','--no-locale']).returncode==0
 assert run([pg/'pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {p/'sock'} -c listen_addresses=''",'-w','start']).returncode==0
 try:
  def sql(s):
   r=run([pg/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',p/'sock','-U','local_admin','-d','postgres'],input=s);assert r.returncode==0,r.stderr;return r.stdout.strip()
  sql("create role authenticated;create role anon;create schema storage;create table storage.objects(bucket_id text,name text);alter table storage.objects enable row level security;grant usage on schema storage to authenticated,anon;grant select,insert,update,delete on storage.objects to authenticated,anon;create function public.account_service_allowed() returns boolean language sql as $$select current_setting('test.active',true)='true'$$;")
  sql(f"insert into storage.objects values('essay-material-originals','{h}.pdf'),('essay-material-originals','answers.pdf'),('other','{h}.pdf');")
  sql((root/'policy.sql').read_text())
  assert sql("set role authenticated;set test.active='true';select count(*) from storage.objects;")=='1'
  assert sql("set role authenticated;set test.active='false';select count(*) from storage.objects;")=='0'
  assert sql("set role anon;set test.active='true';select count(*) from storage.objects;")=='0'
  assert sql("set role authenticated;set test.active='true';with x as (delete from storage.objects returning *) select count(*) from x;")=='0'
  assert sql("select count(*) from storage.objects;")=='3'
  sql((root/'rollback.sql').read_text());assert sql("set role authenticated;set test.active='true';select count(*) from storage.objects;")=='0'
  sql((root/'rollback.sql').read_text())
  print(json.dumps({'status':'PASS','checks':['active_auth_exact_file_only','inactive_denied','anon_denied','other_bucket_and_answer_denied','no_delete','rollback_retains_objects','rollback_idempotent']}))
 finally:run([pg/'pg_ctl','-D',p/'db','-m','immediate','-w','stop'])
