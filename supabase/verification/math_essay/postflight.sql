-- Owner post-install catalog/security verification. No mutations.
begin read only;
select version,name from supabase_migrations.schema_migrations order by version desc limit 8;
-- SQL install and migration tracking are separate: expect this exact version only after Owner tracking.
select exists(select 1 from supabase_migrations.schema_migrations where version='20261002000100') as math_tracked,
 exists(select 1 from supabase_migrations.schema_migrations where version='20261001000300') as adr2_tracked,
 exists(select 1 from supabase_migrations.schema_migrations where version='20260929000500') as provider005_tracked,
 exists(select 1 from supabase_migrations.schema_migrations where version='20260930000100') as day_targets_tracked;
with expected(signature,owner_name,definer,executors) as(values
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
from expected e left join pg_proc p on p.oid=to_regprocedure(e.signature) order by e.signature;
select c.relname,pg_get_userbyid(c.relowner) as owner,c.relrowsecurity,c.relacl::text,
 not exists(select 1 from aclexplode(c.relacl) a where a.grantee in (0,'anon'::regrole,'authenticated'::regrole,'service_role'::regrole)) as no_client_privilege
from pg_class c where c.relnamespace='public'::regnamespace and c.relkind='r' and c.relname like 'math_%' order by 1;
select * from pg_policies where schemaname='public' and tablename like 'math_%' order by tablename,policyname;
select pg_get_userbyid(roleid) as role,pg_get_userbyid(member) as member,pg_get_userbyid(grantor) as grantor,admin_option,inherit_option,set_option
from pg_auth_members where roleid in ('math_executor'::regrole,'math_extraction_worker'::regrole,'math_evaluation_worker'::regrole,'essay_executor'::regrole) order by 1,2,3;
select rolname,rolcanlogin,rolbypassrls,rolsuper,rolcreatedb,rolcreaterole,rolreplication,rolinherit
from pg_roles where rolname in ('math_executor','math_extraction_worker','math_evaluation_worker');
select not has_schema_privilege('math_executor','public','CREATE') and not has_schema_privilege('math_executor','math_private','CREATE') and not has_schema_privilege('essay_executor','math_private','CREATE') as no_temporary_create;
select conrelid::regclass::text as relation,conname,pg_get_constraintdef(oid) from pg_constraint
where conrelid in ('public.human_quality_judgments'::regclass,'public.human_quality_findings'::regclass,'public.math_billing_bindings'::regclass,'public.math_attempts'::regclass) order by 1,2;
select indexname,indexdef from pg_indexes where schemaname='public' and (tablename like 'math_%' or indexname='human_quality_math_history') order by indexname;
-- New tables must be empty immediately after schema installation (no fixture creation).
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
commit;
