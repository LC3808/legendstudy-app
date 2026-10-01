"""ADR-2D topology regression; only called inside the disposable PG17 harness."""
import json
import psycopg
from pathlib import Path
R=Path(__file__).resolve().parents[1]
INVENTORY=json.loads((R/'supabase/verification/account_deletion/ownership_inventory.json').read_text())
def prepare(c,sock):
 admin=psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True)
 # Reproduce actual owner/ACL baseline via actual canonical functions, not Essay stubs.
 for f in INVENTORY['functions']:
  row=c.execute('select p.oid::regprocedure::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname=%s and p.proname=%s and pg_get_function_identity_arguments(p.oid)=%s',(f['nspname'],f['proname'],f['args'])).fetchone()
  assert row,f
  actual=c.execute('select pg_get_userbyid(proowner),proacl::text,prosecdef,proconfig from pg_proc where oid=%s::regprocedure',(row[0],)).fetchone()
  assert actual==(f['owner'],f['proacl'],f['prosecdef'],f['proconfig']),(f,actual)
 for role,member,grantor in c.execute("select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor) from pg_auth_members where roleid='essay_executor'::regrole").fetchall():
  c.execute(f'revoke {role} from {member} granted by {grantor}')
 admin.execute('grant essay_executor to postgres with admin true, inherit false, set false granted by supabase_admin')
 c.execute('grant usage on schema public to postgres')
 for n in INVENTORY['schemas']:
  if n['nspname']=='storage':continue
  actual=c.execute('select nspacl::text from pg_namespace where nspname=%s',(n['nspname'],)).fetchone()[0]
  assert sorted(actual[1:-1].split(','))==sorted(n['nspacl'][1:-1].split(',')),(n,actual)
 print('S1_PRODUCTION_SCHEMA_ACL_PASS',flush=True)
 # PostgreSQL cluster superuser is demoted ONLY for actual migration/rollback execution.
 # Supabase postgres is CREATEROLE+BYPASSRLS, not SUPERUSER.
 return admin

def execute_as_production(c,admin,text):
 admin.execute('alter role postgres nosuperuser createrole bypassrls')
 try:c.execute(text)
 finally:
  c.execute('rollback') # harmless after successful migration's COMMIT; clears aborted state
  admin.execute('alter role postgres superuser')


def snapshot(c):
 return (
  c.execute("select roleid,member,grantor,admin_option,inherit_option,set_option from pg_auth_members order by roleid,member,grantor").fetchall(),
  c.execute("select nspname,nspowner,nspacl::text from pg_namespace where nspname in ('public','essay_private') order by 1").fetchall(),
  c.execute("select p.oid,pg_get_functiondef(p.oid),p.proowner,p.proacl::text,p.prosecdef,p.proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private') order by p.oid").fetchall())

def negative_and_failure_tests(c,admin,text):
 before=snapshot(c)
 for label,sql in [('O2',"create or replace function essay_private.owner(p_session uuid) returns uuid language sql as 'select p_session'"),('O3','set role essay_executor')]:
  try:execute_as_production(c,admin,'begin;'+sql+';commit;');raise AssertionError(label)
  except psycopg.errors.InsufficientPrivilege:pass
  assert snapshot(c)==before;print(label+'_DENIED_PASS',flush=True)
 candidate=text.replace('grant create on schema essay_private to essay_executor;','-- omit CREATE to test SET-only bridge',1)
 try:execute_as_production(c,admin,candidate);raise AssertionError('SET-only bridge accepted')
 except psycopg.errors.InsufficientPrivilege as error:assert 'schema essay_private' in error.diag.message_primary
 assert snapshot(c)==before;print('S2_SET_WITHOUT_CREATE_DENIED_PASS',flush=True)
 for label,marker in [('S15','-- ADR2D_TEST_AFTER_FIRST_SCHEMA_GRANT'),('S16','-- ADR2D_TEST_AFTER_REPLACEMENTS'),('S17','-- ADR2D_TEST_AFTER_RESET'),('F1','-- ADR2D_FINANCE_F1'),('F2','-- ADR2D_FINANCE_F2'),('F3','-- ADR2D_FINANCE_F3'),('F4','-- ADR2D_FINANCE_F4')]:
  injected=text.replace(marker,marker+"\ndo $$begin raise exception 'ADR2D_INJECTED_FAILURE';end$$;",1)
  try:execute_as_production(c,admin,injected);raise AssertionError(label)
  except psycopg.errors.RaiseException as error:assert 'ADR2D_INJECTED_FAILURE' in str(error),str(error)
  assert snapshot(c)==before
  assert c.execute("select to_regnamespace('account_private') is null and to_regclass('public.account_deletion_requests') is null and to_regrole('account_erasure_executor') is null and to_regrole('account_lifecycle_worker') is null").fetchone()[0]
  print(label+'_FULL_RESTORATION_PASS',flush=True)
 # Verify all nine security contracts before the new finance ownership bridge.
 prefix=text.split('-- ADR-2D single new-function initialization')[0]
 post=text[text.index('-- Fail closed rather than commit privilege residue'):text.rindex('commit;')]
 admin.execute('alter role postgres nosuperuser createrole bypassrls')
 try:
  c.execute(prefix)
  c.execute(post)
  for f in INVENTORY['functions']:
   old=next(row for row in before[2] if row[1].startswith('CREATE OR REPLACE FUNCTION '+f['nspname']+'.'+f['proname']+'('))
   now=c.execute('select pg_get_functiondef(oid),proowner,proacl::text,prosecdef,proconfig from pg_proc where oid=%s',(old[0],)).fetchone()
   assert now[0]!=old[1],f
   assert now[1:]==old[2:],f
  print('NINE_REPLACEMENTS_OWNER_ACL_SECURITY_CONFIG_PASS',flush=True)
 finally:
  c.execute('rollback');admin.execute('alter role postgres superuser')
 assert snapshot(c)==before;print('PREFIX_ROLLBACK_EXACT_PASS',flush=True)

 def finance_probe(label,remove):
  candidate=text.replace(remove,'-- intentionally omitted for privilege requirement test',1)
  try:execute_as_production(c,admin,candidate);raise AssertionError(label)
  except psycopg.errors.InsufficientPrivilege as error:print(label+'_DENIED_PASS: '+error.diag.message_primary,flush=True)
  assert snapshot(c)==before
 finance_probe('FINANCE_SET_ONLY', 'grant create on schema account_private to account_erasure_executor;')
 finance_probe('FINANCE_CREATE_ONLY', 'grant account_erasure_executor to postgres with admin false, inherit false, set true granted by postgres;')


def after_apply(c,admin,text):
 before=snapshot(c)
 assert c.execute("select count(*) from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='supabase_admin'::regrole and admin_option and not inherit_option and not set_option").fetchone()[0]==1
 assert c.execute("select count(*) from pg_auth_members where roleid in ('essay_executor'::regrole,'account_erasure_executor'::regrole) and (set_option or inherit_option)").fetchone()[0]==0
 assert c.execute("select not has_schema_privilege('essay_executor','public','CREATE') and not has_schema_privilege('essay_executor','essay_private','CREATE') and not has_schema_privilege('account_erasure_executor','account_private','CREATE')").fetchone()[0]
 assert c.execute("select pg_get_userbyid(proowner)='account_erasure_executor' and prosecdef and proconfig=array['search_path=\"\"'] and has_function_privilege('postgres',oid,'EXECUTE') and not has_function_privilege('authenticated',oid,'EXECUTE') from pg_proc where oid='account_private.detach_finance(uuid)'::regprocedure").fetchone()[0]
 assert c.execute("select not enabled from account_private.dispatch_health").fetchone()[0]
 assert c.execute("select count(*) from pg_class where relnamespace=pg_my_temp_schema() and relname like 'adr2d_%'").fetchone()[0]==0
 print('S18_S20_FULL_NON_SUPERUSER_APPLY_NO_PRIVILEGE_RESIDUE_PASS',flush=True)
 try:execute_as_production(c,admin,text);raise AssertionError('rerun accepted')
 except psycopg.errors.RaiseException as error:assert 'namespace collision' in str(error),str(error)
 assert snapshot(c)==before;print('O16_RERUN_FAIL_CLOSED_NO_PRIVILEGE_CHANGE_PASS',flush=True)
