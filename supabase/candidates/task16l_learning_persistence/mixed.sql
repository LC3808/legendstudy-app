-- Existing completed parent JSON owns mixed-question learning. No duplicate History.
begin;
do $$ declare source text;begin
 source=pg_get_functiondef('public.essay_math_coaching(jsonb)'::regprocedure);
 if to_regprocedure('math_private.mixed_coaching_before_task16l(jsonb)') is not null then raise exception 'ALREADY_INSTALLED';end if;
 execute replace(source,'public.essay_math_coaching(','math_private.mixed_coaching_before_task16l(');
end$$;
revoke all on function math_private.mixed_coaching_before_task16l(jsonb) from public,anon,authenticated,service_role;
create or replace function public.essay_math_coaching(p_request jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare reply jsonb; r jsonb; q jsonb; packet jsonb; prior jsonb; prev jsonb; row jsonb; entries jsonb='[]'; action text=p_request->>'action';
begin
 reply=math_private.mixed_coaching_before_task16l(p_request);
 if action not in ('read','reveal','history') then return reply;end if;
 r=public.essay_exam_history_before_task16g((p_request->'payload'->>'run_id')::uuid)->'runs'->0;
 -- The original RPC requires completed whole exam + current owner; repeat completion
 -- condition here so question-level optional data cannot imply whole exam completion.
 if r->>'state' is distinct from 'completed' then return reply;end if;
 select value into q from jsonb_array_elements(r->'result'->'questions') where value->>'questionId'=p_request->'payload'->>'question_id';
 packet=q->'evaluation'->'learning_judgement';
 if action in ('read','reveal') and packet->'value'->>'status'='ASSESSED' and packet->'review'->'accepted'='true' then
  if r->>'parent_id' is not null then
   prev=public.essay_exam_history_before_task16g((r->>'parent_id')::uuid)->'runs'->0;
   if prev->>'exam_id'=r->>'exam_id' and prev->>'state'='completed' then
    select value->'evaluation'->'learning_judgement' into prior from jsonb_array_elements(prev->'result'->'questions') where value->>'questionId'=q->>'questionId';
   end if;
  end if;
  reply=jsonb_set(reply,'{result}',reply->'result'||jsonb_build_object('learning_completeness',packet->'value','learning_comparison',math_private.learning_comparison(packet,prior),'evaluation_id',packet->'value'->>'evaluation_id'));
 elsif action='history' then
  for row in select value from jsonb_array_elements(reply->'result'->'attempts') loop
   prev=public.essay_exam_history_before_task16g((row->>'run_id')::uuid)->'runs'->0;
   if prev->>'state'='completed' and prev->>'exam_id'=r->>'exam_id' then
    select value->'evaluation'->'learning_judgement' into packet from jsonb_array_elements(prev->'result'->'questions') where value->>'questionId'=q->>'questionId';
    if packet->'value'->>'status'='ASSESSED' and packet->'review'->'accepted'='true' then row=row||jsonb_build_object('learning_completeness',packet->'value','evaluation_id',packet->'value'->>'evaluation_id');end if;
   end if;
   entries=entries||jsonb_build_array(row);
  end loop;
  reply=jsonb_set(reply,'{result,attempts}',entries);
 end if;
 return reply;
end$$;
commit;
