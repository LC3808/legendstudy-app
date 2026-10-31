begin read only;
select p.oid::regprocedure, p.prosecdef, p.proconfig,
 has_function_privilege('authenticated',p.oid,'execute') authenticated,
 has_function_privilege('anon',p.oid,'execute') anon,
 has_function_privilege('service_role',p.oid,'execute') service_role
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('admin_essay_beta_config','admin_essay_beta_save','admin_essay_beta_report');
select c.relname,c.relrowsecurity,c.relacl from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='essay_beta_private' and c.relname in ('operations_config','settings_editors','settings_audit');
select campaign_id,beta_enabled,beta_start_at,beta_end_at,daily_free_limit,next_daily_limit,limit_effective_at,reset_timezone,version from essay_beta_private.operations_config;
-- Record these before/after installation; no evaluation or credit calls.
select count(*),md5(string_agg(row_to_json(x)::text,'' order by id)) from essay_exam_private.runs x;
select count(*),md5(string_agg(row_to_json(x)::text,'' order by id)) from public.credit_transactions x;
select count(*),md5(string_agg(row_to_json(x)::text,'' order by user_id,grant_day)) from essay_beta_private.daily_grants x;
-- Assert privileges rather than accepting a successful SELECT as verification.
do $$declare f regprocedure;begin
 foreach f in array array['public.admin_essay_beta_config()'::regprocedure,'public.admin_essay_beta_save(uuid,integer,jsonb,text)'::regprocedure,'public.admin_essay_beta_report(text,uuid,timestamptz,timestamptz,text,integer)'::regprocedure] loop
  if not (select prosecdef and proconfig @> array['search_path=""'] from pg_proc where oid=f)
   or not has_function_privilege('authenticated',f,'execute')
   or has_function_privilege('anon',f,'execute') or has_function_privilege('service_role',f,'execute')
   then raise exception 'ADMIN_RPC_PERMISSION_MISMATCH %',f;end if;
 end loop;
end $$;

commit;
