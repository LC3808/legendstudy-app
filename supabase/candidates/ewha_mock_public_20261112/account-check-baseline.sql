CREATE OR REPLACE FUNCTION account_private.allowed(u uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select u is not null and exists(select 1 from auth.users where id=u) and not exists(select 1 from public.account_deletion_requests where subject_id=u and state in ('DELETION_PENDING','ERASING'))
$function$
