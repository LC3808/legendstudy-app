-- SELECT only. Before install expect zero functions; after install expect three.
select p.proname,p.prosecdef,p.proconfig,
 has_function_privilege('authenticated',p.oid,'execute') authenticated_execute,
 has_function_privilege('anon',p.oid,'execute') anon_execute,
 has_function_privilege('service_role',p.oid,'execute') service_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in
 ('essay_exam_request_status','essay_exam_observation','essay_exam_question_result')
order by p.proname;
-- Existing incident facts only; no claim, retry, finish, dispatch or Credit call.
select id,state,completed_at from essay_exam_private.runs
where id in ('4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1','6ef28b49-12a5-4825-886d-548f0d9897df');
select key,state,payload->>'state' question_state
from essay_exam_private.checkpoints
where run_id='4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1' and key in ('q0','q1','q1-retry-9');
select transaction_type,count(*),sum(balance_delta),sum(reserved_delta)
from public.credit_transactions where decision_id='c66dc018-9d55-43e0-9a2c-604721e1d332'
group by transaction_type;
