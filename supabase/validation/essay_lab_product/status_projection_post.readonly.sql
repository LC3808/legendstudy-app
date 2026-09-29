begin read only;
select jsonb_build_object(
 'function',(select jsonb_build_object('arguments',pg_get_function_identity_arguments(p.oid),'result',pg_get_function_result(p.oid),'owner',pg_get_userbyid(p.proowner),'path',p.proconfig,'definer',p.prosecdef,'volatility',p.provolatile,'source',p.prosrc) from pg_proc p where p.oid='public.essay_evaluation_status(uuid)'::regprocedure),
 'execute',(select jsonb_object_agg(role,has_function_privilege(role,'public.essay_evaluation_status(uuid)','EXECUTE')) from unnest(array['anon','authenticated','service_role','essay_worker','essay_finance','essay_executor']) role),
 'processing_select',(select jsonb_object_agg(role,has_table_privilege(role,'public.essay_ai_processing_runs','SELECT')) from unnest(array['anon','authenticated','service_role','essay_worker','essay_finance']) role)
) snapshot;
rollback;
