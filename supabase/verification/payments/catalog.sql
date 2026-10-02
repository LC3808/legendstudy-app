-- Owner preflight, read-only. Never infer remote deployment from local files.
select version from supabase_migrations.schema_migrations order by version;
select name,to_regprocedure(name) is not null as present from unnest(array[
 'essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamp with time zone)',
 'essay_private.uid()','account_private.allowed(uuid)','account_private.lock_subject(uuid)']) name;
select name,to_regclass(name) as collision from unnest(array['public.payment_orders','public.payment_operations','public.payment_events','payment_private.configuration']) name;
select name,to_regprocedure(name) as collision from unnest(array['public.payment_order(jsonb)','public.payment_process(jsonb)','payment_private.result(uuid)','payment_private.spend_guard()']) name;
select current_user,rolsuper,rolcreaterole,rolbypassrls from pg_roles where rolname=current_user;
select pg_get_userbyid(roleid) role,pg_get_userbyid(member) member,pg_get_userbyid(grantor) grantor,admin_option,inherit_option,set_option from pg_auth_members where roleid='essay_executor'::regrole;
select nspname,nspacl from pg_namespace where nspname in ('public','essay_private','payment_private');
select 'essay_executor public CREATE',has_schema_privilege('essay_executor','public','CREATE');
select pg_get_userbyid(proowner),proacl,prosecdef,proconfig,pg_get_functiondef(oid) from pg_proc where oid='essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure;
