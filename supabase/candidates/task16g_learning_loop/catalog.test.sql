begin;
-- Existing leaf/Registry FK, no inferred question number matching.
create or replace function public.math_catalog(p_limit integer default 20) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;begin
 perform math_private.require_active(array[auth.uid()]);
 if p_limit not between 1 and 50 then raise invalid_parameter_value;end if;
 select coalesce(jsonb_agg(x),'[]') into result from (
 select s.essay_exam_id,l.essay_question_id,l.id as leaf_id,l.statement,p.statement as problem_statement,s.label||' · '||q.label as label,l.response_format
 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id
 join public.essay_questions q on q.id=l.essay_question_id and q.essay_exam_id=s.essay_exam_id
 where p.state='ACTIVE' and s.state='ACTIVE' order by s.id,p.display_order,l.display_order limit p_limit) x;
 return result;
end$$;
commit;
