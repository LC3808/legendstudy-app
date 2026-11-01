-- Live read-only verification; no source rows or privileges are changed.
-- JWT claims below exist only within this rollback transaction, not real sessions.
begin read only;
do $$declare u uuid;n uuid;p record;begin
 select a.user_id into strict u from public.admin_users a where account_private.allowed(a.user_id) limit 1;
 select id into n from auth.users where id not in(select user_id from public.admin_users) and account_private.allowed(id) limit 1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform set_config('request.jwt.claim.sub',u::text,true);
 perform set_config('test.normal',coalesce(n,'00000000-0000-4000-8000-000000000000'::uuid)::text,true);
 for p in select oid,prosecdef,provolatile,proconfig from pg_proc where pronamespace='public'::regnamespace and (proname like 'analytics_%' or proname='admin_learning_analytics' or (proname='admin_essay_operations' and pronargs=5)) loop
 assert p.prosecdef and p.provolatile='s';
 assert p.proconfig @> array['search_path=""'];
 assert has_function_privilege('authenticated',p.oid,'execute');
 assert not has_function_privilege('anon',p.oid,'execute');
 assert not has_function_privilege('service_role',p.oid,'execute');
 end loop;
 assert not has_schema_privilege('authenticated','essay_ops_private','usage');
 assert not has_schema_privilege('authenticated','analytics_private','usage');
 assert to_regprocedure('public.admin_essay_operations(integer,text,timestamptz)') is not null;
 assert to_regprocedure('public.admin_essay_operations_estimate()') is null;
 assert to_regclass('essay_ops_private.access_log') is null;
end$$;
set local role authenticated;
do $$declare n text;r jsonb;outcome jsonb='{}';begin
 assert public.admin_operator();
 perform public.analytics_admin_check();
 foreach n in array array['analytics_kpi_overview','analytics_funnel','analytics_free_credit','analytics_revenue','analytics_reliability','analytics_api_cost','analytics_university_usage','admin_learning_analytics','admin_essay_operations'] loop
 execute format('select public.%I($1,$2)',n) into r using '2026-10-01T00:00:00+09'::timestamptz,'2026-11-02T00:00:00+09'::timestamptz;
 assert r is not null;
 outcome:=outcome||jsonb_build_object(n,'PASS');
 end loop;
 perform set_config('test.readonly_results',outcome::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.normal'),'role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform set_config('request.jwt.claim.sub',current_setting('test.normal'),true);
 assert not public.admin_operator();
 foreach n in array array['analytics_kpi_overview','analytics_funnel','analytics_free_credit','analytics_revenue','analytics_reliability','analytics_api_cost','analytics_university_usage','admin_learning_analytics','admin_essay_operations'] loop
 begin execute format('select public.%I($1,$2)',n) using '2026-10-01'::timestamptz,'2026-11-02'::timestamptz;
 raise exception 'NONADMIN_ACCEPTED %',n;
 exception when insufficient_privilege or sqlstate 'PT403' then null;end;
 end loop;
end$$;
select jsonb_build_object('transaction_read_only',current_setting('transaction_read_only'),'reports',current_setting('test.readonly_results')::jsonb,'nonadmin_denials',9,'anon_service_acl','DENIED','private_views','DENIED','old_operations_overload','PRESERVED') as verification;
rollback;
