begin;
CREATE OR REPLACE FUNCTION math_private.evaluation_admission()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if not (select evaluations_enabled from math_private.runtime_control where singleton) then
 raise exception 'MATH_EVALUATIONS_PAUSED' using errcode='55000';end if;return new;
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
 where p.state='ACTIVE' and s.state='ACTIVE' order by s.id,p.display_order,l.display_order limit p_limit) x;
 return result;
end$function$;
CREATE OR REPLACE FUNCTION public.essay_web_runtime_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 perform math_private.require_active(array[auth.uid()]);
 return jsonb_build_object('version','essay-web-runtime-v1','math_evaluations_enabled',
   coalesce((select evaluations_enabled from math_private.runtime_control where singleton),false));
end$function$;
update math_private.runtime_control set evaluations_enabled=false where singleton;
commit;
