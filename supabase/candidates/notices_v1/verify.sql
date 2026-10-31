-- Read-only postflight. Do not infer behavioral tests from catalog checks.
select p.proname,pg_get_function_identity_arguments(p.oid),p.prosecdef,p.proconfig,
 has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute,
 has_function_privilege('service_role',p.oid,'EXECUTE') service_execute
from pg_proc p where p.pronamespace='public'::regnamespace and p.proname like 'notice_%';
select relname,relrowsecurity from pg_class where relnamespace='notice_private'::regnamespace and relkind='r';
select count(*) notice_count from notice_private.notices;
