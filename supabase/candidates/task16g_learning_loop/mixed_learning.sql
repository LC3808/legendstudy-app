begin;
create table math_private.mixed_coaching_hints(
 run_id uuid not null references essay_exam_private.runs(id) on delete cascade,question_id uuid not null,task_id uuid not null,level integer not null check(level in(1,2)),student_id uuid not null,client_key uuid not null unique,delivered_at timestamptz not null,primary key(run_id,question_id,task_id,level)
);
alter table math_private.mixed_coaching_hints enable row level security;
revoke all on math_private.mixed_coaching_hints from public,anon,authenticated,service_role;
create or replace function public.essay_math_coaching(p_request jsonb) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload'; action text=p_request->>'action'; r jsonb; q jsonb; key uuid; old math_private.mixed_coaching_disclosures; answer jsonb; task jsonb; old_hint math_private.mixed_coaching_hints; history_row jsonb; attempts jsonb;
begin
 if p_request->>'dto_version' is distinct from 'math-coaching-v1' or p_request-array['dto_version','action','payload']<>'{}' or jsonb_typeof(v) is distinct from 'object' or action not in ('read','reveal','hint','history') or action is null then raise invalid_parameter_value;end if;
 if v-(case when action='hint' then array['run_id','question_id','client_submission_id','task_id','level'] when action='reveal' then array['run_id','question_id','client_submission_id'] else array['run_id','question_id'] end)<>'{}' then raise invalid_parameter_value;end if;
 -- The existing History function enforces owner and account lifecycle before any access.
 r=public.essay_exam_history_before_task16g((v->>'run_id')::uuid)->'runs'->0;
 if r is null or r->>'state'<>'completed' then raise insufficient_privilege;end if;
 select value into q from jsonb_array_elements(r->'result'->'questions') where value->>'questionId'=v->>'question_id' and value->'evaluation'->>'contract_version'='math-eval-v1';
 if q is null then raise insufficient_privilege;end if;
 if action='reveal' then
  key=(v->>'client_submission_id')::uuid;if key is null then raise invalid_parameter_value;end if;
  perform pg_advisory_xact_lock(hashtextextended(r->>'id',717));
  select * into old from math_private.mixed_coaching_disclosures where client_key=key;
  if found and (old.run_id<>(r->>'id')::uuid or old.question_id<>(q->>'questionId')::uuid) then raise unique_violation using message='DISCLOSURE_RETRY_CONFLICT';end if;
  insert into math_private.mixed_coaching_disclosures(run_id,question_id,student_id,client_key) values((r->>'id')::uuid,(q->>'questionId')::uuid,auth.uid(),key) on conflict(run_id,question_id) do nothing;
 end if;
 answer=math_private.mixed_coaching_projection(r,q,exists(select 1 from math_private.mixed_coaching_disclosures where run_id=(r->>'id')::uuid and question_id=(q->>'questionId')::uuid and student_id=auth.uid()));
 if action='hint' then
  key=(v->>'client_submission_id')::uuid;
  if key is null or v->>'level' is null or (v->>'level')::integer not in (1,2) then raise invalid_parameter_value;end if;
  select value into task from jsonb_array_elements(answer->'tasks') where value->>'id'=v->>'task_id';
  if task is null then raise invalid_parameter_value using message='HINT_UNAVAILABLE';end if;
  select * into old_hint from math_private.mixed_coaching_hints where client_key=key;
  if found and (old_hint.run_id<>(r->>'id')::uuid or old_hint.question_id<>(q->>'questionId')::uuid or old_hint.task_id<>(v->>'task_id')::uuid or old_hint.level<>(v->>'level')::integer) then raise unique_violation using message='HINT_RETRY_CONFLICT';end if;
  insert into math_private.mixed_coaching_hints values((r->>'id')::uuid,(q->>'questionId')::uuid,(v->>'task_id')::uuid,(v->>'level')::integer,auth.uid(),key,clock_timestamp()) on conflict do nothing;
  answer=jsonb_build_object('level',(v->>'level')::integer,'body',case when v->>'level'='1' then '사용한 정의·정리의 적용 조건을 원래 문제의 조건과 대조하세요.' else task->>'direction' end);
 elsif action='history' then
  -- Reuse the existing bounded owner History, filtered to this exam/question.
  -- No raw evaluation prose or answer bodies enter this projection.
  attempts='[]';
  for history_row in select value from jsonb_array_elements(public.essay_exam_history_before_task16g(null)->'runs') loop
   if history_row->>'exam_id'=r->>'exam_id' and (history_row->'question_ids') ? (q->>'questionId') then
    attempts=attempts||jsonb_build_array(jsonb_build_object(
     'run_id',history_row->'id','evaluation_state',history_row->'state',
     'resolve_kind',case when history_row->>'parent_id' is null then 'INITIAL' else 'FULL_RESOLVE' end,
     'completed_at',history_row->'completed_at',
     'solution_revealed',exists(select 1 from math_private.mixed_coaching_disclosures where run_id=(history_row->>'id')::uuid and question_id=(q->>'questionId')::uuid and student_id=auth.uid()),
     'exposed_hint_levels',(select coalesce(jsonb_agg(distinct level),'[]') from math_private.mixed_coaching_hints where run_id=(history_row->>'id')::uuid and question_id=(q->>'questionId')::uuid and student_id=auth.uid())));
   end if;
  end loop;
  answer=jsonb_build_object('attempts',attempts);
 end if;
 return jsonb_build_object('dto_version','math-coaching-v1','action',action,'result',answer);
end$$;
commit;
