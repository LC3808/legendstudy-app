select p.oid::regprocedure,p.prosecdef,p.proconfig,pg_get_userbyid(p.proowner),
 has_function_privilege('authenticated',p.oid,'execute') authenticated,
 has_function_privilege('anon',p.oid,'execute') anon,
 has_function_privilege('service_role',p.oid,'execute') service_role
 from pg_proc p where p.proname in ('admin_essay_operations','admin_essay_operations_estimate','admin_essay_operations_check_alerts');
select relname,relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='essay_ops_private' and relkind='r';
select grantee,table_name,privilege_type from information_schema.role_table_grants where table_schema='essay_ops_private';
-- Authorized/denied JWT calls are mandatory before WEB flag/release; no evaluation call.
select count(*) from essay_ops_private.prices; -- Initially zero; pricing needs verified source approval.
