begin;
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to math_executor;
set role math_executor;
alter function public.math_coaching(jsonb) rename to math_coaching_before_task16g;
revoke all on function public.math_coaching_before_task16g(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_coaching_before_task16g(jsonb) to postgres;
reset role;
revoke create on schema public from math_executor;
revoke math_executor from postgres granted by postgres;
create function public.math_coaching(p_request jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare answer jsonb; run math_private.session_runs; quote jsonb; can_continue boolean;
begin
 answer=public.math_coaching_before_task16g(p_request);
 if p_request->>'action' not in ('read','reveal') then return answer;end if;
 select r.* into run from math_private.session_evaluations x join math_private.session_members m on m.attempt_id=x.attempt_id join math_private.session_runs r on r.id=m.run_id
 where x.evaluation_id=(p_request->'payload'->>'evaluation_id')::uuid and r.student_id=auth.uid();
 if found then
  can_continue=run.state='completed' and not exists(select 1 from math_private.session_runs where previous_run_id=run.id and state<>'cancelled');
  if can_continue then quote=public.math_session_quote(run.id);end if;
  answer=jsonb_set(answer,'{result,rewrite_policy}',coalesce(answer->'result'->'rewrite_policy','{}')||jsonb_build_object('eligible',can_continue and quote->>'credits_required'='0','paid_available',can_continue and quote->>'credits_required'='1','session_run_id',run.id,'exam_id',run.exam_id,'next_quote',quote));
 end if;
 return answer;
end$$;
revoke all on function public.math_coaching(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_coaching(jsonb) to authenticated;
commit;
