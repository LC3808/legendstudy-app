begin read only;
do $empty$begin
 if exists(select 1 from public.math_problem_sets) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_problems) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_subproblems) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_source_artifacts) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_evaluation_profiles) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_scoring_criteria) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_canonical_solutions) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_canonical_solution_steps) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_attempts) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_attempt_artifacts) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_extraction_runs) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_extraction_regions) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_evaluations) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_solution_steps) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_step_regions) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_step_dependencies) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_errors) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_error_propagations) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_core) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_hints) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_hint_exposures) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_considered_references) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_evaluated_paths) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_evaluation_sources) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_evaluation_criteria) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_solution_exposures) then raise exception 'Unexpected new Math rows after installation';end if;
 if exists(select 1 from public.math_billing_bindings) then raise exception 'Unexpected new Math rows after installation';end if;
end $empty$;

with checks as (with expected(signature,owner_name,definer,executors) as(values
('public.math_submit_attempt(jsonb)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_register_artifact(uuid,jsonb)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_confirm_extraction(uuid,uuid,jsonb)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_request_evaluation(uuid,uuid)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_attempt_detail(uuid)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_evaluation_detail(uuid)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_reveal_hint(uuid,uuid)','math_executor',true,array['authenticated','math_executor']::text[]),
('public.math_claim_extraction(uuid)','math_executor',true,array['math_executor','math_extraction_worker']::text[]),
('public.math_finalize_extraction(uuid,uuid,jsonb)','math_executor',true,array['math_executor','math_extraction_worker']::text[]),
('public.math_fail_extraction(uuid,uuid,text)','math_executor',true,array['math_executor','math_extraction_worker']::text[]),
('public.math_claim_evaluation(uuid)','math_executor',true,array['math_evaluation_worker','math_executor']::text[]),
('public.math_finalize_evaluation(uuid,uuid,jsonb)','math_executor',true,array['math_evaluation_worker','math_executor']::text[]),
('public.math_fail_evaluation(uuid,uuid,text)','math_executor',true,array['math_evaluation_worker','math_executor']::text[]),
('math_private.resolve_profile(uuid)','math_executor',true,array['math_executor']::text[]),
('math_private.lock_evaluation(uuid)','math_executor',true,array['math_executor']::text[]),
('math_private.evaluation_projection(uuid,boolean)','math_executor',true,array['math_executor','postgres']::text[]),
('math_private.validate_output(uuid,jsonb)','math_executor',true,array['math_executor']::text[]),
('math_private.authorize_billing(uuid)','essay_executor',true,array['essay_executor','math_executor']::text[]),
('math_private.settle_billing(uuid)','essay_executor',true,array['essay_executor','math_executor']::text[]),
('math_private.release_billing(uuid)','essay_executor',true,array['essay_executor','math_executor']::text[]),
('math_private.current_subject()','postgres',true,array['math_executor','postgres']::text[]),
('math_private.require_active(uuid[])','postgres',true,array['essay_executor','math_executor','postgres']::text[]),
('math_private.content_immutable()','postgres',false,array['postgres']::text[]),
('math_private.personal_immutable()','postgres',false,array['postgres']::text[]),
('math_private.artifact_guard()','postgres',true,array['postgres']::text[]),
('math_private.binding_guard()','postgres',true,array['postgres']::text[]),
('math_private.activate_profile(uuid)','postgres',true,array['postgres']::text[]),
('math_private.hq_parent_guard()','postgres',true,array['postgres']::text[]),
('math_private.hq_finding_guard()','postgres',true,array['postgres']::text[]),
('math_private.hq_rubric_valid(jsonb)','postgres',false,array['postgres']::text[]),
('math_private.hq_finding_valid(jsonb)','postgres',false,array['postgres']::text[]),
('math_private.hq_validate_context(uuid,jsonb,jsonb)','postgres',true,array['postgres']::text[]),
('math_private.hq_require_operator(uuid)','postgres',true,array['postgres']::text[]),
('public.qlm_submit_human_judgment(jsonb)','postgres',true,array['authenticated','postgres']::text[]),
('public.qlm_review_state(uuid[])','postgres',true,array['authenticated','postgres']::text[]),
('public.qlm_list_human_judgments(uuid,integer,timestamp with time zone,uuid)','postgres',true,array['authenticated','postgres']::text[]),
('public.qlm_list_cases(integer,timestamp with time zone,uuid)','postgres',true,array['authenticated','postgres']::text[]),
('public.qlm_case_detail(uuid)','postgres',true,array['authenticated','postgres']::text[]),
('public.ql_submit_human_judgment(jsonb)','postgres',true,array['authenticated','postgres']::text[]),
('public.ql_list_human_judgments(uuid,integer,timestamp with time zone,uuid)','postgres',true,array['authenticated','postgres']::text[]),
('math_private.lock_account_attempt(uuid)','essay_executor',true,array['essay_executor','math_executor']::text[])
)
select e.signature,pg_get_userbyid(p.proowner)=e.owner_name as owner_ok,
 p.prosecdef=e.definer as mode_ok,p.proconfig=array['search_path=""'] as search_path_ok,
 array(select pg_get_userbyid(a.grantee)::text from aclexplode(p.proacl) a where a.privilege_type='EXECUTE' order by 1)=e.executors as exact_execute_ok
from expected e left join pg_proc p on p.oid=to_regprocedure(e.signature) order by e.signature) select jsonb_build_object(
'function_checks',(select jsonb_agg(to_jsonb(c)) from checks c),
'memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'grantor',pg_get_userbyid(grantor),'admin',admin_option,'inherit',inherit_option,'set',set_option)) from pg_auth_members where roleid in(select oid from pg_roles where rolname like 'math_%' or rolname='essay_executor')),
'roles',(select jsonb_agg(jsonb_build_object('name',rolname,'login',rolcanlogin,'super',rolsuper,'bypass',rolbypassrls,'inherit',rolinherit,'createdb',rolcreatedb,'createrole',rolcreaterole,'replication',rolreplication)) from pg_roles where rolname like 'math_%'),
'math_tables',(select jsonb_agg(jsonb_build_object('table',relname,'owner',pg_get_userbyid(relowner),'rls',relrowsecurity,'acl',relacl::text,'no_client_privilege',not exists(select 1 from aclexplode(relacl) a where a.grantee in(0,'anon'::regrole,'authenticated'::regrole,'service_role'::regrole)))) from pg_class where relnamespace='public'::regnamespace and relkind='r' and relname like 'math_%'),
'no_temporary_create',not has_schema_privilege('math_executor','public','CREATE') and not has_schema_privilege('math_executor','math_private','CREATE') and not has_schema_privilege('essay_executor','math_private','CREATE'),
'schemas',(select jsonb_agg(jsonb_build_object('name',nspname,'owner',pg_get_userbyid(nspowner),'acl',nspacl::text)) from pg_namespace where nspname in('public','essay_private','math_private'))
) as postflight;commit;
