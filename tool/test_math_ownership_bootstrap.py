#!/usr/bin/env python3
"""Disposable PG17 ownership-only proof. NOT the Math implementation/acceptance suite.
Loads actual canonical Essay/Quality/HQP prerequisites. New Math function bodies
are deliberately inert typed fixtures; no behavioral/financial claim is made.
No remote DSN accepted. Unix socket only; synthetic auth shim as in HQP harness.
"""
import argparse, json, os, subprocess, tempfile
from pathlib import Path
import psycopg
from psycopg import sql
R=Path(__file__).resolve().parents[1]
V=R/'supabase/verification/math_essay'
INVENTORY=json.loads((V/'ownership_inventory.json').read_text())
ROLES=list(INVENTORY['new_roles'])
VERSIONS=['20260912000100','20260913000100','20260917000100','20260927000100','20260927000200','20260928000100','20260928000200','20260928000300','20260928000400','20260929000100','20260929000200','20260929000300','20260929000400','20261001000100','20261001000200']
def snapshot(c):
 return {
  'memberships':c.execute("select roleid,member,grantor,admin_option,inherit_option,set_option from pg_auth_members order by 1,2,3").fetchall(),
  'schemas':c.execute("select oid,nspname,nspowner,nspacl::text from pg_namespace where nspname in ('public','essay_private','math_private') order by 1").fetchall(),
  'functions':c.execute("select p.oid,pg_get_functiondef(p.oid),p.proowner,p.proacl::text,p.prosecdef,p.proconfig,p.provolatile,p.proparallel from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private','math_private') order by p.oid").fetchall(),
  'relations':c.execute("select oid,relowner,relacl::text,relrowsecurity,relforcerowsecurity from pg_class where relnamespace in ('public'::regnamespace,'essay_private'::regnamespace) order by oid").fetchall(),
  'constraints':c.execute("select oid,pg_get_constraintdef(oid) from pg_constraint where connamespace='public'::regnamespace order by oid").fetchall(),
  'policies':c.execute("select * from pg_policies where schemaname in ('public','essay_private') order by schemaname,tablename,policyname").fetchall()}
def exercise(c,fail_at=None):
 checkpoints=[]
 def mark(name):
  checkpoints.append(name)
  if fail_at==name:c.execute("do $$begin raise exception 'MATH_OWNERSHIP_INJECTED';end$$")
 c.execute('begin')
 assert c.execute('select current_user,rolsuper from pg_roles where rolname=current_user').fetchone()==('postgres',False)
 for role in ROLES:c.execute(sql.SQL('create role {} nologin nobypassrls nosuperuser nocreatedb nocreaterole noreplication noinherit').format(sql.Identifier(role)))
 c.execute('create schema math_private; revoke all on schema math_private from public')
 c.execute('grant usage on schema math_private to math_executor,essay_executor; grant usage on schema public to math_executor,math_extraction_worker,math_evaluation_worker')
 expected_memberships=c.execute("select roleid,member,grantor,admin_option,inherit_option,set_option from pg_auth_members order by 1,2,3").fetchall()
 expected_schemas=c.execute("select oid,nspacl::text from pg_namespace where nspname in ('public','essay_private','math_private') order by oid").fetchall()
 for owner in ['math_executor','essay_executor','postgres']:
  if owner!='postgres':
   c.execute(sql.SQL('grant {} to postgres with admin false,inherit false,set true granted by postgres').format(sql.Identifier(owner)))
   mark(owner+'_A_AFTER_SET_GRANT')
   for schema in INVENTORY['temporary_schema_create'][owner]:c.execute(sql.SQL('grant create on schema {} to {}').format(sql.Identifier(schema),sql.Identifier(owner)))
   mark(owner+'_B_AFTER_CREATE_GRANT')
   c.execute(sql.SQL('set role {}').format(sql.Identifier(owner)))
   mark(owner+'_D_AFTER_SET_ROLE')
  entries=[f for f in INVENTORY['functions'] if f['final_owner']==owner and not f['existing']]
  for index,f in enumerate(entries):
   # These bodies prove only exact ownership/ACL installation; never business behavior.
   body='begin return new; end' if f['returns']=='trigger' else ('begin return; end' if f['returns']=='void' else 'begin return null; end')
   c.execute('create function '+f['signature']+' returns '+f['returns']+' language plpgsql '+f['volatility']+' security '+f['security_mode']+" set search_path='' as $ownership_fixture$"+body+'$ownership_fixture$')
   c.execute('revoke all on function '+f['signature']+' from public,anon,authenticated,service_role')
   for role in f['execute_roles']:
    c.execute(sql.SQL('grant execute on function '+f['signature']+' to {}').format(sql.Identifier(role)))
   if owner!='postgres' and index==0:mark(owner+'_C_AFTER_FIRST_FUNCTION')
  if owner!='postgres':
   mark(owner+'_E_AFTER_OWNER_INITIALIZATION')
   c.execute('reset role');mark(owner+'_D_AFTER_RESET_ROLE')
   for schema in INVENTORY['temporary_schema_create'][owner]:c.execute(sql.SQL('revoke create on schema {} from {}').format(sql.Identifier(schema),sql.Identifier(owner)))
   c.execute(sql.SQL('revoke {} from postgres granted by postgres').format(sql.Identifier(owner)))
 assert c.execute("select roleid,member,grantor,admin_option,inherit_option,set_option from pg_auth_members order by 1,2,3").fetchall()==expected_memberships
 assert c.execute("select oid,nspacl::text from pg_namespace where nspname in ('public','essay_private','math_private') order by oid").fetchall()==expected_schemas
 for role in ROLES:
  assert c.execute("select rolcanlogin,rolbypassrls,rolsuper,rolcreatedb,rolcreaterole,rolreplication,rolinherit from pg_roles where rolname=%s",(role,)).fetchone()==(False,)*7
  assert c.execute("select pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where roleid=%s::regrole",(role,)).fetchall()==[('postgres','supabase_admin',True,False,False)]
 for f in INVENTORY['functions']:
  if f['existing']:continue
  row=c.execute("select pg_get_userbyid(proowner),prosecdef,proconfig,provolatile,proparallel from pg_proc where oid=%s::regprocedure",(f['signature'],)).fetchone()
  assert row==(f['final_owner'],f['security_mode']=='DEFINER',['search_path=""'],f['volatility'][0],'u'),(f,row)
  acl=c.execute("select pg_get_userbyid(a.grantee),a.privilege_type,a.is_grantable from pg_proc p cross join lateral aclexplode(p.proacl) a where p.oid=%s::regprocedure order by 1",(f['signature'],)).fetchall()
  assert acl==sorted((r,'EXECUTE',False) for r in f['execute_roles']),(f,acl)
 mark('F_AFTER_COMPLETE_OWNERSHIP_FIXTURE')
 return checkpoints

def rollback_ownership_fixture(c):
 # Empty ownership fixture only. Actual Math rollback must additionally guard data/dependencies.
 c.execute('begin')
 for owner in ['math_executor','essay_executor','postgres']:
  if owner!='postgres':
   c.execute(sql.SQL('grant {} to postgres with admin false,inherit false,set true granted by postgres').format(sql.Identifier(owner)))
   c.execute(sql.SQL('set role {}').format(sql.Identifier(owner)))
  for f in reversed(INVENTORY['functions']):
   if f['final_owner']==owner and not f['existing']:c.execute('drop function '+f['signature'])
  if owner!='postgres':
   c.execute('reset role')
   c.execute(sql.SQL('revoke {} from postgres granted by postgres').format(sql.Identifier(owner)))
 c.execute('drop schema math_private')
 for role in ROLES:
  c.execute(sql.SQL('revoke usage on schema public from {}').format(sql.Identifier(role)))
  c.execute(sql.SQL('drop role {}').format(sql.Identifier(role)))
 c.execute('commit')

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--pg-bin',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);args=ap.parse_args()
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(parts):return subprocess.run(list(map(str,parts)),env=env,check=True,capture_output=True,text=True).stdout
 assert ' 17.' in run([args.pg_bin/'postgres','--version'])
 results=[]
 with tempfile.TemporaryDirectory(prefix='math-ownership-',dir='/private/tmp') as td:
  root=Path(td);sock=root/'socket';sock.mkdir();data=root/'db';started=False
  run([args.pg_bin/'initdb','-D',data,'-U','supabase_admin','--auth=trust','--no-locale','--encoding=UTF8'])
  try:
   run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);started=True
   with psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True) as admin:
    admin.execute('create role postgres login superuser;alter database postgres owner to postgres')
    with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as c:
     c.execute("create role anon nologin;create role authenticated nologin;create role service_role nologin bypassrls;create schema auth;create table auth.users(id uuid primary key,created_at timestamptz default now());create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;grant usage on schema auth,public to anon,authenticated,service_role;alter default privileges in schema public grant all on tables to anon,authenticated,service_role;alter default privileges in schema public grant all on functions to anon,authenticated,service_role;")
     for version in VERSIONS:c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())
     for role,member,grantor in c.execute("select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor) from pg_auth_members where roleid='essay_executor'::regrole").fetchall():
      c.execute(sql.SQL('revoke {} from {} granted by {}').format(*map(sql.Identifier,[role,member,grantor])))
     admin.execute('grant essay_executor to postgres with admin true,inherit false,set false granted by supabase_admin')
     c.execute('grant usage on schema public to postgres')
     before=snapshot(c)
     admin.execute('alter role postgres nosuperuser createrole bypassrls')
     try:
      checkpoints=exercise(c)
      c.execute('rollback');assert snapshot(c)==before
      results.append(dict(test='complete_ownership_fixture_and_rollback',result='PASS'))
      for checkpoint in checkpoints:
       try:exercise(c,checkpoint);raise AssertionError('failure injection did not fire')
       except psycopg.errors.RaiseException as e:assert e.diag.message_primary=='MATH_OWNERSHIP_INJECTED'
       finally:c.execute('rollback')
       assert snapshot(c)==before,checkpoint
       for role in ROLES:assert c.execute('select to_regrole(%s)',(role,)).fetchone()[0] is None
       assert c.execute("select to_regnamespace('math_private')").fetchone()[0] is None
       results.append(dict(test=checkpoint,result='PASS',restoration='EXACT'))
      exercise(c);c.execute('commit')
      for role in ROLES:
       assert c.execute("select pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where roleid=%s::regrole",(role,)).fetchall()==[('postgres','supabase_admin',True,False,False)]
      results.append(dict(test='committed_final_admin_only_topology',result='PASS'))
      c.execute("create view public.math_ownership_unexpected_dependency as select public.math_attempt_detail(null::uuid)")
      installed=snapshot(c)
      try:rollback_ownership_fixture(c);raise AssertionError('unexpected dependency accepted')
      except psycopg.errors.DependentObjectsStillExist:pass
      finally:c.execute('rollback')
      assert snapshot(c)==installed
      c.execute('drop view public.math_ownership_unexpected_dependency')
      results.append(dict(test='unexpected_dependency_rejected_without_cascade',result='PASS'))
      rollback_ownership_fixture(c)
      assert snapshot(c)==before
      results.append(dict(test='committed_empty_ownership_fixture_rollback',result='PASS'))
     finally:
      c.execute('rollback')
  finally:
   if started:run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])
 report=dict(scope='ownership bootstrap fixtures only; NOT complete Math migration or R01-R24',canonical_prerequisite_migrations=len(VERSIONS),new_inert_function_fixtures=sum(not f['existing'] for f in INVENTORY['functions']),execution_superuser=False,auto_admin_membership_accepted=True,tests=results,production_writes=0,provider_calls=0)
 args.output.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
