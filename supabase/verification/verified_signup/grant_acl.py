"""Reproduce the hosted non-superuser grant failure, then test the one-function ACL fix.
Fresh local PG17 only; reuses the full lifecycle suite and its production topology.
"""
import pathlib,sys,tempfile
root=pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'tool'))
original_temp=tempfile.TemporaryDirectory
def portable_temp(*args,**kwargs):
    if kwargs.get('dir')=='/private/tmp':kwargs['dir']='/tmp'
    return original_temp(*args,**kwargs)
tempfile.TemporaryDirectory=portable_temp
path=root/'tool/test_account_deletion.py'; source=path.read_text()
anchor=' c.execute("alter table auth.users add column email_confirmed_at timestamptz default now()")'
assert source.count(anchor)==1
source=source.replace(anchor,anchor+'\n c.execute((h.R/"supabase/migrations/20261007150000_verified_signup_eligibility.sql").read_text())',1)
anchor=" result=rpc('account_benefit_claim',[V,Jsonb(m)],role='account_lifecycle_worker')"
assert source.count(anchor)==1
injection='''
 # Test transport only: allow caller-role simulation without essay_executor membership.
 admin.execute('grant account_lifecycle_worker,authenticated to postgres with admin false, inherit false, set true')
 admin.execute('alter role postgres nosuperuser createrole bypassrls')
 try:
  rpc('account_benefit_claim',[V,Jsonb(m)],role='account_lifecycle_worker')
  raise AssertionError('expected hosted grant failure')
 except psycopg.errors.InsufficientPrivilege as error:
  assert 'credit_post_grant' in error.diag.message_primary, error
 ok('HOSTED_42501_REPRODUCED')
 assert scalar('select count(*) from public.credit_accounts where user_id=%s',(V,))==0
 before_acl=scalar("select proacl::text from pg_proc where oid='essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure")
 # Transaction failure restores temporary membership and ACL exactly.
 c.execute("create schema supabase_migrations; create table supabase_migrations.schema_migrations(version text primary key,name text,statements text[])")
 migration=(h.R/'supabase/verification/verified_signup/apply_grant_acl.sql').read_text()
 before_members=scalar("select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m")
 try:
  c.execute(migration.replace('reset role;',"reset role; do $$begin raise exception 'injected';end$$;",1))
  raise AssertionError('expected injected failure')
 except psycopg.errors.RaiseException: c.execute('rollback')
 assert before_members==scalar("select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m")
 assert before_acl==scalar("select proacl::text from pg_proc where oid='essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure")
 ok('ACL_FAILED_APPLY_ROLLBACK_EXACT')
 c.execute(migration)
 ok('ACL_APPLY_NON_SUPERUSER')
 ok('ACL_LEDGER_RECORDED',scalar("select count(*) from supabase_migrations.schema_migrations where version='20261008000400'")==1)
 try:
  c.execute(migration);raise AssertionError('repeat must refuse')
 except psycopg.errors.RaiseException:c.execute('rollback')
 ok('ACL_REPEAT_REFUSED')
'''
source=source.replace(anchor,injection+'\n'+anchor,1)
anchor=" ok('D44',sorted(res)==['GRANTED','PREVIOUSLY_CLAIMED'])"
source=source.replace(anchor,anchor+"\n ok('ACL_SIGNUP_THREE_NO_EXPIRY',scalar(\"select count(*)=1 and sum(t.balance_delta)=3 and bool_and(g.expires_at is null) from public.credit_accounts a join public.credit_grants g on g.account_id=a.id join public.credit_transactions t on t.grant_id=g.id where a.user_id=%s and g.origin='signup_bonus'\",(V,)))",1)

# Keep the actual non-superuser owner during all signup/duplicate/concurrent calls.
# Restore the harness bootstrap role only after those assertions finish.
anchor=" # Cancelled history must allow final Auth FK identity erasure, not block it."
assert source.count(anchor)==1
source=source.replace(anchor," admin.execute('alter role postgres superuser')\n"+anchor,1)
exec(compile(source,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
