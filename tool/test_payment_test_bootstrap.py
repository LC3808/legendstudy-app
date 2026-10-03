import tempfile,subprocess,pathlib,psycopg,json,hashlib
import payment_hosted_fixture as platform
# LOCAL ONLY: platform/Auth fixtures below MUST NOT be run on Hosted Supabase.
R=pathlib.Path(__file__).resolve().parents[1];V=R/'supabase/verification/payments/hosted-test';b=pathlib.Path('/opt/homebrew/opt/postgresql@17/bin')
allowlist=json.loads((V/'manifest.json').read_text())['migrations']
assert len(allowlist)==24
for index,row in enumerate(allowlist):
 assert row['order']==index+1
 assert hashlib.sha256((R/'supabase/migrations'/row['filename']).read_bytes()).hexdigest()==row['sha256'],row['filename']
versions=[row['filename'].split('_')[0] for row in allowlist]
observed=json.loads((V/'observed-platform.json').read_text())

with tempfile.TemporaryDirectory(prefix='payment-fresh-',dir='/private/tmp') as t:
 p=pathlib.Path(t);s=p/'socket';s.mkdir()
 def run(*a): return subprocess.run([str(b/a[0]),*map(str,a[1:])],check=True,capture_output=True,text=True)
 run('initdb','-D',p/'db','-U','supabase_admin','--auth=trust','--no-locale','--encoding=UTF8')
 run('pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {s} -c listen_addresses=''",'-w','start')
 try:
  with psycopg.connect(host=str(s),user='supabase_admin',dbname='postgres',autocommit=True) as a:
   platform.setup(a,observed)
  with psycopg.connect(host=str(s),user='postgres',dbname='postgres',autocommit=True) as c:
   platform.verify(c,observed)
   print('OBSERVED_PLATFORM_PREFLIGHT_PASS',flush=True)
   def functions():
    return c.execute("select p.oid::regprocedure::text,pg_get_userbyid(p.proowner),p.prosecdef,p.proconfig,p.proacl::text,pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private','account_private','payment_private') order by 1").fetchall()
   def snapshot():
    return (
     functions(),
     c.execute('select roleid,member,grantor,admin_option,inherit_option,set_option from pg_auth_members order by roleid,member,grantor').fetchall(),
     c.execute("select nspname,nspowner,nspacl::text from pg_namespace where nspname in ('public','essay_private','account_private','payment_private') order by 1").fetchall(),
     c.execute("select oid,relowner,relacl::text,relrowsecurity,relforcerowsecurity from pg_class where relnamespace in (select oid from pg_namespace where nspname in ('public','essay_private','account_private','payment_private')) order by oid").fetchall(),
     c.execute('select defaclrole,defaclnamespace,defaclobjtype,defaclacl::text from pg_default_acl order by 1,2,3').fetchall())
   manifest=[];previous={};before_payment=None
   for i,v in enumerate(versions):
    f=next((R/'supabase/migrations').glob(v+'_*.sql'))
    if v=='20261003000100':before_payment=snapshot()
    try:
     c.execute(f.read_text());print(v,'PASS',flush=True)
     now={row[0]:row for row in functions()}
     changed=[{'signature':row[0],'owner':row[1],'security':'DEFINER' if row[2] else 'INVOKER','config':row[3],'execute_acl':row[4]} for key,row in now.items() if previous.get(key)!=row]
     manifest.append({'order':i+1,'filename':f.name,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'dependency':'Managed auth.users/auth.uid and platform roles' if not i else 'All preceding allowlisted entries (conservative exact tested chain)','deployer':'postgres NOSUPERUSER CREATEROLE BYPASSRLS','function_changes':changed,'roles_present':c.execute("select rolname from pg_roles where rolname like 'essay_%' or rolname like 'account_%' order by 1").fetchall()})
     previous=now
    except psycopg.Error as e:
     print(v,'BLOCKED',e.sqlstate,e.diag.message_primary,flush=True);c.execute('rollback');raise
   topology=c.execute("select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where pg_get_userbyid(roleid) like 'essay_%' or pg_get_userbyid(roleid) like 'account_%' order by 1,2").fetchall()
   assert all(row[1:] == ('postgres','supabase_admin',True,False,False) for row in topology)
   assert not c.execute("select has_schema_privilege('essay_executor','public','CREATE') or has_schema_privilege('essay_executor','essay_private','CREATE')").fetchone()[0]
   original={tuple((r['role'],r['member'],r['grantor'],r['admin'],r['inherit'],r['set'])) for r in observed['memberships']}
   current=set(c.execute("select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where pg_get_userbyid(member) in ('postgres','authenticator','anon','authenticated','service_role')").fetchall())
   assert current==original|set(topology)
   owner,acl=c.execute("select pg_get_userbyid(nspowner),nspacl::text from pg_namespace where nspname='public'").fetchone()
   original_acl=next(row['acl'] for row in observed['schemas'] if row['name']=='public')
   assert owner=='pg_database_owner'
   assert set(acl[1:-1].split(','))==set(original_acl[1:-1].split(','))|{row[0]+'=U/pg_database_owner' for row in topology}
   for name in ['payment_orders','payment_operations','payment_events']:
    assert c.execute("select pg_get_userbyid(relowner),relrowsecurity from pg_class where oid=%s::regclass",('public.'+name,)).fetchone()==('postgres',True)
    for role in ['anon','authenticated','service_role']:
     assert not c.execute("select has_table_privilege(%s,%s,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE')",(role,'public.'+name)).fetchone()[0]
   for role,expected in [('anon',False),('authenticated',False),('service_role',False),('essay_worker',False),('essay_finance',True)]:
    assert c.execute("select has_function_privilege(%s,'public.payment_process(jsonb)','EXECUTE')",(role,)).fetchone()[0] == expected
   # Compatibility phase leaves even the disposable gateway unenrolled.
   assert not c.execute("select pg_has_role('authenticator','essay_finance','MEMBER')").fetchone()[0]
   finance=c.execute("select p.oid::regprocedure::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('essay_finance',p.oid,'EXECUTE') order by 1").fetchall()
   schemas=c.execute("select nspname,pg_get_userbyid(nspowner),nspacl::text from pg_namespace where nspname in ('public','essay_private','account_private','payment_private') order by 1").fetchall()
   c.execute((R/'supabase/verification/payments/postflight.sql').read_text())
   assert c.execute("select mode from payment_private.configuration").fetchone()[0]=='TEST'
   assert c.execute('select count(*) from public.payment_orders').fetchone()[0]==0
   c.execute((R/'supabase/verification/payments/rollback.sql').read_text())
   assert before_payment==snapshot()
   migration=(R/'supabase/migrations/20261003000100_payment_foundation.sql').read_text()
   failure_points=[
    'grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;',
    'grant create on schema public to essay_executor;',
    'set role essay_executor;',
    'grant execute on function public.payment_order(jsonb) to authenticated;',
    'reset role;',
   ]
   failure_pass=[]
   for marker in failure_points+['before_commit']:
    if marker=='before_commit':
     candidate=migration[:migration.rfind('commit;')]+"do $$begin raise exception 'SYNTHETIC_FAILURE';end$$;commit;"
    else:
     assert marker in migration
     candidate=migration.replace(marker,marker+"\ndo $$begin raise exception 'SYNTHETIC_FAILURE';end$$;",1)
    try:
     c.execute(candidate)
     raise AssertionError('failure injection accepted')
    except psycopg.errors.RaiseException as error:
     assert error.diag.message_primary=='SYNTHETIC_FAILURE'
     c.execute('rollback')
    assert before_payment==snapshot()
    assert c.execute("select to_regnamespace('payment_private')").fetchone()[0] is None
    failure_pass.append(marker)
   c.execute(migration)
   V.mkdir(exist_ok=True)
   assert json.loads(json.dumps(manifest))==allowlist, 'Canonical manifest drift; do not regenerate allowlist'
   (V/'validation.json').write_text(json.dumps({'postgres':'17.11','public_schema_owner':'pg_database_owner','public_schema_acl_grantor':'pg_database_owner','observed_public_preflight':'PASS','observed_roles_memberships_default_acls':'PASS','managed_extensions_auth_runtime':'NOT_EMULATED; local Auth facilities only; no Hosted JWT claim','deployer':'NOSUPERUSER CREATEROLE BYPASSRLS','migration_count':len(manifest),'full_chain':'PASS','payment_postflight':'PASS','payment_empty_rollback':'PASS','payment_injected_failure_restoration':'PASS','role_memberships':topology,'schema_acl':schemas,'finance_public_execute_surface':finance,'db_execute_matrix':'PASS','finance_gateway_enrolled':False,'failure_points':failure_pass,'rollback_catalog_membership_schema_default_acl_exact':'PASS','managed_auth_gateway':'HOSTED_VERIFICATION_REQUIRED','expired_invalid_signature_JWT':'HOSTED_VERIFICATION_REQUIRED','production_writes':0},indent=2)+'\n')
   print('FRESH_BOOTSTRAP_POSTFLIGHT_ROLLBACK_FAILURE_PASS',flush=True)
 finally:run('pg_ctl','-D',p/'db','-m','fast','-w','stop')
