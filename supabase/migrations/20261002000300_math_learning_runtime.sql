-- MATH-2E: learning delivery/resolve surface, NOT Production activation.
begin;
do $$begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user) then raise exception 'NON_SUPERUSER_POSTGRES_REQUIRED';end if;
 if to_regprocedure('public.math_input(jsonb)') is null then raise exception 'MATH_2D_REQUIRED';end if;
 if has_schema_privilege('math_executor','math_private','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'UNEXPECTED_TOPOLOGY';end if;
end$$;
-- Explicit typed generated-reference binding, no copied answer or detached hash.
alter table public.math_evaluations add constraint math_evaluation_output_identity unique(id,output_sha256);
alter table public.math_solution_exposures alter column solution_id drop not null;
alter table public.math_solution_exposures add column generated_output_sha256 text;
alter table public.math_solution_exposures add constraint math_solution_exposure_one_binding check(num_nonnulls(solution_id,generated_output_sha256)=1);
alter table public.math_solution_exposures add constraint math_solution_generated_output_fk foreign key(evaluation_id,generated_output_sha256) references public.math_evaluations(id,output_sha256) on delete cascade;
create index math_hint_delivery_history on public.math_hint_exposures(hint_id,delivered_at,id);
create index math_solution_delivery_history on public.math_solution_exposures(evaluation_id,delivered_at,id);

grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema math_private to math_executor;
set role math_executor;
create or replace function math_private.validate_output(uuid,jsonb) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; p public.math_evaluation_profiles; a public.math_attempts; v jsonb; k text; ids uuid[]; required text[]:=array['contract_version','extraction_id','steps','edges','errors','causes','core','hints','references','paths','criteria','rubric','overall','provenance','progression','generated_solution'];
begin
 select * into e from public.math_evaluations where id=$1; select * into p from public.math_evaluation_profiles where id=e.profile_id;select * into a from public.math_attempts where id=e.attempt_id;
 if $2 is null or jsonb_typeof($2)<>'object' or octet_length($2::text)>524288 or $2-required<>'{}' or not $2 ?& required or $2->>'contract_version' is distinct from 'math-eval-v1' or ($2->>'extraction_id')::uuid is distinct from e.selected_extraction_id then raise invalid_parameter_value using message='INVALID_OUTPUT_ENVELOPE';end if;
 foreach k in array array['steps','edges','errors','causes','core','hints','references','paths','criteria'] loop
  if jsonb_typeof($2->k)<>'array' or jsonb_array_length($2->k)>100 then raise invalid_parameter_value;end if;
 end loop;
 if jsonb_typeof($2->'rubric')<>'object' or ($2->'rubric')-(p.required_dimensions||p.optional_dimensions)<>'{}' or not ($2->'rubric' ?& p.required_dimensions) then raise invalid_parameter_value using message='RUBRIC_SHAPE';end if;
 for k,v in select * from jsonb_each($2->'rubric') loop
  if jsonb_typeof(v)<>'string' or v#>>'{}' not in ('STRONG','ADEQUATE','NEEDS_IMPROVEMENT','INSUFFICIENT','NOT_APPLICABLE','NOT_ASSESSABLE') or (k=any(p.required_dimensions) and v#>>'{}'='NOT_APPLICABLE') then raise invalid_parameter_value;end if;
 end loop;
 if p.reasoning_required and $2->'overall'->>'coverage'='ATTEMPTED' and jsonb_array_length($2->'steps')=0 then raise invalid_parameter_value using message='REASONING_REQUIRED';end if;
 if jsonb_typeof($2->'overall')<>'object' or ($2->'overall')-array['status','explanation','answer_status','coverage','review_status']<>'{}' or ($2->'overall')->>'status' not in ('ANSWER_CORRECT_AND_REASONING_SUFFICIENT','ANSWER_CORRECT_REASONING_INCOMPLETE','ANSWER_INCORRECT_APPROACH_MOSTLY_VALID','FUNDAMENTAL_APPROACH_ERROR','NOT_DETERMINABLE') or length(($2->'overall')->>'explanation') not between 1 and 10000 then raise invalid_parameter_value;end if;
 foreach k in array array['status','explanation','answer_status','coverage'] loop if jsonb_typeof($2->'overall'->k) is distinct from 'string' then raise invalid_parameter_value;end if;end loop;
 if jsonb_typeof($2->'provenance')<>'object' or ($2->'provenance')-array['provider','model','model_version','prompt_version']<>'{}' then raise invalid_parameter_value;end if;
 foreach k in array array['provider','model','model_version','prompt_version'] loop if jsonb_typeof(($2->'provenance')->k) is distinct from 'string' or length(($2->'provenance')->>k) not between 1 and 200 then raise invalid_parameter_value;end if;end loop;
 if a.kind='INITIAL' and $2->'progression'<>'null' then raise invalid_parameter_value;end if;
 if a.kind<>'INITIAL' and (jsonb_typeof($2->'progression')<>'object' or ($2->'progression')-array['prior_evaluation_id','target_step_id','downstream','summary','delta']<>'{}' or (($2->'progression')->>'prior_evaluation_id')::uuid is distinct from a.prior_evaluation_id or (($2->'progression')->>'target_step_id')::uuid is distinct from a.target_step_id or (a.kind='STEP_RETRY' and ($2->'progression')->>'downstream' is distinct from 'NOT_REASSESSED')) then raise invalid_parameter_value using message='INVALID_PROGRESSION';end if;
 if $2->'generated_solution'<>'null' and (jsonb_typeof($2->'generated_solution')<>'object' or ($2->'generated_solution')-array['body','origin']<>'{}' or ($2->'generated_solution')->>'origin' is distinct from 'AI_GENERATED' or length(($2->'generated_solution')->>'body') not between 1 and 20000) then raise invalid_parameter_value;end if;
 for v in select value from jsonb_array_elements($2->'steps') loop
  if v-array['id','position','kind','representation','status','explanation','regions']<>'{}' or not v ?& array['id','position','kind','representation','status','explanation','regions'] or jsonb_typeof(v->'regions')<>'array' or jsonb_array_length(v->'regions')>100 then raise invalid_parameter_value;end if;
 end loop;
 for v in select value from jsonb_array_elements($2->'edges') loop if v-array['from','to']<>'{}' or not v ?& array['from','to'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'errors') loop
  if v-array['id','step_id','classification','category','materiality','explanation']<>'{}' or not v ?& array['id','step_id','classification','category','materiality','explanation'] or v->>'category' not in ('CONDITION_MISREAD','CONCEPT_SELECTION','STRATEGY','LOGICAL_GAP','CALCULATION','SIGN','ALGEBRAIC_TRANSFORMATION','CASE_OMISSION','DOMAIN_RANGE','THEOREM_MISUSE','GRAPH_INTERPRETATION','JUSTIFICATION','CONCLUSION','OTHER') then raise invalid_parameter_value;end if;
 end loop;
 for v in select value from jsonb_array_elements($2->'causes') loop if v-array['root','consequence']<>'{}' or not v ?& array['root','consequence'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'core') loop if v-array['id','position','error_id','step_id','title','diagnosis','why','next_action']<>'{}' or not v ?& array['id','position','error_id','step_id','title','diagnosis','why','next_action'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'hints') loop if v-array['id','core_id','level','body','leakage_class','validated']<>'{}' or not v ?& array['id','core_id','level','body','leakage_class','validated'] or v->'validated' is distinct from 'true'::jsonb or ((v->>'level')::integer=1 and v->>'leakage_class'<>'SAFE_DIRECTION') or ((v->>'level')::integer=2 and v->>'leakage_class'<>'CONCEPT_REVEAL') then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'paths') loop if v-array['key','verdict','explanation']<>'{}' or not v ?& array['key','verdict','explanation'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'criteria') loop if v-array['criterion_id','verdict','explanation']<>'{}' or not v ?& array['criterion_id','verdict','explanation'] or jsonb_typeof(v->'verdict') is distinct from 'string' or jsonb_typeof(v->'explanation') is distinct from 'string' or v->>'verdict' not in ('satisfied','partially_satisfied','not_satisfied','not_determinable') or length(v->>'explanation')>5000 then raise invalid_parameter_value;end if;end loop;

 if ($2->'overall') ? 'review_status' and (jsonb_typeof($2->'overall'->'review_status') is distinct from 'string' or $2->'overall'->>'review_status' not in ('NOT_REQUIRED','HUMAN_REVIEW_REQUIRED')) then raise invalid_parameter_value using message='INVALID_REVIEW_STATUS';end if;
 if ($2->'progression') ? 'delta' then
  if jsonb_typeof($2->'progression'->'delta') is distinct from 'array' or jsonb_array_length($2->'progression'->'delta')>20 then raise invalid_parameter_value;end if;
  for v in select value from jsonb_array_elements($2->'progression'->'delta') loop
   if jsonb_typeof(v)<>'object' or v-array['kind','prior_error_id','current_error_id','explanation']<>'{}' or not v ?& array['kind','explanation'] or jsonb_typeof(v->'explanation') is distinct from 'string' or length(v->>'explanation') not between 1 and 2000 or jsonb_typeof(v->'kind') is distinct from 'string' or v->>'kind' not in ('CORE_CORRECTED','ROOT_ERROR_REMOVED','ROOT_ERROR_REMAINS','PROPAGATED_ERROR_REMOVED','NEW_INDEPENDENT_ERROR','ANSWER_CHANGED','ANSWER_NOW_CORRECT','JUSTIFICATION_IMPROVED','NO_MATERIAL_CHANGE','PATH_VALIDITY_CHANGED') then raise invalid_parameter_value using message='INVALID_DELTA';end if;
   if v->>'prior_error_id' is not null and not exists(select 1 from public.math_errors where id=(v->>'prior_error_id')::uuid and evaluation_id=a.prior_evaluation_id) then raise invalid_parameter_value;end if;
   if v->>'current_error_id' is not null and not exists(select 1 from jsonb_array_elements($2->'errors') x where x->>'id'=v->>'current_error_id') then raise invalid_parameter_value;end if;
  end loop;
 end if;
end$math_fn$;
reset role;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;
create function math_private.learning_eligibility(p_evaluation_id uuid,p_at timestamptz) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare initial public.math_evaluations; decision public.essay_billing_decisions; lineage uuid; student uuid; eligibility_status text; expires timestamptz;
begin
 select a.lineage_id,a.student_id into lineage,student from public.math_attempts a join public.math_evaluations e on e.attempt_id=a.id where e.id=p_evaluation_id;
 select e.* into initial from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where a.lineage_id=lineage and a.student_id=student and e.request_kind='MATH_INITIAL_EVALUATION' and e.state='COMPLETED' order by e.completed_at desc,e.id desc limit 1;
 select d.* into decision from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=initial.id;
 expires=initial.completed_at+interval '336 hours';
 eligibility_status=case when initial.id is null or decision.id is null or decision.status<>'settled' or decision.reason<>'paid_cycle' or decision.policy_key<>'essay_cycle' or decision.policy_version<>'v2' or exists(select 1 from public.credit_transactions where decision_id=decision.id and transaction_type='refund') then 'UNAVAILABLE'
 when exists(select 1 from public.essay_billing_decisions where included_by_decision_id=decision.id and status='settled') then 'CONSUMED'
 when exists(select 1 from public.essay_billing_decisions where included_by_decision_id=decision.id and status in ('authorized','reserved')) then 'AUTHORIZED_PENDING'
 when p_at>=expires then 'EXPIRED' else 'AVAILABLE' end;
 return jsonb_build_object('status',eligibility_status,'eligible',eligibility_status='AVAILABLE','included_count',1,'initial_evaluation_id',initial.id,'expires_at',expires,'as_of',p_at,'request_route',case when eligibility_status='AVAILABLE' then 'math_learning.request_reevaluation' else 'math_input.request_evaluation' end);
end$$;
revoke all on function math_private.learning_eligibility(uuid,timestamptz) from public,anon,authenticated,service_role;

create function math_private.learning_state(p_evaluation_id uuid) returns jsonb
language plpgsql volatile security invoker set search_path='' as $$
declare e public.math_evaluations;a public.math_attempts;response text;u uuid;refs jsonb;hints jsonb;cores jsonb;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 select er.* into e from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=p_evaluation_id and ar.student_id=u;
 if not found then raise no_data_found;end if;
 select * into a from public.math_attempts where id=e.attempt_id;
 select response_format into response from public.math_subproblems where id=e.leaf_id;
 select coalesce(jsonb_agg(jsonb_build_object('core_id',id,'position',position,'error_id',error_id,'step_id',step_id,'title',title,'diagnosis',diagnosis,'why',why,'next_action',next_action) order by position),'[]') into cores from public.math_core where evaluation_id=e.id;
 select coalesce(jsonb_agg(jsonb_build_object('hint_id',h.id,'core_id',h.core_id,'level',h.level,'available',h.validated and e.state='COMPLETED','revealed',exists(select 1 from public.math_hint_exposures where hint_id=h.id),'can_reveal',h.validated and e.state='COMPLETED' and (h.level<2 or exists(select 1 from public.math_hint_exposures x join public.math_hints prior on prior.id=x.hint_id where prior.core_id=h.core_id and prior.level=1))) order by h.core_id,h.level),'[]') into hints from public.math_hints h where h.evaluation_id=e.id;
 select coalesce(jsonb_agg(jsonb_build_object('solution_id',s.id,'target','REFERENCE','provenance',case s.origin when 'OFFICIAL' then 'OFFICIAL_SOLUTION' when 'VERIFIED_INTERNAL' then 'VERIFIED_INTERNAL_SOLUTION' else 'AI_GENERATED_REFERENCE' end,'physical_origin',s.origin,'reveal_state',case when e.state='COMPLETED' then 'AVAILABLE_ON_EXPLICIT_REQUEST' else 'UNAVAILABLE' end,'revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=e.id and solution_id=s.id)) order by s.id),'[]') into refs from public.math_considered_references x join public.math_canonical_solutions s on s.id=x.solution_id where x.evaluation_id=e.id;
 if e.result->'generated_solution'<>'null' then refs=refs||jsonb_build_array(jsonb_build_object('solution_id',null,'target','GENERATED','provenance','AI_GENERATED_REFERENCE','physical_origin','AI_GENERATED','reveal_state',case when e.state='COMPLETED' then 'AVAILABLE_ON_EXPLICIT_REQUEST' else 'UNAVAILABLE' end,'revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=e.id and generated_output_sha256=e.output_sha256)));end if;
 return jsonb_build_object('evaluation_id',e.id,'attempt_id',a.id,'lineage_id',a.lineage_id,'leaf_id',a.leaf_id,'problem_id',(select problem_id from public.math_subproblems where id=a.leaf_id),'response_format',response,'resolve_kind',a.kind,'prior_attempt_id',a.predecessor_id,'prior_evaluation_id',a.prior_evaluation_id,'target_step_id',a.target_step_id,'submitted_scope',case when a.kind='STEP_RETRY' then 'TARGET_STEP' else 'WHOLE_LEAF' end,'downstream',case when a.kind='STEP_RETRY' then 'NOT_REASSESSED' else null end,
 'evaluation_state',e.state,'completed_at',e.completed_at,'valid_evaluation_available',e.state in ('COMPLETED','INVALIDATED'),'review_status',coalesce(e.result->'overall'->>'review_status','NOT_RECORDED'),
 'core',cores,'hints',hints,'hint_availability',case when jsonb_array_length(cores)=0 then 'NOT_APPLICABLE' when jsonb_array_length(hints)=0 then 'UNAVAILABLE' else 'FROM_FROZEN_HINTS' end,'solutions',refs,
 'resolve_kinds',case when e.state<>'COMPLETED' then '[]'::jsonb when response='SHORT_ANSWER' then '["SHORT_ANSWER_RESOLVE","FULL_RESOLVE"]'::jsonb else '["FULL_RESOLVE"]'::jsonb end || case when e.state='COMPLETED' and exists(select 1 from public.math_solution_steps where evaluation_id=e.id) then '["STEP_RETRY"]'::jsonb else '[]'::jsonb end,
 'included_reevaluation',math_private.learning_eligibility(e.id,clock_timestamp()),'reevaluation_delta',e.result->'progression',
 'reference_solution_revealed_before_resolve',exists(select 1 from public.math_solution_exposures where evaluation_id=a.prior_evaluation_id and delivered_at<=a.created_at),
 'hint_levels_before_resolve',(select coalesce(jsonb_agg(distinct h.level),'[]') from public.math_hint_exposures x join public.math_hints h on h.id=x.hint_id where h.evaluation_id=a.prior_evaluation_id and x.delivered_at<=a.created_at));
end$$;
revoke all on function math_private.learning_state(uuid) from public,anon,authenticated,service_role;

create function public.math_learning(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload';action text=p_request->>'action';u uuid;allowed text[];e public.math_evaluations;a public.math_attempts;h public.math_hints;s public.math_canonical_solutions;exposure public.math_solution_exposures;
 answer jsonb;key uuid;target text;sid uuid;gh text;newid uuid;lim integer;before_at timestamptz;before_id uuid;page jsonb;item record;last_at timestamptz;last_id uuid;basis uuid;decision public.essay_billing_decisions;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>70000 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'math-learning-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value using message='INVALID_LEARNING_CONTRACT';end if;
 allowed=case action when 'read_learning_state' then array['evaluation_id'] when 'reveal_hint' then array['evaluation_id','hint_id','level','client_submission_id'] when 'reveal_solution' then array['evaluation_id','target','solution_id','client_submission_id'] when 'create_resolve_attempt' then array['client_submission_id','leaf_id','kind','predecessor_id','prior_evaluation_id','target_step_id','typed_answer','input_kind'] when 'request_reevaluation' then array['attempt_id','client_submission_id'] when 'read_learning_history' then array['evaluation_id','limit','before_at','before_id'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 if action in ('read_learning_state','read_learning_history','reveal_hint','reveal_solution') then
  select er.* into e from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=(v->>'evaluation_id')::uuid and ar.student_id=u;
  if not found then raise no_data_found;end if;select * into a from public.math_attempts where id=e.attempt_id;
 end if;
 case action
 when 'read_learning_state' then answer=math_private.learning_state(e.id);
 when 'reveal_hint' then
  if jsonb_typeof(v->'level') is distinct from 'number' or v->>'level' not in ('0','1','2') then raise invalid_parameter_value;end if;
  select * into h from public.math_hints where id=(v->>'hint_id')::uuid and evaluation_id=e.id and level=(v->>'level')::integer and validated;
  if not found then raise invalid_parameter_value using message='HINT_UNAVAILABLE';end if;
  answer=public.math_reveal_hint(h.id,(v->>'client_submission_id')::uuid);
 when 'reveal_solution' then
  if e.state<>'COMPLETED' then raise invalid_parameter_value;end if;
  key=(v->>'client_submission_id')::uuid;target=v->>'target';sid=(v->>'solution_id')::uuid;
  if key is null or target is null or target not in ('REFERENCE','GENERATED') then raise invalid_parameter_value;end if;
  if target='REFERENCE' then
   select sr.* into s from public.math_canonical_solutions sr join public.math_considered_references cr on cr.solution_id=sr.id where cr.evaluation_id=e.id and sr.id=sid;
   if not found then raise invalid_parameter_value using message='SOLUTION_UNAVAILABLE';end if;
  else
   if sid is not null or e.result->'generated_solution' is null or e.result->'generated_solution'='null' then raise invalid_parameter_value using message='SOLUTION_UNAVAILABLE';end if;gh=e.output_sha256;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(key::text,735));
  select * into exposure from public.math_solution_exposures where client_key=key;
  if found then
   if exposure.evaluation_id<>e.id or exposure.solution_id is distinct from sid or exposure.generated_output_sha256 is distinct from gh then raise unique_violation using message='REVEAL_RETRY_CONFLICT';end if;
  else
   insert into public.math_solution_exposures(evaluation_id,solution_id,generated_output_sha256,client_key) values(e.id,sid,gh,key) returning * into exposure;
  end if;
  answer=jsonb_build_object('exposure_id',exposure.id,'evaluation_id',e.id,'solution_id',sid,'target',target,'delivered_at',exposure.delivered_at,'provenance',case when target='GENERATED' or s.origin='AI_PROPOSED' then 'AI_GENERATED_REFERENCE' when s.origin='OFFICIAL' then 'OFFICIAL_SOLUTION' else 'VERIFIED_INTERNAL_SOLUTION' end,'physical_origin',case when target='GENERATED' then 'AI_GENERATED' else s.origin end,'body',case when target='GENERATED' then e.result->'generated_solution'->>'body' else s.body end,'learning_context','REFERENCE_SOLUTION_REVEALED');
 when 'create_resolve_attempt' then
  if v->>'kind' is null or v->>'kind' not in ('STEP_RETRY','FULL_RESOLVE','SHORT_ANSWER_RESOLVE') then raise invalid_parameter_value using message='INVALID_RESOLVE_KIND';end if;
  -- Reuse immutable attempt + exact canonical lineage validation and idempotency.
  newid=public.math_submit_attempt(v);answer=jsonb_build_object('attempt_id',newid);
 when 'request_reevaluation' then
  select * into a from public.math_attempts where id=(v->>'attempt_id')::uuid and student_id=u;
  if not found or a.kind='INITIAL' then raise invalid_parameter_value;end if;
  -- The canonical request owns lifecycle -> account -> attempt -> evaluation -> decision locking.
  -- A paid fallback is rejected atomically here; existing math_input is the separately explicit ordinary route.
  newid=public.math_request_evaluation(a.id,(v->>'client_submission_id')::uuid);
  select d.* into decision from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=newid;
  if decision.reason<>'included_revision' or decision.credits_required<>0 then raise invalid_parameter_value using message='INCLUDED_REEVALUATION_UNAVAILABLE';end if;
  answer=jsonb_build_object('evaluation_id',newid,'commercial_context','INCLUDED_REEVALUATION','additional_credit',0);
 when 'read_learning_history' then
  lim=coalesce((v->>'limit')::integer,20);before_at=(v->>'before_at')::timestamptz;before_id=(v->>'before_id')::uuid;
  if lim not between 1 and 50 or (before_at is null)<>(before_id is null) then raise invalid_parameter_value;end if;
  page='[]';
  for item in select ar.*,er.id as current_evaluation_id,er.state as evaluation_state,er.result->'progression' as progression,er.completed_at
   from public.math_attempts ar left join lateral(select id,state,result,completed_at from public.math_evaluations where attempt_id=ar.id order by requested_at desc,id desc limit 1) er on true
   where ar.student_id=u and ar.lineage_id=a.lineage_id and (before_at is null or (ar.created_at,ar.id)<(before_at,before_id)) order by ar.created_at desc,ar.id desc limit lim loop
   page=page||jsonb_build_array(jsonb_build_object('attempt_id',item.id,'created_at',item.created_at,'resolve_kind',item.kind,'prior_attempt_id',item.predecessor_id,'prior_evaluation_id',item.prior_evaluation_id,'target_step_id',item.target_step_id,'submitted_scope',case when item.kind='STEP_RETRY' then 'TARGET_STEP' else 'WHOLE_LEAF' end,'evaluation_id',item.current_evaluation_id,'evaluation_state',item.evaluation_state,'completed_at',item.completed_at,'reevaluation_delta',item.progression,
    'core_ids',(select coalesce(jsonb_agg(id order by position),'[]') from public.math_core where evaluation_id=item.current_evaluation_id),
    'exposed_hint_levels',(select coalesce(jsonb_agg(distinct hint_row.level),'[]') from public.math_hint_exposures x join public.math_hints hint_row on hint_row.id=x.hint_id where hint_row.evaluation_id=item.current_evaluation_id),
    'solution_revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=item.current_evaluation_id),
    'reference_solution_revealed_before_resolve',exists(select 1 from public.math_solution_exposures where evaluation_id=item.prior_evaluation_id and delivered_at<=item.created_at)));
   last_at=item.created_at;last_id=item.id;
  end loop;
  answer=jsonb_build_object('lineage_id',a.lineage_id,'attempts',page,'included_reevaluation',math_private.learning_eligibility(e.id,clock_timestamp()),'next_cursor',case when jsonb_array_length(page)=lim then jsonb_build_object('created_at',last_at,'attempt_id',last_id) else null end);
 end case;
 if octet_length(answer::text)>2097152 then raise program_limit_exceeded using message='LEARNING_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','math-learning-v1','action',action,'result',answer);
end$$;
revoke all on function public.math_learning(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_learning(jsonb) to authenticated;
do $$begin
 if has_schema_privilege('math_executor','math_private','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'TOPOLOGY_NOT_RESTORED';end if;
end$$;
commit;
