-- Extend the same projection to mixed Math children; humanities remain byte-identical.
begin;
create table math_private.mixed_coaching_disclosures (
 run_id uuid not null references essay_exam_private.runs(id) on delete cascade,
 question_id uuid not null, student_id uuid not null, client_key uuid not null unique,
 delivered_at timestamptz not null default clock_timestamp(), primary key(run_id,question_id)
);
alter table math_private.mixed_coaching_disclosures enable row level security;
revoke all on math_private.mixed_coaching_disclosures from public,anon,authenticated,service_role;
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
set role math_executor;
grant execute on function math_private.coaching_projection(uuid,jsonb,text,jsonb,boolean) to postgres;
reset role;
revoke math_executor from postgres granted by postgres;

alter function public.essay_exam_history(uuid) rename to essay_exam_history_before_task16g;
revoke all on function public.essay_exam_history_before_task16g(uuid) from public,anon,authenticated,service_role;
create function math_private.mixed_coaching_projection(p_run jsonb,p_question jsonb,p_disclosed boolean) returns jsonb
language plpgsql immutable set search_path='' as $$
declare answer jsonb; student text;
begin
 select value->>'body' into student from jsonb_array_elements(p_run->'answers') where value->>'questionId'=p_question->>'questionId';
 answer=math_private.coaching_projection((p_question->>'questionId')::uuid,p_question->'evaluation',coalesce(student,''),jsonb_build_object('eligible',coalesce((p_run->>'free_rewrite_available')::boolean,false),'expires_at',p_run->'free_rewrite_expires_at','paid_available',true),p_disclosed);
 answer=answer||jsonb_build_object('run_id',p_run->'id','question_id',p_question->'questionId','exam_label',p_run->'title','completed_at',p_run->'completed_at');
 if p_disclosed then answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',p_question->'evaluation'->'steps','paths',p_question->'evaluation'->'paths','generated_solution',p_question->'evaluation'->'generated_solution'));end if;
 return answer;
end$$;
revoke all on function math_private.mixed_coaching_projection(jsonb,jsonb,boolean) from public,anon,authenticated,service_role;

create function public.essay_exam_history(p_run uuid default null) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare answer jsonb; r jsonb; q jsonb; rows jsonb='[]'; questions jsonb; mixed boolean; disclosed boolean;
begin
 answer=public.essay_exam_history_before_task16g(p_run);
 for r in select value from jsonb_array_elements(answer->'runs') loop
  mixed=false;questions='[]';
  for q in select value from jsonb_array_elements(coalesce(r->'result'->'questions','[]')) loop
   if q->'evaluation'->>'contract_version'='math-eval-v1' then
    mixed=true;
    disclosed=exists(select 1 from math_private.mixed_coaching_disclosures where run_id=(r->>'id')::uuid and question_id=(q->>'questionId')::uuid and student_id=auth.uid());
    -- Keep stored raw Math exclusively behind explicit disclosure, including legacy History consumers.
    if not disclosed then
     q=jsonb_build_object('questionId',q->'questionId','rubricVersion',q->'rubricVersion','evidenceVersion',q->'evidenceVersion','evaluation',jsonb_build_object('contract_version','math-coaching-v1','coaching',math_private.mixed_coaching_projection(r,q,false)));
    else
     q=q||jsonb_build_object('solution_revealed',true);
    end if;
   end if;
   questions=questions||jsonb_build_array(q);
  end loop;
  if mixed then r=jsonb_set(r,'{result}',jsonb_build_object('questions',questions));end if;
  rows=rows||jsonb_build_array(r);
 end loop;
 return jsonb_set(answer,'{runs}',rows);
end$$;
revoke all on function public.essay_exam_history(uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_history(uuid) to authenticated;

create function public.essay_math_coaching(p_request jsonb) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload'; action text=p_request->>'action'; r jsonb; q jsonb; key uuid; old math_private.mixed_coaching_disclosures; answer jsonb;
begin
 if p_request->>'dto_version' is distinct from 'math-coaching-v1' or p_request-array['dto_version','action','payload']<>'{}' or jsonb_typeof(v) is distinct from 'object' or action not in ('read','reveal') or action is null then raise invalid_parameter_value;end if;
 if v-(case when action='reveal' then array['run_id','question_id','client_submission_id'] else array['run_id','question_id'] end)<>'{}' then raise invalid_parameter_value;end if;
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
 return jsonb_build_object('dto_version','math-coaching-v1','action',action,'result',answer);
end$$;
revoke all on function public.essay_math_coaching(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.essay_math_coaching(jsonb) to authenticated;
commit;
