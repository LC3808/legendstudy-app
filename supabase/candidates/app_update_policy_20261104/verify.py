"""Disposable PG17, no network/remote DB/Provider. Exact candidate, NOSUPERUSER postgres."""
from pathlib import Path
import tempfile,subprocess,json,hashlib,os,sys
import psycopg

# No DSN, host, user, database, or remote endpoint arguments are accepted.
if len(sys.argv)!=1:
 raise SystemExit('No connection arguments accepted. This verifier starts its own local Unix-socket PostgreSQL17.')
SOURCE=Path(__file__).resolve().parent
BIN=Path(os.environ.get('LOCAL_PG_BIN','/opt/homebrew/opt/postgresql@17/bin')).expanduser().resolve()
for name in ('postgres','initdb','pg_ctl'):
 if not (BIN/name).is_file():raise SystemExit('Set LOCAL_PG_BIN to a local PostgreSQL17 bin directory.')
version=subprocess.run([str(BIN/'postgres'),'--version'],check=True,text=True,capture_output=True).stdout
if ' 17.' not in version:raise SystemExit('This proof requires PostgreSQL17.')
candidates=list(SOURCE.glob('*_app_update_policy_disabled_candidate.sql'))
if len(candidates)!=1:raise SystemExit('Expected exactly one adjacent app update policy candidate.')
SQL=candidates[0].read_text(encoding='utf-8');checks=[]
OUTPUT=Path(tempfile.mkdtemp(prefix='legendstudy-app-update-proof-',dir='/tmp'))
log=(OUTPUT/'validation.log').open('w',encoding='utf-8')
class Tee:
 def __init__(self,stream):self.stream=stream
 def write(self,value):self.stream.write(value);log.write(value);return len(value)
 def flush(self):self.stream.flush();log.flush()
sys.stdout=Tee(sys.stdout);sys.stderr=Tee(sys.stderr)
print('LOCAL_PROOF_OUTPUT',OUTPUT,flush=True)
def command(args):subprocess.run([str(x) for x in args],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE)
with tempfile.TemporaryDirectory(prefix='pg-',dir=OUTPUT) as tmp:
 d=Path(tmp);sock=d/'socket';sock.mkdir();data=d/'data'
 command([BIN/'initdb','-D',data,'-U','supabase_admin','--auth=trust','--no-locale','-E','UTF8'])
 command([BIN/'pg_ctl','-D',data,'-l',d/'pg.log','-o',f"-k {sock} -c listen_addresses='' -p 5432",'-w','start'])
 try:
  with psycopg.connect(host=str(sock),port=5432,user='supabase_admin',dbname='postgres',autocommit=True) as admin:
   admin.execute('create role postgres login nosuperuser createrole bypassrls;create role anon;create role authenticated;create role service_role bypassrls;alter database postgres owner to postgres;alter schema public owner to postgres;grant usage on schema public to anon,authenticated,service_role;grant anon,authenticated,service_role to postgres with inherit false,set true;')
   # Simulate broad Supabase-style default grants; candidate must explicitly revoke them.
   admin.execute('alter default privileges for role postgres grant all on tables to anon,authenticated,service_role;alter default privileges for role postgres grant execute on functions to anon,authenticated,service_role;')
  with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as c:
   def scalar(q,args=()):return c.execute(q,args).fetchone()[0]
   def ok(label,condition=True):assert condition,label;checks.append(label);print(label,'PASS',flush=True)
   def rpc(platform,role='anon'):
    with c.transaction():
     c.execute('set local role '+role)
     result=scalar('select public.app_update_policy(%s)',(platform,));c.execute('reset role');return result
   def patch(fragment,args=()):c.execute('update app_release_private.platform_policy set '+fragment+" where platform='ios'",args)
   # Install failure rolls back all newly created objects.
   try:c.execute(SQL.replace("notify pgrst,'reload schema';","do $$begin raise exception 'INTENTIONAL_FAILURE';end$$;"))
   except psycopg.errors.RaiseException as e:assert 'INTENTIONAL_FAILURE' in str(e);c.execute('rollback')
   else:raise AssertionError('rollback probe did not fail')
   ok('ATOMIC_INSTALL_FAILURE_NO_SCHEMA_OR_RPC',scalar("select to_regnamespace('app_release_private') is null and to_regprocedure('public.app_update_policy(text)') is null"))
   c.execute(SQL)
   ok('INSTALL_AS_NON_SUPERUSER',not scalar("select rolsuper from pg_roles where rolname=current_user"))
   ok('INITIAL_TWO_DISABLED_OPTIONAL_LATEST_MIN_UNSET',scalar("select count(*)=2 and bool_and(not enabled and update_type='OPTIONAL' and latest_version is null and latest_build is null and minimum_supported_version is null and minimum_supported_build is null) from app_release_private.platform_policy"))
   for role in ['anon','authenticated']:
    for platform in ['ios','android',None,'web','IOS','ios;drop table x']:
     ok('DEFAULT_OR_INVALID_NULL_'+role+'_'+str(platform),rpc(platform,role) is None)
   ok('SECURITY_DEFINER_FIXED_EMPTY_SEARCH_PATH',scalar("select prosecdef and proconfig=array['search_path=\"\"'] and proowner='postgres'::regrole from pg_proc where oid='public.app_update_policy(text)'::regprocedure"))
   ok('PRIVATE_TABLE_FORCE_RLS',scalar("select relrowsecurity and relforcerowsecurity from pg_class where oid='app_release_private.platform_policy'::regclass"))
   for role in ['anon','authenticated','service_role']:
    for statement in ['select * from app_release_private.platform_policy',"update app_release_private.platform_policy set enabled=true", "insert into app_release_private.platform_policy(platform,store_url) values('ios','x')",'delete from app_release_private.platform_policy',"select app_release_private.version_key('1.0.1',58)"]:
     try:
      with c.transaction():c.execute('set local role '+role);c.execute(statement)
     except psycopg.errors.InsufficientPrivilege:pass
     else:raise AssertionError(role+' direct access allowed '+statement)
    ok('CLIENT_DIRECT_READ_WRITE_HELPER_DENIED_'+role)
   try:rpc('ios','service_role')
   except psycopg.errors.InsufficientPrivilege:pass
   else:raise AssertionError('service rpc unexpectedly permitted')
   ok('ONLY_ANON_AUTH_RPC_NOT_SERVICE')
   key=lambda v,b:scalar('select app_release_private.version_key(%s,%s)',(v,b))
   for a,ab,b,bb in [('1.0.9',99,'1.0.10',1),('1.9.0',100,'1.10.0',1),('1.0.1',57,'1.0.1',58),('1.99.99',999,'2.0.0',1)]:ok('NUMERIC_ORDER_'+a+'_'+str(ab)+'_'+b,key(a,ab)<key(b,bb))
   ok('PADDED_VERSION_EQUAL',key('1.0',58)==key('1.0.0.0',58))
   for v,b in [('1.0.1-rc',58),('1',58),('1.0.1.2.3',58),('10000000.0',58),('1.0',-1),('',0),(None,1),('1.0',None),('1.٠',1)]:ok('MALFORMED_KEY_NULL_'+str(v)+'_'+str(b),key(v,b) is None)
   # All updates below affect this disposable policy fixture only.
   patch("enabled=true,latest_version='1.0.10',latest_build=60,release_notes='검증용' ")
   ok('UNVERIFIED_PUBLICATION_NULL',rpc('ios') is None)
   patch("store_release_verified=true,verified_store_version='1.0.10',verified_store_build=60,verified_at=statement_timestamp()-interval '1 hour',verification_reference='LOCAL SYNTHETIC STORE PROOF'")
   published=rpc('ios');ok('VERIFIED_IOS_OPTIONAL',published['latest_version']=='1.0.10' and published['latest_build']==60 and published['required_approved'] is False and published['update_type']=='OPTIONAL')
   ok('ANDROID_NOT_INHERITING_IOS',rpc('android') is None)
   ok('NO_PRIVATE_APPROVAL_METADATA_EXPOSED',set(published)=={'version','platform','latest_version','latest_build','minimum_supported_version','minimum_supported_build','update_type','release_notes','store_url','enabled','store_release_verified','required_approved','verified_at'})
   for fragment in ["verified_store_version='1.0.9'","verified_store_build=59","verified_at=statement_timestamp()+interval '1 day'","verification_reference=' '","verified_at=null","store_release_verified=false","enabled=false"]:
    with c.transaction():
     patch(fragment);ok('PUBLICATION_GUARD_'+fragment,rpc('ios') is None)
     # Restore canonical row inside this transaction, avoiding test-only schema bypass.
     patch("enabled=true,store_release_verified=true,verified_store_version='1.0.10',verified_store_build=60,verified_at=statement_timestamp()-interval '1 hour',verification_reference='LOCAL SYNTHETIC STORE PROOF'")
   patch("update_type='REQUIRED',minimum_supported_version='1.0.9',minimum_supported_build=55")
   ok('UNAPPROVED_REQUIRED_NEVER_FORCED',rpc('ios')['required_approved'] is False)
   patch("required_approved=true,approved_minimum_version='1.0.9',approved_minimum_build=55,required_approved_at=statement_timestamp()-interval '1 hour',approval_reference='LOCAL SYNTHETIC OWNER APPROVAL'")
   ok('EXACT_APPROVED_MINIMUM_REQUIRED',rpc('ios')['required_approved'] is True)
   for fragment in ["approved_minimum_version='1.0.8'","approved_minimum_build=54","required_approved_at=statement_timestamp()+interval '1 day'","required_approved_at=null","approval_reference=' '","required_approved=false"]:
    patch(fragment);ok('REQUIRED_GUARD_'+fragment,rpc('ios')['required_approved'] is False)
    patch("required_approved=true,approved_minimum_version='1.0.9',approved_minimum_build=55,required_approved_at=statement_timestamp()-interval '1 hour',approval_reference='LOCAL SYNTHETIC OWNER APPROVAL'")
   patch("minimum_supported_build=56");ok('MINIMUM_CHANGED_OLD_APPROVAL_INVALID',rpc('ios')['required_approved'] is False)
   patch("latest_version='1.0.11'");ok('LATEST_CHANGED_OLD_STORE_VERIFICATION_INVALID',rpc('ios') is None)
   for fragment in ["latest_version='1.0.1-rc'","latest_build=-1","latest_build=null","minimum_supported_version='9.0.0'","update_type='FORCE'","store_url='https://example.com/app'","verified_at='infinity'","required_approved_at='-infinity'","release_notes=repeat('x',2001)"]:
    try:
     with c.transaction():patch(fragment)
    except psycopg.errors.CheckViolation:pass
    else:raise AssertionError('invalid config accepted '+fragment)
    ok('MALFORMED_POLICY_WRITE_DENIED_'+fragment)
   patch('release_notes=%s',('😀'*1000,));ok('UTF16_NOTES_2000_UNITS_ALLOWED')
   try:
    with c.transaction():patch('release_notes=%s',('😀'*1001,))
   except psycopg.errors.CheckViolation:pass
   else:raise AssertionError('UTF16 notes exceeded APP boundary')
   ok('UTF16_NOTES_2002_UNITS_REJECTED')
   # New platform verification remains separate and uses its exact official URL.
   c.execute("update app_release_private.platform_policy set enabled=true,latest_version='2.0.0',latest_build=100,store_release_verified=true,verified_store_version='2.0.0',verified_store_build=100,verified_at=statement_timestamp(),verification_reference='LOCAL SYNTHETIC ANDROID PROOF' where platform='android'")
   ok('ANDROID_SEPARATE_POLICY_AND_OFFICIAL_URL',rpc('android')['store_url']=='https://play.google.com/store/apps/details?id=com.legendstudy.app')
   # Reapplying cannot replace an Owner policy.
   before=scalar('select jsonb_agg(to_jsonb(p) order by platform) from app_release_private.platform_policy p')
   try:c.execute(SQL)
   except psycopg.errors.RaiseException as e:assert 'ALREADY_EXISTS' in str(e);c.execute('rollback')
   else:raise AssertionError('collision overwrite allowed')
   ok('RERUN_FAIL_CLOSED_POLICY_PRESERVED',before==scalar('select jsonb_agg(to_jsonb(p) order by platform) from app_release_private.platform_policy p'))
   meta=c.execute("select n.nspname,p.proname,pg_get_userbyid(p.proowner),p.proacl::text,p.proconfig,md5(pg_get_functiondef(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.oid in('public.app_update_policy(text)'::regprocedure,'app_release_private.version_key(text,integer)'::regprocedure) order by 1,2").fetchall()
   (OUTPUT/'expected-postflight.json').write_text(json.dumps([dict(zip(['schema','function','owner','acl','config','definition_md5'],r)) for r in meta],indent=2)+'\n')
   (OUTPUT/'verification.json').write_text(json.dumps({'status':'LOCAL_PG17_PASS','checks':checks,'count':len(checks),'candidate_sha256':hashlib.sha256(SQL.encode()).hexdigest(),'remote_production_changes':0,'remote_test_changes':0,'provider_calls':0,'role':'postgres NOSUPERUSER BYPASSRLS','store_state':'Synthetic fixture only; no public release assertion'},ensure_ascii=False,indent=2)+'\n')
   print('APP_UPDATE_POLICY_TOTAL',len(checks),'PASS',flush=True)
 finally:command([BIN/'pg_ctl','-D',data,'-m','immediate','-w','stop'])
