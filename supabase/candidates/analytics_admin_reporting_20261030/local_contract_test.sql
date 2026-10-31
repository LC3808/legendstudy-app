-- LOCAL SYNTHETIC DB ONLY. Run after bootstrap/schema fixture + apply.sql.
-- Never execute this seed script against a production project.
\set ON_ERROR_STOP on
begin;
do $$ begin
 if current_database()<>'analytics_task03' or inet_server_port() is distinct from 55439 then
  raise exception 'LOCAL_ANALYTICS_FIXTURE_REQUIRED';
 end if;
end $$;
insert into public.essay_ai_processing_runs(id,provider,model_name,status,started_at,input_tokens,output_tokens,cost_amount,currency,cost_basis)
values ('00000000-0000-0000-0000-000000000010','fixture','fixture','completed','2026-10-15',100,40,0.01,'USD','provider_reported');
do $$ declare p record; begin
 for p in select oid from pg_proc where pronamespace='public'::regnamespace and proname like 'analytics_%' loop
  if has_function_privilege('anon',p.oid,'execute') or has_function_privilege('service_role',p.oid,'execute') or not has_function_privilege('authenticated',p.oid,'execute') then raise exception 'BAD_ACL'; end if;
 end loop;
end $$;
create temporary table fixture_before as
 select md5(row_to_json(r)::text) as digest from public.essay_ai_processing_runs r;
set local role authenticated;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000002';
do $$ declare n text; begin
 if public.analytics_admin_check() then raise exception 'NON_ADMIN_ALLOWED'; end if;
 for n in select proname from pg_proc where pronamespace='public'::regnamespace and proname like 'analytics_%' and pronargs=2 loop
  begin
   execute format('select public.%I($1,$2)',n) using '2026-10-01'::timestamptz,'2026-11-01'::timestamptz;
   raise exception 'NON_ADMIN_REPORT_ALLOWED';
  exception when sqlstate 'PT403' then null; end;
 end loop;
end $$;
set local request.jwt.claim.sub='';
do $$ begin if public.analytics_admin_check() then raise exception 'NO_JWT_ALLOWED'; end if; end $$;
set local request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';
do $$ declare n text; result jsonb; begin
 if not public.analytics_admin_check() then raise exception 'ADMIN_DENIED'; end if;
 for n in select proname from pg_proc where pronamespace='public'::regnamespace and proname like 'analytics_%' and pronargs=2 loop
  execute format('select public.%I($1,$2)',n) into result using '2026-10-01'::timestamptz,'2026-11-01'::timestamptz;
  if result is null then raise exception 'REPORT_MISSING'; end if;
  begin
   execute format('select public.%I($1,$2)',n) using '2026-10-01'::timestamptz,'2026-10-01'::timestamptz;
   raise exception 'INVALID_WINDOW_ACCEPTED';
  exception when sqlstate '22023' then null; end;
 end loop;
 result:=public.analytics_api_cost('2026-10-01','2026-11-01');
 if result#>>'{by_model,0,total_tokens}'<>'140' then raise exception 'TOKEN_SUM_INVALID: %',result; end if;
end $$;
reset role;
do $$ begin
 if exists(select digest from fixture_before except select md5(row_to_json(r)::text) from public.essay_ai_processing_runs r) or
    exists(select md5(row_to_json(r)::text) from public.essay_ai_processing_runs r except select digest from fixture_before) then
  raise exception 'REPORT_MUTATED_FIXTURE';
 end if;
 if exists(select 1 from public.credit_transactions) or exists(select 1 from public.essay_evaluations) or exists(select 1 from public.essay_attempts) then raise exception 'UNEXPECTED_FACT_WRITE'; end if;
end $$;
rollback;
