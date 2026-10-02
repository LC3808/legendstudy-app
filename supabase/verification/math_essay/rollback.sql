begin;
set local lock_timeout='5s';
do $guard$declare actual jsonb; expected jsonb; t text; occupied boolean;begin
 expected=nullif(current_setting('math.rollback_credit_counts',true),'')::jsonb;
 select jsonb_build_array((select count(*) from public.credit_accounts),(select count(*) from public.credit_grants),(select count(*) from public.credit_transactions),(select count(*) from public.essay_billing_decisions)) into actual;
 if expected is null or expected<>actual then raise exception 'ROLLBACK_REFUSED: provide unchanged installation-time financial counts';end if;

if exists(select 1 from public.math_problem_sets) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_problems) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_subproblems) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_source_artifacts) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_evaluation_profiles) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_scoring_criteria) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_canonical_solutions) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_canonical_solution_steps) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_attempts) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_attempt_artifacts) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_extraction_runs) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_extraction_regions) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_evaluations) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_solution_steps) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_step_regions) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_step_dependencies) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_errors) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_error_propagations) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_core) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_hints) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_hint_exposures) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_considered_references) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_evaluated_paths) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_evaluation_sources) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_evaluation_criteria) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_solution_exposures) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.math_billing_bindings) then raise exception 'ROLLBACK_REFUSED: Math data exists';end if;
if exists(select 1 from public.human_quality_judgments where math_evaluation_id is not null) then raise exception 'ROLLBACK_REFUSED: Math quality data exists';end if;end $guard$;
drop trigger hq_domain_parent on public.human_quality_judgments;
drop trigger hq_domain_finding on public.human_quality_findings;
alter table public.human_quality_findings drop constraint hq_finding_union;
alter table public.human_quality_findings add constraint human_quality_findings_check check(essay_private.hq_finding_valid(jsonb_build_object('issue_category',issue_category,'severity',severity,'target_kind',target_kind,'target_ref',target_ref,'note',note)));
alter table public.human_quality_judgments drop constraint hq_domain_rubric,drop constraint hq_exact_domain;
alter table public.human_quality_judgments add constraint human_quality_judgments_rubric_version_check check(rubric_version='hq-rubric-v1');
alter table public.human_quality_judgments add constraint human_quality_judgments_rubric_result_check check(essay_private.hq_rubric_valid(rubric_result));
alter table public.human_quality_judgments alter column evaluation_id set not null;
alter table public.human_quality_judgments drop column math_evaluation_id;

create or replace function public.ql_submit_human_judgment(p_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid; eid uuid; key uuid; parent uuid; rw uuid; e public.essay_evaluations; old public.human_quality_judgments; jid uuid;
 v jsonb; f jsonb; t jsonb; h text; r jsonb; k text; cnt integer; sentence_exists boolean; progress_exists boolean;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 u=auth.uid();
 perform 1 from public.quality_operators where user_id=u for key share;
 if not found then raise exception 'not authorized' using errcode='42501';end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>32768
  or p_payload-array['dto_version','evaluation_id','expected_output_sha256','client_submission_id','rubric_version','overall_disposition','rubric_result','selection_reason','recommended_action','summary_note','supersedes_judgment_id','findings','official_source_reviewed']<>'{}'::jsonb
  or p_payload->>'dto_version' is distinct from 'hq-write-v1' or p_payload->'official_source_reviewed' is distinct from 'true'::jsonb then
  raise exception 'invalid payload or source review not confirmed' using errcode='22023';end if;
 foreach k in array array['evaluation_id','client_submission_id','expected_output_sha256','rubric_version','overall_disposition'] loop
  if jsonb_typeof(p_payload->k) is distinct from 'string' then raise exception 'missing field' using errcode='22023';end if;
 end loop;
 eid=(p_payload->>'evaluation_id')::uuid;key=(p_payload->>'client_submission_id')::uuid;parent=(p_payload->>'supersedes_judgment_id')::uuid;
 if p_payload ? 'supersedes_judgment_id' and jsonb_typeof(p_payload->'supersedes_judgment_id') not in ('string','null') then raise exception 'invalid predecessor' using errcode='22023';end if;
 if p_payload ? 'summary_note' and jsonb_typeof(p_payload->'summary_note') not in ('string','null') then raise exception 'invalid note' using errcode='22023';end if;
 foreach k in array array['selection_reason','recommended_action'] loop
  if p_payload ? k and jsonb_typeof(p_payload->k)<>'string' then raise exception 'invalid operational field' using errcode='22023';end if;
 end loop;
 if p_payload->>'rubric_version'<>'hq-rubric-v1' or not essay_private.hq_rubric_valid(p_payload->'rubric_result')
  or jsonb_typeof(p_payload->'findings') is distinct from 'array' then raise exception 'invalid rubric/findings' using errcode='22023';end if;
 if jsonb_array_length(p_payload->'findings')>20 or char_length(p_payload->>'summary_note')>2000 then raise exception 'payload bound' using errcode='22023';end if;
 v=p_payload||jsonb_build_object('evaluation_id',eid,'client_submission_id',key,'supersedes_judgment_id',parent,'summary_note',p_payload->>'summary_note','selection_reason',coalesce(p_payload->>'selection_reason','EARLY_CENSUS'),'recommended_action',coalesce(p_payload->>'recommended_action','NONE'));
 -- Transaction-scoped global key serialization; no request body stored in a second ledger.
 perform pg_advisory_xact_lock(hashtextextended(key::text,731));
 select * into old from public.human_quality_judgments where client_submission_id=key;
 if found then
  h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',old.reviewed_generated_rewrite_id))::text,'UTF8')),'hex');
  if old.reviewer_user_id is distinct from u or old.submission_payload_sha256<>h then raise exception 'submission key conflict' using errcode='23505';end if;
  return jsonb_build_object('dto_version','hq-write-v1','judgment_id',old.id,'replayed',true);
 end if;
 select * into e from public.essay_evaluations where id=eid for share;
 if not found then raise exception 'case not found' using errcode='P0002';end if;
 if e.status<>'completed' or e.contract_version<>'1.3' or e.output_sha256 is null
  or e.output_sha256 is distinct from p_payload->>'expected_output_sha256'
  or exists(select 1 from public.essay_improvement_progress where evaluation_id=eid and scaffolding_observation is null)
  or jsonb_typeof(e.input_snapshot->'evidence') is distinct from 'array'
  or jsonb_typeof(e.input_snapshot->'criteria') is distinct from 'array' then raise exception 'unassessable or stale subject' using errcode='22023';end if;
 if jsonb_array_length(e.input_snapshot->'evidence')=0 or jsonb_array_length(e.input_snapshot->'criteria')=0 then raise exception 'missing frozen evidence' using errcode='22023';end if;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and jsonb_array_length(p.scaffolding_observation->'sentences')>0) into sentence_exists;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and p.previous_progress_id is not null)
   or e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null into progress_exists;
 -- Context points to erased history: do not treat missing predecessor as absent history.
 if e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null and not exists
  (select 1 from public.essay_evaluations where id=(e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id')::uuid) then raise exception 'prior source unavailable' using errcode='22023';end if;
 select id into rw from public.essay_generated_rewrites where evaluation_id=eid and status='completed' for share;
 r=p_payload->'rubric_result';
 if ((r->>'sentence_feedback'='NA')=sentence_exists) or ((r->>'progression'='NA')=progress_exists)
  or ((r->>'generated_rewrite'='NA')=(rw is not null)) then raise exception 'invalid conditional NA' using errcode='22023';end if;
 if parent is not null then
  perform 1 from public.human_quality_judgments where id=parent and evaluation_id=eid for update;
  if not found or exists(select 1 from public.human_quality_judgments where supersedes_judgment_id=parent) then raise exception 'invalid correction head' using errcode='23514';end if;
 end if;
 for f in select value from jsonb_array_elements(p_payload->'findings') loop
  if not essay_private.hq_finding_valid(f) then raise exception 'invalid finding shape' using errcode='22023';end if;
  if p_payload->>'overall_disposition'='PASS' or (p_payload->>'overall_disposition'='PASS_WITH_NOTES' and f->>'severity'<>'MINOR') then raise exception 'finding/disposition conflict' using errcode='23514';end if;
  t=f->'target_ref';cnt=0;
  case f->>'target_kind'
   when 'OVERALL' then cnt=1;
   when 'DIMENSION' then select count(*) into cnt from public.essay_evaluation_dimensions where evaluation_id=eid and id=(t->>'dimension_id')::uuid;
   when 'PROGRESS' then select count(*) into cnt from public.essay_improvement_progress where evaluation_id=eid and id=(t->>'progress_id')::uuid;
   when 'ISSUE_KEY' then select count(*) into cnt from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id where p.evaluation_id=eid and i.issue_key=t->>'issue_key';
   when 'SENTENCE' then select count(*) into cnt from public.essay_improvement_progress p cross join lateral jsonb_array_elements(p.scaffolding_observation->'sentences') s where p.evaluation_id=eid and p.id=(t->>'progress_id')::uuid and s->>'observation_key'=t->>'observation_key';
   when 'EVIDENCE_LINK' then select count(*) into cnt from public.essay_evaluation_evidence where evaluation_id=eid and evidence_id=(t->>'evidence_id')::uuid and dimension_id is not distinct from (t->>'dimension_id')::uuid and improvement_progress_id is not distinct from (t->>'progress_id')::uuid;
   when 'GENERATED_REWRITE' then cnt=case when rw is not null then 1 else 0 end;
   else null;
  end case;
  if cnt<>1 then raise exception 'finding target not on subject' using errcode='22023';end if;
 end loop;
 h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',rw))::text,'UTF8')),'hex');
 insert into public.human_quality_judgments(evaluation_id,reviewed_output_sha256,reviewed_generated_rewrite_id,reviewer_user_id,rubric_version,overall_disposition,rubric_result,selection_reason,recommended_action,summary_note,supersedes_judgment_id,client_submission_id,submission_payload_sha256)
 values(eid,e.output_sha256,rw,u,v->>'rubric_version',v->>'overall_disposition',r,v->>'selection_reason',v->>'recommended_action',v->>'summary_note',parent,key,h) returning id into jid;
 insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref,note)
 select jid,value->>'issue_category',value->>'severity',value->>'target_kind',value->'target_ref',value->>'note' from jsonb_array_elements(v->'findings');
 return jsonb_build_object('dto_version','hq-write-v1','judgment_id',jid,'replayed',false);
end$$;
create or replace function public.ql_list_human_judgments(p_evaluation_id uuid,p_limit integer default 20,p_before timestamptz default null,p_before_id uuid default null) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare n int:=least(100,greatest(1,coalesce(p_limit,20))); v jsonb;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 if (p_before is null)<>(p_before_id is null) then raise exception 'paired cursor required' using errcode='22023';end if;
 if not exists(select 1 from public.essay_evaluations where id=p_evaluation_id) then raise exception 'case not found' using errcode='P0002';end if;
 with page as materialized(select * from public.human_quality_judgments where evaluation_id=p_evaluation_id and (p_before is null or (created_at,id)<(p_before,p_before_id)) order by created_at desc,id desc limit n+1),
 shown as materialized(select * from page order by created_at desc,id desc limit n)
 select jsonb_build_object('dto_version','hq-read-v1','judgments',coalesce((select jsonb_agg(
  (to_jsonb(j)-array['submission_payload_sha256','client_submission_id'])||jsonb_build_object('reviewer_state',case when j.reviewer_user_id is null then 'DELETED_OR_UNAVAILABLE' else 'AVAILABLE' end,
   'is_active',not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id),
   'findings',coalesce((select jsonb_agg(to_jsonb(f)-'judgment_id' order by f.id) from public.human_quality_findings f where f.judgment_id=j.id),'[]'::jsonb)) order by j.created_at desc,j.id desc) from shown j),'[]'::jsonb),
  'next_cursor',case when (select count(*) from page)>n then (select jsonb_build_object('created_at',created_at,'judgment_id',id) from shown order by created_at,id limit 1) else null end) into v;
 return v;
end$$;
alter table public.math_attempts drop constraint math_attempts_prior_evaluation_id_predecessor_id_fkey,drop constraint math_attempts_target_step_id_prior_evaluation_id_fkey;
drop table public.math_billing_bindings;
drop table public.math_solution_exposures;
drop table public.math_evaluation_criteria;
drop table public.math_evaluation_sources;
drop table public.math_evaluated_paths;
drop table public.math_considered_references;
drop table public.math_hint_exposures;
drop table public.math_hints;
drop table public.math_core;
drop table public.math_error_propagations;
drop table public.math_errors;
drop table public.math_step_dependencies;
drop table public.math_step_regions;
drop table public.math_solution_steps;
drop table public.math_evaluations;
drop table public.math_extraction_regions;
drop table public.math_extraction_runs;
drop table public.math_attempt_artifacts;
drop table public.math_attempts;
drop table public.math_canonical_solution_steps;
drop table public.math_canonical_solutions;
drop table public.math_scoring_criteria;
drop table public.math_evaluation_profiles;
drop table public.math_source_artifacts;
drop table public.math_subproblems;
drop table public.math_problems;
drop table public.math_problem_sets;
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;set role math_executor;
drop function math_private.validate_output(uuid,jsonb);
drop function math_private.evaluation_projection(uuid,boolean);
drop function math_private.lock_evaluation(uuid);
drop function math_private.resolve_profile(uuid);
drop function public.math_fail_evaluation(uuid,uuid,text);
drop function public.math_finalize_evaluation(uuid,uuid,jsonb);
drop function public.math_claim_evaluation(uuid);
drop function public.math_fail_extraction(uuid,uuid,text);
drop function public.math_finalize_extraction(uuid,uuid,jsonb);
drop function public.math_claim_extraction(uuid);
drop function public.math_reveal_hint(uuid,uuid);
drop function public.math_evaluation_detail(uuid);
drop function public.math_attempt_detail(uuid);
drop function public.math_request_evaluation(uuid,uuid);
drop function public.math_confirm_extraction(uuid,uuid,jsonb);
drop function public.math_register_artifact(uuid,jsonb);
drop function public.math_submit_attempt(jsonb);
reset role;revoke math_executor from postgres granted by postgres;
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;set role essay_executor;
drop function math_private.lock_account_attempt(uuid);
drop function math_private.release_billing(uuid);
drop function math_private.settle_billing(uuid);
drop function math_private.authorize_billing(uuid);
reset role;revoke essay_executor from postgres granted by postgres;
drop function public.qlm_case_detail(uuid);
drop function public.qlm_list_cases(integer,timestamp with time zone,uuid);
drop function public.qlm_list_human_judgments(uuid,integer,timestamp with time zone,uuid);
drop function public.qlm_review_state(uuid[]);
drop function public.qlm_submit_human_judgment(jsonb);
drop function math_private.hq_require_operator(uuid);
drop function math_private.hq_validate_context(uuid,jsonb,jsonb);
drop function math_private.hq_finding_valid(jsonb);
drop function math_private.hq_rubric_valid(jsonb);
drop function math_private.hq_finding_guard();
drop function math_private.hq_parent_guard();
drop function math_private.activate_profile(uuid);
drop function math_private.binding_guard();
drop function math_private.artifact_guard();
drop function math_private.personal_immutable();
drop function math_private.content_immutable();
drop function math_private.require_active(uuid[]);
drop function math_private.current_subject();
drop schema math_private;
revoke usage on schema public from math_executor;drop role math_executor;
revoke usage on schema public from math_extraction_worker;drop role math_extraction_worker;
revoke usage on schema public from math_evaluation_worker;drop role math_evaluation_worker;
commit;
