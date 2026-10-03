import tempfile,subprocess,pathlib,psycopg,json,hashlib
# LOCAL ONLY: platform/Auth fixtures below MUST NOT be run on Hosted Supabase.
R=pathlib.Path(__file__).resolve().parents[1];V=R/'supabase/verification/payments/hosted-test';b=pathlib.Path('/opt/homebrew/opt/postgresql@17/bin')
versions=['20260912000100','20260913000100','20260913000200','20260914000100','20260914000200','20260917000100','20260917000200','20260923000100','20260926000100','20260927000100','20260927000200','20260928000100','20260928000200','20260928000300','20260928000400','20260929000100','20260929000200','20260929000300','20260929000400','20260930000100','20261001000100','20261001000200','20261001000300','20261003000100']
with tempfile.TemporaryDirectory(prefix='payment-fresh-',dir='/private/tmp') as t:
 p=pathlib.Path(t);s=p/'socket';s.mkdir()
 def run(*a): return subprocess.run([str(b/a[0]),*map(str,a[1:])],check=True,capture_output=True,text=True)
 run('initdb','-D',p/'db','-U','supabase_admin','--auth=trust','--no-locale','--encoding=UTF8')
 run('pg_ctl','-D',p/'db','-l',p/'log','-o',f"-k {s} -c listen_addresses=''",'-w','start')
 try:
  with psycopg.connect(host=str(s),user='supabase_admin',dbname='postgres',autocommit=True) as a:
   a.execute('create role postgres login nosuperuser createrole createdb bypassrls; alter database postgres owner to postgres; alter schema public owner to postgres; create role authenticator login noinherit; create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls; create schema auth; create table auth.users(id uuid primary key,created_at timestamptz default now(),email_confirmed_at timestamptz); create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting(\'request.jwt.claim.sub\',true),\'\')::uuid $$; grant usage on schema auth to postgres,anon,authenticated,service_role; grant references on auth.users to postgres;')
  with psycopg.connect(host=str(s),user='postgres',dbname='postgres',autocommit=True) as c:
   c.execute('grant usage on schema public to anon,authenticated,service_role; alter default privileges in schema public grant all on tables to anon,authenticated,service_role; alter default privileges in schema public grant all on functions to anon,authenticated,service_role')
   def functions():
    return c.execute("select p.oid::regprocedure::text,pg_get_userbyid(p.proowner),p.prosecdef,p.proconfig,p.proacl::text,pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','essay_private','account_private','payment_private') order by 1").fetchall()
   manifest=[];previous={};before_payment=None
   for i,v in enumerate(versions):
    f=next((R/'supabase/migrations').glob(v+'_*.sql'))
    if v=='20261003000100':before_payment=functions()
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
   for role,expected in [('anon',False),('authenticated',False),('service_role',False),('essay_worker',False),('essay_finance',True)]:
    assert c.execute("select has_function_privilege(%s,'public.payment_process(jsonb)','EXECUTE')",(role,)).fetchone()[0] == expected
   # Real local gateway role switching, no JWT-signature simulation claim.
   c.execute('grant essay_finance to authenticator with admin false, inherit false, set true')
   with psycopg.connect(host=str(s),user='authenticator',dbname='postgres',autocommit=True) as gateway:
    gateway.execute('set role essay_finance')
    assert gateway.execute('select current_user').fetchone()[0]=='essay_finance'
    assert gateway.execute("select has_function_privilege(current_user,'public.payment_process(jsonb)','EXECUTE')").fetchone()[0]
    assert not gateway.execute("select pg_has_role(current_user,'essay_executor','MEMBER')").fetchone()[0]
    gateway.execute('reset role')
   c.execute('revoke essay_finance from authenticator')
   assert not c.execute("select pg_has_role('authenticator','essay_finance','MEMBER')").fetchone()[0]
   finance=c.execute("select p.oid::regprocedure::text from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and has_function_privilege('essay_finance',p.oid,'EXECUTE') order by 1").fetchall()
   schemas=c.execute("select nspname,pg_get_userbyid(nspowner),nspacl::text from pg_namespace where nspname in ('public','essay_private','account_private','payment_private') order by 1").fetchall()
   c.execute((R/'supabase/verification/payments/postflight.sql').read_text())
   assert c.execute("select mode from payment_private.configuration").fetchone()[0]=='TEST'
   assert c.execute('select count(*) from public.payment_orders').fetchone()[0]==0
   c.execute((R/'supabase/verification/payments/rollback.sql').read_text())
   assert before_payment==functions()
   migration=(R/'supabase/migrations/20261003000100_payment_foundation.sql').read_text()
   try:
    c.execute(migration[:migration.rfind('commit;')]+"do $$begin raise exception 'SYNTHETIC_FAILURE';end$$;commit;")
    raise AssertionError('failure injection accepted')
   except psycopg.errors.RaiseException:c.execute('rollback')
   assert before_payment==functions()
   assert c.execute("select to_regnamespace('payment_private')").fetchone()[0] is None
   c.execute(migration)
   V.mkdir(exist_ok=True)
   (V/'manifest.json').write_text(json.dumps({'scope':'Fresh TEST only. No db push; no Production replay. Managed auth fixtures excluded. Math/provider005/avatar/quota omitted.','migrations':manifest},indent=2)+'\n')
   (V/'validation.json').write_text(json.dumps({'postgres':'17.11','deployer':'NOSUPERUSER CREATEROLE BYPASSRLS','migration_count':len(manifest),'full_chain':'PASS','payment_postflight':'PASS','payment_empty_rollback':'PASS','payment_injected_failure_restoration':'PASS','role_memberships':topology,'schema_acl':schemas,'finance_public_execute_surface':finance,'db_execute_matrix':'PASS','local_authenticator_finance_set_and_revoke':'PASS','managed_auth_gateway':'HOSTED_VERIFICATION_REQUIRED','expired_invalid_signature_JWT':'HOSTED_VERIFICATION_REQUIRED','production_writes':0},indent=2)+'\n')
   print('FRESH_BOOTSTRAP_POSTFLIGHT_ROLLBACK_FAILURE_PASS',flush=True)
 finally:run('pg_ctl','-D',p/'db','-m','fast','-w','stop')
