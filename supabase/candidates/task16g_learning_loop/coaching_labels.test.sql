-- TEST-only incremental display projection. No table/ACL/financial changes.
-- Run only on the dedicated TASK16-G TEST project after the common wrapper.
begin;
do $patch$
declare definition text; marker text=$marker$ if p_request->>'action' not in ('read','reveal') then return answer;end if;$marker$;
begin
 definition=pg_get_functiondef('public.math_coaching(jsonb)'::regprocedure);
 if position('math_coaching_before_task16g' in definition)=0 or position(marker in definition)=0 or position('-- Display only the canonical question label' in definition)>0 then
  raise exception 'TASK16G_COACHING_LABEL_BASELINE_CHANGED';
 end if;
 execute replace(definition,marker,marker||$addition$
 -- Display only the canonical question label; a leaf_key is an internal identifier.
 answer=jsonb_set(answer,'{result}',answer->'result'||coalesce((
  select jsonb_build_object('exam_label',ps.label||' · '||q.label)
  from public.math_evaluations e join public.math_subproblems s on s.id=e.leaf_id
  join public.math_problems p on p.id=s.problem_id join public.math_problem_sets ps on ps.id=p.problem_set_id
  join public.essay_questions q on q.id=s.essay_question_id and q.essay_exam_id=ps.essay_exam_id
  where e.id=(p_request->'payload'->>'evaluation_id')::uuid
 ),'{}'::jsonb));$addition$);
end$patch$;
commit;
