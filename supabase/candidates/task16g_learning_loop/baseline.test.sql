begin;grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;grant create on schema math_private to essay_executor;set role essay_executor;
CREATE OR REPLACE FUNCTION math_private.authorize_billing(uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e public.math_evaluations; a public.math_attempts; account uuid; parent public.essay_billing_decisions; decision uuid; selected_grant uuid; quantity integer=1; reason text='paid_cycle';
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select * into a from public.math_attempts where id=e.attempt_id;
 if exists(select 1 from public.math_billing_bindings where math_evaluation_id=e.id) then raise unique_violation using message='BINDING_ALREADY_EXISTS';end if;
 if e.state<>'REQUESTED' then raise invalid_parameter_value;end if;
 if e.request_kind='MATH_REEVALUATION' then
  select d.* into parent from public.essay_billing_decisions d
  join public.math_billing_bindings b on b.billing_decision_id=d.id
  join public.math_evaluations pe on pe.id=b.math_evaluation_id
  join public.math_attempts pa on pa.id=pe.attempt_id
  where d.account_id=account and d.status='settled' and d.reason='paid_cycle' and d.policy_key='essay_cycle' and d.policy_version='v2'
   and pa.lineage_id=a.lineage_id and pa.student_id=a.student_id and pa.id<>a.id and pa.created_at<a.created_at
   and pe.state='COMPLETED' and pe.request_kind='MATH_INITIAL_EVALUATION' and clock_timestamp()<pe.completed_at+interval '336 hours'
   and not exists(select 1 from public.essay_billing_decisions ch where ch.included_by_decision_id=d.id and ch.status in ('authorized','reserved','settled'))
   and not exists(select 1 from public.credit_transactions t where t.decision_id=d.id and t.transaction_type='refund')
  order by pe.completed_at desc,pe.id desc limit 1;
  if parent.id is not null then quantity=0;reason='included_revision';end if;
 end if;
 if quantity=1 then
  select g.id into selected_grant from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id)
   and (g.expires_at is null or g.expires_at>clock_timestamp())
   and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1
  order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if selected_grant is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT';end if;
 end if;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,null,e.idempotency_key,'essay_cycle','v2',reason,quantity,'authorized',parent.id) returning id into decision;
 insert into public.math_billing_bindings(math_evaluation_id,billing_decision_id,account_id) values(e.id,decision,account);
 if quantity=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(account,selected_grant,decision,'reserve',0,1,'reserve/'||decision::text,'essay_cycle_v2');
  update public.essay_billing_decisions set status='reserved',reserved_at=clock_timestamp() where id=decision;
 end if;
 return decision;
end$function$;
CREATE OR REPLACE FUNCTION math_private.settle_billing(uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e public.math_evaluations; b public.essay_billing_decisions; account uuid; t public.credit_transactions;
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select d.* into b from public.essay_billing_decisions d join public.math_billing_bindings m on m.billing_decision_id=d.id and m.account_id=d.account_id where m.math_evaluation_id=e.id for update of d;
 if b.id is null or b.account_id<>account or b.evaluation_id is not null then raise invalid_parameter_value;end if;
 if b.status='settled' and e.state='COMPLETED' then return;end if;
 if e.state<>'PROCESSING' or b.status not in ('authorized','reserved') then raise invalid_parameter_value;end if;
 if b.credits_required>0 then
  if b.status<>'reserved' or (select coalesce(sum(reserved_delta),0) from public.credit_transactions where decision_id=b.id)<>b.credits_required then raise check_violation using message='INVALID_RESERVATION';end if;
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' order by grant_id loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
   values(account,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,'evaluation_completed');
  end loop;
 end if;
 update public.essay_billing_decisions set status='settled',settled_at=clock_timestamp() where id=b.id;
end$function$;
CREATE OR REPLACE FUNCTION math_private.release_billing(uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e public.math_evaluations; b public.essay_billing_decisions; account uuid; t public.credit_transactions;
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select d.* into b from public.essay_billing_decisions d join public.math_billing_bindings m on m.billing_decision_id=d.id and m.account_id=d.account_id where m.math_evaluation_id=e.id for update of d;
 if b.id is null or b.account_id<>account or b.evaluation_id is not null then raise invalid_parameter_value;end if;
 if b.status in ('settled','released','rejected') then return;end if;
 if b.status='reserved' then
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' order by grant_id loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
   values(account,t.grant_id,b.id,'release',0,-t.reserved_delta,'release/'||b.id::text||'/'||t.grant_id::text,'evaluation_failed');
  end loop;
 end if;
 update public.essay_billing_decisions set status='released',released_at=clock_timestamp() where id=b.id;
end$function$;
reset role;
CREATE OR REPLACE FUNCTION public.math_learning(p_request jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end$function$;
CREATE OR REPLACE FUNCTION math_private.learning_eligibility(p_evaluation_id uuid, p_at timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
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
end$function$;
revoke create on schema math_private from essay_executor;revoke essay_executor from postgres granted by postgres;commit;