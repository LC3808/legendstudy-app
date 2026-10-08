"""Isolated PostgreSQL17 exact activation, ACL, no-write and rollback checks."""
import os,re,subprocess,tempfile,importlib.util
from pathlib import Path
import psycopg
root=Path(__file__).resolve().parents[3];bin_dir=Path(os.environ['PG_BIN'])
def cmd(args):subprocess.run([str(bin_dir/args[0]),*args[1:]],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
with tempfile.TemporaryDirectory(prefix='legendstudy-admin-directory-') as tmp:
 base=Path(tmp);(base/'socket').mkdir();cmd(['initdb','-D',str(base/'data'),'-U','harness','--no-locale','--encoding=UTF8','-A','trust']);cmd(['pg_ctl','-D',str(base/'data'),'-l',str(base/'log'),'-o',f"-k {base/'socket'} -h ''",'-w','start'])
 try:
  with psycopg.connect(f"host={base/'socket'} dbname=postgres user=harness",autocommit=True) as c:
   c.execute('create role postgres nosuperuser;create role anon;create role authenticated;create role service_role;grant create on database postgres to postgres;grant all on schema public to postgres;set role postgres;')
   source=(root/'supabase/verification/admin_members/directory.mjs').read_text();fixture=re.search(r'await db.exec\(`(.*?)`\);',source,re.S)[1].replace('create role anon;create role authenticated;create role service_role;','');c.execute(fixture)
   lifecycle=(root/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text();c.execute(lifecycle[lifecycle.index('create function account_private.lock_subject'):lifecycle.index('create function account_private.guard_request')]);c.execute((root/'supabase/verification/my_foundation/fixtures/admin_operator.sql').read_text())
   c.execute("create schema supabase_migrations;create table supabase_migrations.schema_migrations(version text primary key,name text,statements text[]);insert into supabase_migrations.schema_migrations(version) values('20261008000600'),('20261008000700'),('20261008000800');")
   spec=importlib.util.spec_from_file_location('package',root/'tool/production/prepare_admin_directory.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);package=mod.prepare('0'*40,lambda path:(root/path).read_text());c.execute(package)
   report=c.execute((root/'supabase/verification/admin_members/postflight.sql').read_text()).fetchone()[0]
   assert report['rpc']['owner']=='postgres' and report['rpc']['authenticated_execute'] and not report['rpc']['anon_execute']
   assert report['cache']['rls'] and not any(report['cache'][x] for x in ['direct_select','direct_insert','direct_update','direct_delete'])
   assert len(report['resolved_schools'])==2
   for role in ['anon','authenticated']:
    c.execute('reset role');c.execute('set role '+role)
    try:c.execute('select public.admin_member_list()')
    except psycopg.Error as e:assert e.sqlstate=='42501'
    else:raise AssertionError('unauthorized directory read')
   c.execute('reset role;set role postgres');admin='00000000-0000-4000-8000-000000000001';c.execute('insert into auth.users values(%s,%s,now())',[admin,'fixture@example.test']);c.execute('insert into admin_users values(%s)',[admin]);c.execute('set role authenticated')
   c.execute("select set_config('request.jwt.claim.sub',%s,false),set_config('request.jwt.claims',%s,false)",[admin,'{"sub":"'+admin+'","role":"authenticated","exp":9999999999}']);assert c.execute('select public.admin_member_list()').fetchone()[0]['total']==1
   c.execute('reset role;set role postgres')
   try:c.execute(package)
   except psycopg.Error as e:assert 'MIGRATION_COLLISION' in str(e);c.execute('rollback')
   else:raise AssertionError('replay accepted')
   c.execute((root/'supabase/verification/admin_members/rollback.sql').read_text());assert c.execute("select to_regclass('student_private.school_display_cache')").fetchone()[0] is None;assert c.execute('select count(*) from auth.users').fetchone()[0]==1
   print('ADMIN_DIRECTORY_PG17_NOSUPERUSER: apply/grants/admin/deny/collision/rollback PASS')
 finally:cmd(['pg_ctl','-D',str(base/'data'),'-m','immediate','stop'])
