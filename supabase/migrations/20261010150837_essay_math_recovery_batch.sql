-- READY FOR REVIEW, NOT APPLIED. No Cron activation or financial policy change.
-- Canonical single-job recovery remains the only expiry/settlement authority.
begin;
do $$begin
 if to_regprocedure('public.math_recover_evaluation(uuid)') is null
 or md5(pg_get_functiondef('public.math_recover_evaluation(uuid)'::regprocedure))<>'5cc017fbbd0ba9ca4602827dd0fbeeeb' then
  raise exception 'Recovery prerequisite differs: review deployed function first';
 end if;
 if to_regprocedure('public.math_recover_expired_evaluations(integer)') is not null then
  raise exception 'Recovery batch already exists: inspect instead of overwriting';
 end if;
end$$;
create function public.math_recover_expired_evaluations(p_limit integer default 20)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r record; scanned integer=0; recovered integer=0; skipped integer=0;
begin
 if p_limit is null or p_limit<1 or p_limit>50 then raise sqlstate '22023' using message='INVALID_LIMIT';end if;
 -- Same lock order as canonical recovery: attempt first, evaluation inside the RPC.
 -- Concurrent runners skip locked attempts; the RPC rechecks expiry under its lock.
 for r in select e.id from public.math_attempts a join public.math_evaluations e on e.attempt_id=a.id
  where (e.state='PROCESSING' and e.lease_until<clock_timestamp())
     or (e.state='REQUESTED' and e.requested_at<clock_timestamp()-interval '5 minutes')
  order by e.requested_at,e.id limit p_limit for update of a skip locked
 loop
  scanned=scanned+1;
  begin
   if public.math_recover_evaluation(r.id) then recovered=recovered+1;end if;
  exception when sqlstate '42501' then skipped=skipped+1; -- Lifecycle denial stays denied.
  end;
 end loop;
 return jsonb_build_object('version','math-recovery-v1','scanned',scanned,'recovered',recovered,'skipped',skipped);
end$$;
revoke all on function public.math_recover_expired_evaluations(integer) from public,anon,authenticated,service_role;
grant execute on function public.math_recover_expired_evaluations(integer) to math_evaluation_worker;
commit;
