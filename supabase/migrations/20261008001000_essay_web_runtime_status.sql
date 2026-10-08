-- Additive read projection only; does not activate providers, change Credit, or open the Math kill switch.
begin;
set local lock_timeout='5s';
set local statement_timeout='15s';
do $$begin
 if current_user<>'postgres' then raise exception 'OWNER_REQUIRED';end if;
 if to_regprocedure('public.essay_web_runtime_status()') is not null then raise exception 'ESSAY_WEB_RUNTIME_COLLISION';end if;
 if to_regclass('math_private.runtime_control') is null or to_regprocedure('math_private.require_active(uuid[])') is null then raise exception 'MATH_ACTIVATION_AUTHORITY_REQUIRED';end if;
end$$;
create function public.essay_web_runtime_status() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 perform math_private.require_active(array[auth.uid()]);
 return jsonb_build_object('version','essay-web-runtime-v1','math_evaluations_enabled',
   coalesce((select evaluations_enabled from math_private.runtime_control where singleton),false));
end$$;
alter function public.essay_web_runtime_status() owner to postgres;
revoke all on function public.essay_web_runtime_status() from public,anon,service_role;
grant execute on function public.essay_web_runtime_status() to authenticated;
comment on function public.essay_web_runtime_status() is 'Authenticated active-account read of existing runtime kill switch; no content, credentials or student records.';
notify pgrst,'reload schema';
commit;
