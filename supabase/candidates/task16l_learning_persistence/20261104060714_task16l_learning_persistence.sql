-- TASK16-L candidate. TEST first; Production requires separate Owner approval.
begin;
alter table public.math_evaluations add column learning_judgement jsonb;
comment on column public.math_evaluations.learning_judgement is 'Optional independently reviewed learning judgement, written only with new canonical finalization. Never a university score.';

create function math_private.finalize_with_learning(eid uuid, token uuid, output jsonb, packet jsonb) returns uuid
language plpgsql security invoker set search_path='' as $$
declare e public.math_evaluations; v jsonb; refs jsonb; observations jsonb; result uuid;
begin
 perform math_private.lock_evaluation(eid);
 select * into strict e from public.math_evaluations where id=eid;
 if packet is not null then
  if e.state='COMPLETED' then
   if e.learning_judgement is null or e.learning_judgement->'submitted' is distinct from packet then
    raise invalid_parameter_value using message='LEARNING_BACKFILL_OR_REPLAY_CONFLICT';
   end if;
  else
   if e.state<>'PROCESSING' or e.lease_token is distinct from token or e.lease_until<=clock_timestamp() then raise invalid_parameter_value using message='STALE_FINALIZE';end if;
   v=packet->'value';
   if jsonb_typeof(packet) is distinct from 'object' or octet_length(packet::text)>32000
    or packet-array['value','review']<>'{}' or jsonb_typeof(v) is distinct from 'object'
    or v-array['version','evaluation_id','question_id','rubric_version','assessed_at','status','level','rationale','criterion_refs','observation_refs','strengths','improvements','next_direction','criterion_evidence']<>'{}'
    or jsonb_typeof(v->'level') is distinct from 'number'
    or v->>'version' is distinct from 'learning-completeness-v1'
    or v->>'status' is distinct from 'ASSESSED' or coalesce(v->>'level','') !~ '^[1-5]$'
    or v->>'evaluation_id' is distinct from eid::text or v->>'question_id' is distinct from e.leaf_id::text
    or coalesce(v->>'rubric_version','') !~ '^pinned-[a-f0-9]{64}$'
    or coalesce(length(v->>'rationale'),0) not between 1 and 1200
    or coalesce(length(v->>'next_direction'),0) not between 1 and 1200
    or jsonb_typeof(v->'strengths') is distinct from 'array' or jsonb_typeof(v->'improvements') is distinct from 'array'
    or jsonb_typeof(v->'criterion_refs') is distinct from 'array' or jsonb_typeof(v->'observation_refs') is distinct from 'array'
    or packet->'review'->>'version' is distinct from 'learning-independent-review-v1'
    or packet->'review'->'accepted' is distinct from 'true'::jsonb
    or coalesce(packet->'review'->>'candidate_sha256','') !~ '^[a-f0-9]{64}$'
    or output->'overall'->>'review_status' is distinct from 'NOT_REQUIRED'
    or output->'overall'->>'status'='NOT_DETERMINABLE' then raise invalid_parameter_value using message='LEARNING_INVALID';end if;
   if (v->>'assessed_at')::timestamptz is null or (v->>'assessed_at')::timestamptz<e.requested_at or (v->>'assessed_at')::timestamptz>clock_timestamp()+interval '5 minutes'
    or jsonb_array_length(v->'improvements')>5 or jsonb_array_length(v->'strengths')>20
    or exists(select 1 from jsonb_array_elements((v->'strengths')||(v->'improvements')) x where jsonb_typeof(x)<>'string' or length(x#>>'{}') not between 1 and 1200)
    then raise invalid_parameter_value using message='LEARNING_INVALID';end if;
   select coalesce(jsonb_agg(criterion_id::text order by criterion_id),'[]') into refs from public.math_evaluation_criteria where evaluation_id=eid;
   if jsonb_array_length(refs)=0 or jsonb_array_length(refs)<>jsonb_array_length(v->'criterion_refs') or not (refs @> (v->'criterion_refs') and refs <@ (v->'criterion_refs')) then raise invalid_parameter_value using message='LEARNING_CRITERIA_MISMATCH';end if;
   select coalesce(jsonb_agg(x->>'id'),'[]') into observations from jsonb_array_elements(output->'steps') x;
   if jsonb_array_length(v->'observation_refs')=0 or not observations @> (v->'observation_refs') then raise invalid_parameter_value using message='LEARNING_OBSERVATION_MISMATCH';end if;
  end if;
 end if;
 -- Canonical validation, ownership/lifecycle, fencing and replay remain authoritative.
 result=public.math_finalize_evaluation(eid,token,output);
 if packet is not null and e.state='PROCESSING' then
  update public.math_evaluations set learning_judgement=jsonb_build_object(
   'submitted',packet,'value',packet->'value','review',packet->'review',
   'criterion_outcomes',(select jsonb_agg(jsonb_build_object('criterion_id',x->>'criterion_id','verdict',x->>'verdict') order by x->>'criterion_id') from jsonb_array_elements(output->'criteria') x),
   'metadata',jsonb_build_object('assessment',output->'provenance','selected_extraction_id',e.selected_extraction_id,'profile_id',e.profile_id,'attempt_id',e.attempt_id,
    'exam_id',(select to_jsonb(ps)->>'essay_exam_id' from public.math_subproblems s join public.math_problems p on p.id=s.problem_id join public.math_problem_sets ps on ps.id=p.problem_set_id where s.id=e.leaf_id),
    'essay_question_id',(select to_jsonb(s)->>'essay_question_id' from public.math_subproblems s where s.id=e.leaf_id))) where id=eid;
 end if;
 return result;
end$$;
revoke all on function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) from public,anon,authenticated,service_role;
grant execute on function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) to math_executor;

-- Match canonical math executor boundary; public facade may be owned by postgres.
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
alter function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) security definer;
grant create on schema math_private to math_executor;
alter function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) owner to math_executor;
set local role math_executor;
grant execute on function math_private.finalize_with_learning(uuid,uuid,jsonb,jsonb) to postgres;
reset role;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;

-- Preserve the existing public RPC signature, owner, ACL and all non-finalize code.
do $$ declare original text; patched text; begin
 original=pg_get_functiondef('public.math_evaluation(jsonb)'::regprocedure);
 if position('math_private.finalize_with_learning' in original)>0 then raise exception 'ALREADY_INSTALLED';end if;
 patched=replace(original,'''evaluation_id'',''lease_token'',''output''','''evaluation_id'',''lease_token'',''output'',''learning_judgement''');
 patched=replace(patched,'public.math_finalize_evaluation((v->>''evaluation_id'')::uuid,(v->>''lease_token'')::uuid,v->''output'')','math_private.finalize_with_learning((v->>''evaluation_id'')::uuid,(v->>''lease_token'')::uuid,v->''output'',v->''learning_judgement'')');
 if patched=original or position('math_private.finalize_with_learning' in patched)=0 then raise exception 'UNEXPECTED_FINALIZE_DEFINITION';end if;
 execute patched;
end$$;

create function math_private.learning_comparison(current_packet jsonb, prior_packet jsonb) returns jsonb
language plpgsql immutable set search_path='' as $$
declare cur jsonb=current_packet->'value'; prev jsonb=prior_packet->'value'; improved jsonb; remaining jsonb;
begin
 if cur is null then return null;end if;
 if prev is null then return jsonb_build_object('comparable',false,'reason','NO_PREVIOUS_ASSESSMENT');end if;
 if cur->>'question_id' is distinct from prev->>'question_id' or cur->>'version' is distinct from prev->>'version' or cur->>'rubric_version' is distinct from prev->>'rubric_version'
 or current_packet->'metadata'->'assessment'->>'prompt_version' is distinct from prior_packet->'metadata'->'assessment'->>'prompt_version'
 or current_packet->'metadata'->'assessment'->>'model' is distinct from prior_packet->'metadata'->'assessment'->>'model'
 then return jsonb_build_object('comparable',false,'reason','CRITERIA_CHANGED');end if;
 select coalesce(jsonb_agg(c->>'criterion_id'),'[]') into improved from jsonb_array_elements(current_packet->'criterion_outcomes') c join jsonb_array_elements(prior_packet->'criterion_outcomes') p on c->>'criterion_id'=p->>'criterion_id'
 where (case c->>'verdict' when 'satisfied' then 3 when 'partially_satisfied' then 2 when 'not_satisfied' then 1 end)>(case p->>'verdict' when 'satisfied' then 3 when 'partially_satisfied' then 2 when 'not_satisfied' then 1 end);
 select coalesce(jsonb_agg(c->>'criterion_id'),'[]') into remaining from jsonb_array_elements(current_packet->'criterion_outcomes') c where c->>'verdict' in ('partially_satisfied','not_satisfied');
 return jsonb_build_object('comparable',true,'before',(prev->>'level')::integer,'after',(cur->>'level')::integer,'delta',(cur->>'level')::integer-(prev->>'level')::integer,'prior_evaluation_id',prev->>'evaluation_id','improved_criterion_ids',improved,'remaining_criterion_ids',remaining,'improved_elements',(select coalesce(jsonb_agg(x),'[]') from jsonb_array_elements(coalesce(cur->'criterion_evidence','[]')) x where improved ? (x->>'criterion_id')),'remaining_elements',(select coalesce(jsonb_agg(x),'[]') from jsonb_array_elements(coalesce(cur->'criterion_evidence','[]')) x where remaining ? (x->>'criterion_id')),'prior_rationale',prev->>'rationale','current_rationale',cur->>'rationale');
end$$;
revoke all on function math_private.learning_comparison(jsonb,jsonb) from public,anon,authenticated,service_role;
grant execute on function math_private.learning_comparison(jsonb,jsonb) to math_executor;

-- Copy current guard/projection including any official-solution wrapper, not an old file.
do $$ declare original text; begin
 if to_regprocedure('math_private.coaching_before_task16l(jsonb)') is not null then raise exception 'ALREADY_INSTALLED';end if;
 original=pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure);
 execute replace(original,'public.math_coaching(', 'math_private.coaching_before_task16l(');
end$$;
revoke all on function math_private.coaching_before_task16l(jsonb) from public,anon,authenticated,service_role;
grant execute on function math_private.coaching_before_task16l(jsonb) to math_executor;

create or replace function public.math_coaching(p_request jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare reply jsonb; e public.math_evaluations; prior jsonb; a public.math_attempts; row jsonb; entries jsonb='[]'; action text=p_request->>'action';
begin
 -- Authenticate and authorize before inspecting any optional learning data.
 reply=math_private.coaching_before_task16l(p_request);
 if action in ('read','reveal') then
  select ev.* into strict e from public.math_evaluations ev join public.math_attempts at on at.id=ev.attempt_id where ev.id=(p_request->'payload'->>'evaluation_id')::uuid and at.student_id=math_private.current_subject();
  if e.learning_judgement is not null then
   select * into a from public.math_attempts where id=e.attempt_id;
   select ev.learning_judgement into prior from public.math_evaluations ev join public.math_attempts at on at.id=ev.attempt_id where ev.id=a.prior_evaluation_id and ev.leaf_id=e.leaf_id and at.student_id=math_private.current_subject() and at.lineage_id=a.lineage_id;
   reply=jsonb_set(reply,'{result}',reply->'result'||jsonb_build_object('learning_completeness',e.learning_judgement->'value','learning_comparison',math_private.learning_comparison(e.learning_judgement,prior)));
  end if;
 elsif action='history' then
  for row in select value from jsonb_array_elements(reply->'result'->'attempts') loop
   select ev.* into e from public.math_evaluations ev join public.math_attempts at on at.id=ev.attempt_id where ev.id=(row->>'evaluation_id')::uuid and at.student_id=math_private.current_subject();
   if found and e.learning_judgement is not null then row=row||jsonb_build_object('learning_completeness',e.learning_judgement->'value');end if;
   entries=entries||jsonb_build_array(row);
  end loop;
  reply=jsonb_set(reply,'{result,attempts}',entries);
 end if;
 return reply;
end$$;
-- CREATE OR REPLACE retains the existing authenticated-only ACL.
commit;
