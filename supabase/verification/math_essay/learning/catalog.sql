-- Read-only Owner preflight. No application data or credential values.
begin read only;
select version from supabase_migrations.schema_migrations order by version;
select to_regprocedure('public.math_input(jsonb)') as required_math_2d,
 to_regprocedure('public.math_request_evaluation(uuid,uuid)') as required_request,
 to_regprocedure('public.math_learning(jsonb)') as collision,
 to_regprocedure('math_private.learning_state(uuid)') as state_collision,
 to_regprocedure('math_private.learning_eligibility(uuid,timestamptz)') as eligibility_collision;
select pg_get_userbyid(roleid) as role,pg_get_userbyid(member) as member,pg_get_userbyid(grantor) as grantor,admin_option,inherit_option,set_option
 from pg_auth_members where roleid in (select oid from pg_roles where rolname in ('math_executor','math_extraction_worker','math_evaluation_worker')) order by 1,2,3;
select nspname,pg_get_userbyid(nspowner),nspacl from pg_namespace where nspname in ('public','math_private');
select oid::regprocedure,pg_get_userbyid(proowner),prosecdef,proconfig,proacl from pg_proc where oid=to_regprocedure('math_private.validate_output(uuid,jsonb)');
commit;
