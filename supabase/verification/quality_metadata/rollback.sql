-- Owner-only rollback of these two functions; no student/history data writes.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
do $rollback_preflight$
begin
 if md5(pg_get_functiondef('public.qlm_list_cases(integer,timestamp with time zone,uuid)'::regprocedure)) <> 'ed39c64765e1580dd0e813a78b6ca0a7'
 or md5(pg_get_functiondef('public.qlm_case_detail(uuid)'::regprocedure)) <> '2c262739380528d4f00813ddea5829a2'
 then raise exception 'QUALITY_METADATA_ROLLBACK_DRIFT'; end if;
 if exists(select 1 from pg_proc where oid in ('public.qlm_list_cases(integer,timestamptz,uuid)'::regprocedure,'public.qlm_case_detail(uuid)'::regprocedure) and (proowner <> 'postgres'::regrole or proacl::text is distinct from '{postgres=X/postgres,authenticated=X/postgres}')) then raise exception 'QUALITY_METADATA_ROLLBACK_ACL_DRIFT';end if;
end $rollback_preflight$;
-- Production function backup, read-only snapshot 2026-10-10. No secrets/student data.
-- qlm_case_detail(uuid); owner=postgres; acl={postgres=X/postgres,authenticated=X/postgres}; definition_md5=06a6eec442d7ff3f3869b4b74cde82ba
CREATE OR REPLACE FUNCTION public.qlm_case_detail(uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin perform math_private.hq_require_operator($1);return math_private.evaluation_projection($1,true);end$function$;

-- qlm_list_cases(integer,timestamp with time zone,uuid); owner=postgres; acl={postgres=X/postgres,authenticated=X/postgres}; definition_md5=09e99c01c3b50850e4cf6e3778d847d8
CREATE OR REPLACE FUNCTION public.qlm_list_cases(integer, timestamp with time zone, uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n integer:=least(100,greatest(1,coalesce($1,20)));v jsonb;
begin
 perform math_private.hq_require_operator(null);if ($2 is null)<>($3 is null) then raise invalid_parameter_value;end if;
 select coalesce(jsonb_agg(jsonb_build_object('evaluation_id',id,'completed_at',completed_at,'leaf_id',leaf_id)),'[]') into v from (select id,completed_at,leaf_id from public.math_evaluations where state='COMPLETED' and exists(select 1 from public.math_attempts a where a.id=attempt_id and account_private.allowed(a.student_id)) and ($2 is null or (completed_at,id)<($2,$3)) order by completed_at desc,id desc limit n) x;
 return jsonb_build_object('dto_version','qlm-read-v1','cases',v);
end$function$;

commit;
