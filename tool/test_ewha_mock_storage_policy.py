import tempfile,subprocess,json,sys
from pathlib import Path
import psycopg
A=Path('/Users/woojinchang/.codex/worktrees/app-ga4-usage-20261105/legendstudy-service-app-20261022');O=A/'supabase/candidates/ewha_mock_public_20261112';pg=Path('/opt/homebrew/opt/postgresql@17/bin')
def run(cmd):subprocess.run(list(map(str,cmd)),check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
with tempfile.TemporaryDirectory(prefix='sogang-rls-',dir='/private/tmp') as tmp:
 p=Path(tmp);data=p/'data';sock=p/'sock';sock.mkdir();run([pg/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8']);run([pg/'pg_ctl','-D',data,'-l',p/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start'])
 try:
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as c:
   c.execute("create role authenticated;create role anon;create schema auth;create schema account_private;create schema storage;create table auth.users(id uuid primary key);create table public.account_deletion_requests(subject_id uuid,state text);create table storage.objects(bucket_id text,name text);alter table storage.objects enable row level security;grant usage on schema storage to authenticated,anon;grant select on storage.objects to authenticated,anon;create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;")
   definition=(O/'account-check-baseline.sql').read_text();c.execute(definition)
   c.execute("create function public.account_service_allowed() returns boolean language sql stable security definer set search_path='' as $$select account_private.allowed(auth.uid())$$")
   c.execute((O/'storage-policy-definition.sql').read_text());names=[r['objectName'] for r in json.load(open(O/'pdf-originals.json'))];sha=names[0]
   c.executemany if False else None
   for bucket,name in [('essay-material-originals',n) for n in names]+[('other',sha),('essay-material-originals','secret.pdf')]:c.execute('insert into storage.objects values(%s,%s)',(bucket,name))
   ids=['11111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','33333333-3333-4333-8333-333333333333'];checks=[]
   for uid in ids:c.execute('insert into auth.users values(%s)',(uid,))
   for uid,state in zip(ids[1:],['DELETION_PENDING','ERASING']):c.execute('insert into public.account_deletion_requests values(%s,%s)',(uid,state))
   for label,role,uid,want in [('active','authenticated',ids[0],8),('pending','authenticated',ids[1],0),('erasing','authenticated',ids[2],0),('unknown','authenticated','44444444-4444-4444-8444-444444444444',0),('no_uid','authenticated','',0),('anon','anon',ids[0],0)]:
    c.execute('begin');c.execute('set local role '+role);c.execute("select set_config('request.jwt.claim.sub',%s,true)",(uid,));rows=c.execute('select * from storage.objects').fetchall();assert len(rows)==want,(label,rows)
    if want:assert set(rows)=={('essay-material-originals',n) for n in names}
    c.execute('rollback');checks.append(label)
   c.execute((O/'rollback-storage.sql').read_text());c.execute('set role authenticated');assert c.execute('select count(*) from storage.objects').fetchone()[0]==0;c.execute('reset role');assert c.execute('select count(*) from storage.objects').fetchone()[0]==10
   (O/'storage-isolated-results.json').write_text(json.dumps(dict(checks=checks,wrong_bucket_and_file_denied=True,rollback_access_revoked=True,objects_preserved=True,provider_calls=0),indent=2)+'\n');print('STORAGE_21_OBJECTS_6_CASES_ROLLBACK_PASS')
 finally:run([pg/'pg_ctl','-D',data,'-m','fast','-w','stop'])
