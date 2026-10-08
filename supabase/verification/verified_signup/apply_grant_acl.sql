-- Owner SQL Editor apply. One transaction; no manual grant or ledger mutation.
-- Refuse migration version collisions before changing ACLs.
begin;
do $$begin
 if exists(select 1 from supabase_migrations.schema_migrations where version='20261008000400') then
 raise exception 'MIGRATION_ALREADY_RECORDED_REVIEW_REQUIRED';end if;
end$$;
create temporary table benefit_acl_before on commit drop as
select p.oid, pg_get_functiondef(p.oid) definition, p.proowner, p.proconfig,
 (select coalesce(jsonb_agg(to_jsonb(m) order by roleid,member,grantor),'[]'::jsonb)
  from pg_auth_members m where roleid='essay_executor'::regrole) memberships
from pg_proc p where p.oid=to_regprocedure('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)');
do $$declare f record;begin
 if current_user <> 'postgres' then raise exception 'EXPECTED_POSTGRES';end if;
 select * into f from pg_proc where oid=to_regprocedure('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)');
 if not found or f.proowner<>'essay_executor'::regrole or not f.prosecdef
 or f.proconfig is distinct from array['search_path=""']::text[]
 or f.proacl::text is distinct from '{essay_executor=X/essay_executor}' then
 raise exception 'GRANT_HELPER_AUTHORITY_DRIFT';end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.account_benefit_claim(uuid,jsonb)')
 and proowner='postgres'::regrole and prosecdef and proconfig @> array['search_path=""']) then
 raise exception 'BENEFIT_CALLER_AUTHORITY_DRIFT';end if;
 if not has_schema_privilege('postgres','essay_private','USAGE') then raise exception 'SCHEMA_USAGE_MISSING';end if;
 if exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='postgres'::regrole)
 or not exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and admin_option) then
 raise exception 'TEMPORARY_ROLE_BRIDGE_UNAVAILABLE';end if;
end$$;
-- Existing supabase_admin membership stays untouched; no schema CREATE is needed.
grant essay_executor to postgres with admin false, inherit false, set true granted by postgres;
set local role essay_executor;
grant execute on function essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz) to postgres;
reset role;
revoke essay_executor from postgres granted by postgres;
do $$declare b record;role_name text;begin
 select * into strict b from benefit_acl_before;
 if not has_function_privilege('postgres',b.oid,'EXECUTE') then raise exception 'GRANT_NOT_EFFECTIVE';end if;
 foreach role_name in array array['anon','authenticated','service_role','account_lifecycle_worker','essay_worker','essay_finance'] loop
 if has_function_privilege(role_name,b.oid,'EXECUTE') then raise exception 'DIRECT_GRANT_BOUNDARY_EXPANDED';end if;
 end loop;
 if not exists(select 1 from pg_proc p where p.oid=b.oid and p.proowner=b.proowner
 and pg_get_functiondef(p.oid)=b.definition and p.proconfig=b.proconfig) then
 raise exception 'HELPER_DEFINITION_CHANGED';end if;
 if b.memberships is distinct from (select coalesce(jsonb_agg(to_jsonb(m) order by roleid,member,grantor),'[]'::jsonb)
 from pg_auth_members m where roleid='essay_executor'::regrole) then raise exception 'ROLE_MEMBERSHIP_CHANGED';end if;
end$$;
insert into supabase_migrations.schema_migrations(version,name,statements)
values('20261008000400','benefit_grant_executor_acl',array[$migration$-- Only the postgres-owned benefit RPC may call the existing private grant helper.
-- No function replacement, ledger write, PUBLIC/service_role grant or owner change.
begin;
create temporary table benefit_acl_before on commit drop as
select p.oid, pg_get_functiondef(p.oid) definition, p.proowner, p.proconfig,
 (select coalesce(jsonb_agg(to_jsonb(m) order by roleid,member,grantor),'[]'::jsonb)
  from pg_auth_members m where roleid='essay_executor'::regrole) memberships
from pg_proc p where p.oid=to_regprocedure('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)');
do $$declare f record;begin
 if current_user <> 'postgres' then raise exception 'EXPECTED_POSTGRES';end if;
 select * into f from pg_proc where oid=to_regprocedure('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)');
 if not found or f.proowner<>'essay_executor'::regrole or not f.prosecdef
 or f.proconfig is distinct from array['search_path=""']::text[]
 or f.proacl::text is distinct from '{essay_executor=X/essay_executor}' then
 raise exception 'GRANT_HELPER_AUTHORITY_DRIFT';end if;
 if not exists(select 1 from pg_proc where oid=to_regprocedure('public.account_benefit_claim(uuid,jsonb)')
 and proowner='postgres'::regrole and prosecdef and proconfig @> array['search_path=""']) then
 raise exception 'BENEFIT_CALLER_AUTHORITY_DRIFT';end if;
 if not has_schema_privilege('postgres','essay_private','USAGE') then raise exception 'SCHEMA_USAGE_MISSING';end if;
 if exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='postgres'::regrole)
 or not exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and admin_option) then
 raise exception 'TEMPORARY_ROLE_BRIDGE_UNAVAILABLE';end if;
end$$;
-- Existing supabase_admin membership stays untouched; no schema CREATE is needed.
grant essay_executor to postgres with admin false, inherit false, set true granted by postgres;
set local role essay_executor;
grant execute on function essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz) to postgres;
reset role;
revoke essay_executor from postgres granted by postgres;
do $$declare b record;role_name text;begin
 select * into strict b from benefit_acl_before;
 if not has_function_privilege('postgres',b.oid,'EXECUTE') then raise exception 'GRANT_NOT_EFFECTIVE';end if;
 foreach role_name in array array['anon','authenticated','service_role','account_lifecycle_worker','essay_worker','essay_finance'] loop
 if has_function_privilege(role_name,b.oid,'EXECUTE') then raise exception 'DIRECT_GRANT_BOUNDARY_EXPANDED';end if;
 end loop;
 if not exists(select 1 from pg_proc p where p.oid=b.oid and p.proowner=b.proowner
 and pg_get_functiondef(p.oid)=b.definition and p.proconfig=b.proconfig) then
 raise exception 'HELPER_DEFINITION_CHANGED';end if;
 if b.memberships is distinct from (select coalesce(jsonb_agg(to_jsonb(m) order by roleid,member,grantor),'[]'::jsonb)
 from pg_auth_members m where roleid='essay_executor'::regrole) then raise exception 'ROLE_MEMBERSHIP_CHANGED';end if;
end$$;
commit;
$migration$]);
commit;

select
 exists(select 1 from supabase_migrations.schema_migrations where version='20261008000400') as migration_recorded,
 has_function_privilege('postgres',oid,'EXECUTE') as postgres_can_execute,
 has_function_privilege('authenticated',oid,'EXECUTE') as authenticated_can_execute,
 has_function_privilege('service_role',oid,'EXECUTE') as service_role_can_execute,
 pg_get_userbyid(proowner) as owner, proacl as acl
from pg_proc where oid='essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure;
