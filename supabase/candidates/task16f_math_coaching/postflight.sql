-- Read-only metadata checks; run against reviewed isolated TEST only.
select to_regprocedure('public.math_coaching(jsonb)') is not null as coaching_exists,
 has_function_privilege('authenticated','public.math_coaching(jsonb)','EXECUTE') as student_rpc,
 not has_function_privilege('anon','public.math_coaching(jsonb)','EXECUTE') as anonymous_denied,
 not has_function_privilege('authenticated','public.math_evaluation_detail_task16f_legacy(uuid)','EXECUTE') as raw_detail_denied,
 not has_function_privilege('authenticated','public.math_learning_task16f_legacy(jsonb)','EXECUTE') as raw_learning_denied,
 not has_table_privilege('authenticated','math_private.coaching_disclosures','SELECT,INSERT,UPDATE,DELETE') as private_events;
select relrowsecurity from pg_class where oid='math_private.coaching_disclosures'::regclass;
-- These catalog checks do NOT prove behavioral disclosure safety or compatibility.
