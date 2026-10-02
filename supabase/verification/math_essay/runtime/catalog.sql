-- Read-only Owner postflight; no application row content.
begin read only;
select oid::regprocedure::text,pg_get_function_arguments(oid),pg_get_userbyid(proowner),prosecdef,proconfig,proacl::text
from pg_proc where pronamespace='public'::regnamespace and proname in ('math_input','math_extraction','math_evaluation','qlm_quality') order by proname;
select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option
from pg_auth_members where roleid in ('math_executor'::regrole,'math_extraction_worker'::regrole,'math_evaluation_worker'::regrole) order by 1,2,3;
select has_schema_privilege('math_executor','public','CREATE') as unexpected_temporary_create;
select indexdef from pg_indexes where schemaname='public' and indexname='math_confirmed_candidate_once';
commit;
