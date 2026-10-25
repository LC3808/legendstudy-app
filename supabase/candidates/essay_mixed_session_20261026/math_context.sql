-- Candidate only. Apply through a baseline-guarded package after mixed routing is ready.
-- Read frozen material/answer under the EXISTING parent lease. Never reserve/settle.
create function public.essay_exam_math_context(p_subject uuid,p_run uuid,p_token uuid,p_question uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; pkg jsonb; entry jsonb; answer jsonb; previous jsonb;
begin
 perform math_private.require_active(array[p_subject]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id
 where x.id=p_run and a.user_id=p_subject;
 if r.id is null or r.state<>'reserved' or p_token is null or r.lease_token is distinct from p_token
 then raise sqlstate 'PT403' using message='EXAM_LEASE_REQUIRED';end if;
 select value into answer from jsonb_array_elements(r.snapshot->'answers') where value->>'questionId'=p_question::text;
 if answer is null then raise sqlstate 'PT403' using message='QUESTION_NOT_SUBMITTED';end if;
 pkg=public.essay_material_runtime_package(r.exam_id,r.snapshot->'runtime'->>'package_digest');
 select value into entry from jsonb_array_elements(pkg->'questions') where value->>'question_id'=p_question::text;
 if entry->>'evaluation_engine' is distinct from 'math' or jsonb_typeof(entry->'math_context') is distinct from 'object'
 then raise exception 'MATH_PACKAGE_REQUIRED';end if;
 if not exists(select 1 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id
 join public.math_problem_sets s on s.id=p.problem_set_id where l.id=(entry->'math_context'->'leaf'->>'id')::uuid
 and l.essay_question_id=p_question and s.essay_exam_id=r.exam_id)
 then raise exception 'MATH_QUESTION_MAPPING_REQUIRED';end if;
 if r.parent_id is not null then
  select q into previous from essay_exam_private.runs parent,
   lateral jsonb_array_elements(parent.result->'questions') q
   where parent.id=r.parent_id and parent.account_id=r.account_id and q->>'questionId'=p_question::text;
  if previous->'evaluation'->>'contract_version' is distinct from 'math-eval-v1'
  then raise exception 'PRIOR_MATH_RESULT_REQUIRED';end if;
 end if;
 return jsonb_build_object('run_id',r.id,'exam_id',r.exam_id,'question_id',p_question,
  'parent_id',r.parent_id,'answer',answer,'entry',entry,'previous',previous,
  'package_digest',pkg->>'package_digest');
end$$;
revoke all on function public.essay_exam_math_context(uuid,uuid,uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_math_context(uuid,uuid,uuid,uuid) to essay_worker;
