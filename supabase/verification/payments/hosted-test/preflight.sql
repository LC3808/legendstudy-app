-- READ ONLY. Run only after Owner identifies the NEW EMPTY TEST project.
select current_user,version();
select rolname,rolsuper,rolcreaterole,rolbypassrls,rolcanlogin,rolinherit from pg_roles
where rolname in ('postgres','authenticator','anon','authenticated','service_role','supabase_admin','essay_executor','essay_finance','essay_worker','account_erasure_executor','account_lifecycle_worker');
select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members;
select nspname,pg_get_userbyid(nspowner),nspacl from pg_namespace where nspname in ('public','auth','essay_private','account_private','payment_private');
select to_regclass('auth.users'),to_regprocedure('auth.uid()'),to_regclass('public.profiles'),to_regclass('public.payment_orders');
select pg_get_userbyid(defaclrole),defaclnamespace::regnamespace,defaclobjtype,defaclacl from pg_default_acl;
select extname,extversion,extnamespace::regnamespace from pg_extension;
-- No student rows, credentials, backup contents or mutating RPC calls.
