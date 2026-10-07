-- READ ONLY. Run through an existing approved DB connection; never paste credentials.
begin read only;
select version,name from supabase_migrations.schema_migrations
where version in ('20261007000100','20261007000200','20261007000400','20261007150000','20261008000100','20261008000200') order by version;
select p.oid::regprocedure signature,r.rolname owner,p.prosecdef,p.provolatile,p.proconfig,p.proacl,md5(p.prosrc) body_md5
from pg_proc p join pg_namespace n on n.oid=p.pronamespace join pg_roles r on r.oid=p.proowner
where (n.nspname='public' and p.proname like 'admin_%')
or (n.nspname='essay_private' and p.proname in ('credit_signup_eligible','credit_post_grant','credit_profile_signup'))
or (n.nspname='public' and p.proname in ('essay_claim_signup_credit','account_benefit_claim','account_benefit_candidates','credit_summary','is_quality_operator','essay_admin_grant'))
order by signature::text;
select exists(select 1 from auth.users where email='admin@legendstudy.com') account_exists,
 exists(select 1 from public.admin_users a join auth.users u on u.id=a.user_id where u.email='admin@legendstudy.com') admin_enrolled,
 exists(select 1 from public.quality_operators q join auth.users u on u.id=q.user_id where u.email='admin@legendstudy.com') quality_enrolled;
select c.relrowsecurity,p.polname,p.polcmd,p.polpermissive,p.polroles,pg_get_expr(p.polqual,p.polrelid) using_expression,pg_get_expr(p.polwithcheck,p.polrelid) check_expression
from pg_class c join pg_policy p on p.polrelid=c.oid where c.oid='public.profiles'::regclass;
select has_column_privilege('authenticated','public.profiles','intended_major','UPDATE') major_update,
 has_function_privilege('authenticated','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','EXECUTE') browser_grant,
 has_function_privilege('essay_finance','public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz)','EXECUTE') finance_grant;
select to_regprocedure('account_private.enabled()') lifecycle_switch,
 to_regclass('account_private.benefit_delivery') benefit_delivery,
 to_regclass('public.payment_orders') payment_orders;
-- Securely capture exact pg_get_functiondef, owners and ACL of replaced functions
-- separately before apply. Never export Auth passwords, JWTs, provider or finance secrets.
rollback;
