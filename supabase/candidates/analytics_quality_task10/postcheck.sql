-- Read only. Both RPCs: definer true, search_path="", auth true, anon/service false.
select p.oid::regprocedure,p.prosecdef,p.proconfig,
 has_function_privilege('authenticated',p.oid,'execute') authenticated,
 has_function_privilege('anon',p.oid,'execute') anon,
 has_function_privilege('service_role',p.oid,'execute') service_role
from pg_proc p where p.oid in ('public.essay_feedback_submit(jsonb)'::regprocedure,
 'public.admin_essay_satisfaction(timestamptz,timestamptz)'::regprocedure);
select column_name,data_type from information_schema.columns
 where table_schema='feedback_private' and table_name='essay_context'
 and column_name in ('rating','positive_reasons','negative_reasons');
