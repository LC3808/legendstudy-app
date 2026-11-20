CREATE OR REPLACE FUNCTION public.essay_exam_session_claim(p_subject uuid, p_run uuid, p_dispatch uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb; attempts jsonb;
begin
 -- Existing claim owns account lock, lifecycle, ownership and immutable lease token.
 result=public.essay_exam_claim(p_subject,p_run,p_dispatch);
 select r.attempts into attempts from essay_exam_private.retry_requests r where run_id=p_run order by generation desc limit 1;
 return result||jsonb_build_object('session_version','exam-session-v1','attempts',coalesce(attempts,'{}'::jsonb));
end $function$;
