#!/usr/bin/env python3
"""MATH-2C full non-superuser PG17 installation/failure/rollback verification. No network DSN."""
import argparse,json,os,subprocess,tempfile,hashlib
from pathlib import Path
import psycopg
import test_math_ownership_bootstrap as b
R=Path(__file__).resolve().parents[1]
V=R/'supabase/verification/math_essay'
M=R/'supabase/migrations/20261002000100_math_essay_persistence.sql'
candidate=M.read_text();rollback=(V/'rollback.sql').read_text()
def verify(c):
 checks=[]
 before=b.snapshot(c)
 assert c.execute('select rolsuper from pg_roles where rolname=current_user').fetchone()==(False,)
 # Exact transaction rollback fingerprints at each approved bootstrap checkpoint + late DDL.
 markers=[]
 for owner in ['math_executor','essay_executor']:
  markers += [f'grant {owner} to postgres with admin false,inherit false,set true granted by postgres;',f'grant create on schema '+b.INVENTORY['temporary_schema_create'][owner][0]+f' to {owner};',f'set role {owner};',f'revoke {owner} from postgres granted by postgres;']
  first=next(f for f in b.INVENTORY['functions'] if f['final_owner']==owner)
  end=candidate.index('$math_fn$;',candidate.index('create or replace function '+first['signature'].split('(')[0]))+len('$math_fn$;')
  markers.append(candidate[end-90:end])
 markers.append('create trigger hq_domain_parent before insert on public.human_quality_judgments for each row execute function math_private.hq_parent_guard();')
 for n,marker in enumerate(markers):
  assert marker in candidate
  bad=candidate.replace(marker,marker+"\ndo $$begin raise exception 'MATH_TEST_INJECT';end$$;",1)
  try:c.execute(bad);raise AssertionError('injection absent')
  except psycopg.errors.RaiseException as e:assert e.diag.message_primary=='MATH_TEST_INJECT'
  finally:c.execute('rollback')
  assert b.snapshot(c)==before,n;checks.append('full_migration_failure_'+str(n))
 c.execute(candidate)
 c.execute((V/'postflight.sql').read_text())
 for role in b.ROLES:
  assert c.execute("select pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where roleid=%s::regrole",(role,)).fetchall()==[('postgres','supabase_admin',True,False,False)]
 for f in b.INVENTORY['functions']:
  actual=c.execute("select pg_get_userbyid(proowner),prosecdef,proconfig from pg_proc where oid=%s::regprocedure",(f['signature'],)).fetchone();assert actual==(f['final_owner'],f['security_mode']=='DEFINER',['search_path=""']),(f,actual)
  acl=c.execute("select pg_get_userbyid(a.grantee),privilege_type from pg_proc p cross join lateral aclexplode(proacl) a where oid=%s::regprocedure order by 1",(f['signature'],)).fetchall();assert acl==sorted((r,'EXECUTE') for r in f['execute_roles']),(f,acl)
 checks.append('final_owners_acl_config_memberships')
 metadata={"indexes":c.execute("select indexname,indexdef from pg_indexes where schemaname='public' and (tablename like 'math_%' or indexname='human_quality_math_history') order by indexname").fetchall(),"tables":c.execute("select relname,pg_get_userbyid(relowner),relrowsecurity,relacl::text from pg_class where relnamespace='public'::regnamespace and relkind='r' and relname like 'math_%' order by relname").fetchall()}
 counts=c.execute('select jsonb_build_array((select count(*) from public.credit_accounts),(select count(*) from public.credit_grants),(select count(*) from public.credit_transactions),(select count(*) from public.essay_billing_decisions))').fetchone()[0]
 try:c.execute(rollback);raise AssertionError('unguarded rollback')
 except psycopg.errors.RaiseException:pass
 finally:c.execute('rollback')
 c.execute("select set_config('math.rollback_credit_counts',%s,false)",(json.dumps(counts),))
 c.execute('create view public.math_test_unexpected as select * from public.math_evaluations')
 installed=b.snapshot(c)
 try:c.execute(rollback);raise AssertionError('dependency accepted')
 except psycopg.errors.DependentObjectsStillExist:pass
 finally:c.execute('rollback')
 assert b.snapshot(c)==installed
 c.execute('drop view public.math_test_unexpected');checks.append('unexpected_dependency_abort_exact')
 c.execute(rollback)
 after=b.snapshot(c)
 for key in ['memberships','schemas','functions','relations','policies']:assert before[key]==after[key],key
 # Constraint OIDs legitimately change when restoring original checks; definitions must match.
 assert sorted(x[1] for x in before['constraints'])==sorted(x[1] for x in after['constraints'])
 checks.append('empty_install_rollback_legacy_owner_acl_security_restored')
 return dict(checks=checks,count=len(checks),catalog=metadata,migration_sha256=hashlib.sha256(M.read_bytes()).hexdigest(),execution_superuser=False,production_writes=0)

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--pg-bin',type=Path,required=True);args=ap.parse_args()
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(a):return subprocess.run(list(map(str,a)),check=True,capture_output=True,text=True,env=env).stdout
 assert ' 17.' in run([args.pg_bin/'postgres','--version'])
 with tempfile.TemporaryDirectory(prefix='math-install-',dir='/private/tmp') as td:
  root=Path(td);sock=root/'socket';sock.mkdir();data=root/'db';started=False
  run([args.pg_bin/'initdb','-D',data,'-U','supabase_admin','--auth=trust','--no-locale','--encoding=UTF8'])
  try:
   run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);started=True
   with psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
    admin.execute('create role postgres login superuser;alter database postgres owner to postgres')
    with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as c:
     c.execute("create role anon nologin;create role authenticated nologin;create role service_role nologin bypassrls;create schema auth;create table auth.users(id uuid primary key,created_at timestamptz default now());create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth,public to anon,authenticated,service_role;alter default privileges in schema public grant all on tables to anon,authenticated,service_role;alter default privileges in schema public grant all on functions to anon,authenticated,service_role;")
     for version in b.VERSIONS:c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())
     c.execute('revoke essay_executor from postgres;grant usage on schema public to postgres')
     admin.execute('grant essay_executor to postgres with admin true,inherit false,set false granted by supabase_admin;alter role postgres nosuperuser createrole bypassrls')
     # Local metadata-only ledger shim for Owner package query syntax; no remote access.
     c.execute('create schema supabase_migrations;create table supabase_migrations.schema_migrations(version text primary key,name text)')
     for version in b.VERSIONS:c.execute('insert into supabase_migrations.schema_migrations values(%s,%s)',(version,'isolated_prerequisite'))
     c.execute((V/'catalog.sql').read_text())
     result=verify(c)
     result['owner_catalog_postflight_sql']='PASS'
  finally:
   if started:run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])
 (V/'installation_validation.json').write_text(json.dumps(result,indent=2)+'\n');print('MATH_INSTALLATION_CHECKS',result['count'])
if __name__=='__main__':main()
