-- Owner post-apply read-only catalog verification (not a substitute for real-role RPC tests).
select oid::regprocedure signature,md5(pg_get_functiondef(oid)) definition_md5,
 pg_get_userbyid(proowner) owner,proacl,prosecdef,proconfig,
 has_function_privilege('anon',oid,'EXECUTE') anon_execute,
 has_function_privilege('authenticated',oid,'EXECUTE') authenticated_execute
from pg_proc where oid in ('public.qlm_list_cases(integer,timestamptz,uuid)'::regprocedure,
 'public.qlm_case_detail(uuid)'::regprocedure);
-- Match candidate_function_fingerprints.json; anon=false; authenticated=true plus
-- unchanged hq_require_operator runtime guard. Run acceptance_readonly.sql for facts.
-- With authenticated operator: qlm_quality list/detail must return quality_metadata;
-- paired cursors and prior links must match. Real anon/nonoperator calls must deny.
