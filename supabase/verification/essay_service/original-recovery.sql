CREATE OR REPLACE FUNCTION public.math_recover_evaluation(p_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e public.math_evaluations;a public.math_attempts;
begin
 select ar.* into a from public.math_attempts ar join public.math_evaluations ev on ev.attempt_id=ar.id where ev.id=p_id;
 if a.id is null then raise no_data_found;end if;
 perform math_private.require_active(array[a.student_id]);
 perform 1 from public.math_attempts where id=a.id for update;
 select * into e from public.math_evaluations where id=p_id for update;
 if not ((e.state='PROCESSING' and e.lease_until<clock_timestamp()) or
 (e.state='REQUESTED' and e.requested_at<clock_timestamp()-interval '5 minutes')) then return false;end if;
 perform math_private.release_billing(e.id);
 update public.math_evaluations set state='FAILED',error_code='TIMEOUT' where id=e.id;
 return true;
end$function$
;
REVOKE ALL ON FUNCTION public.math_recover_evaluation(uuid) FROM PUBLIC,anon,authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.math_recover_evaluation(uuid) TO math_evaluation_worker;
