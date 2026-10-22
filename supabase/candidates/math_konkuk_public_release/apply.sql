begin;
CREATE OR REPLACE FUNCTION math_private.evaluation_admission()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if not (select evaluations_enabled from math_private.runtime_control where singleton) then
 raise exception 'MATH_EVALUATIONS_PAUSED' using errcode='55000';end if;
 if new.leaf_id is distinct from '3bab07d3-c047-53c2-89ad-9fa20ec7b3f3'::uuid
 or not exists(select 1 from public.math_attempts a where a.id=new.attempt_id and a.student_id=auth.uid() and a.leaf_id=new.leaf_id) then
 raise exception 'MATH_QUESTION_NOT_RELEASED' using errcode='55000';end if;
 return new;
end$function$;

CREATE OR REPLACE FUNCTION public.math_catalog(p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb;begin
 perform math_private.require_active(array[auth.uid()]);
 if p_limit not between 1 and 50 then raise invalid_parameter_value;end if;
 select coalesce(jsonb_agg(x),'[]') into result from (
 select l.id as leaf_id,l.statement,p.statement as problem_statement,s.label,l.response_format
 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id
 where l.id='3bab07d3-c047-53c2-89ad-9fa20ec7b3f3'::uuid and p.state='ACTIVE' and s.state='ACTIVE' order by s.id,p.display_order,l.display_order limit p_limit) x;
 return result;
end$function$;

update math_private.runtime_control set evaluations_enabled=true where singleton;
commit;
