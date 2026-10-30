-- Run AFTER apply.sql. Read-only verification of the created surface.
-- NOTE: SQL Editor SET ROLE is NOT authoritative RLS/authorization evidence
-- (wiki). Verify non-admin rejection with a real authenticated (non-admin) JWT
-- over REST: each function must return HTTP 40x / 'OPERATOR_REQUIRED'.
begin read only;

do $$
declare fn text; missing text := '';
begin
  foreach fn in array array[
    'public.analytics_admin_check()',
    'public.analytics_kpi_overview(timestamptz,timestamptz)',
    'public.analytics_funnel(timestamptz,timestamptz)',
    'public.analytics_free_credit(timestamptz,timestamptz)',
    'public.analytics_revenue(timestamptz,timestamptz)',
    'public.analytics_reliability(timestamptz,timestamptz)',
    'public.analytics_api_cost(timestamptz,timestamptz)',
    'public.analytics_university_usage(timestamptz,timestamptz)'
  ] loop
    if to_regprocedure(fn) is null then missing := missing||fn||' '; end if;
  end loop;
  if missing <> '' then raise exception 'MISSING functions after apply: %', missing; end if;

  -- All must be SECURITY DEFINER with empty search_path, owned by postgres,
  -- and NOT executable by anon/public.
  perform 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname like 'analytics\_%' escape '\'
      and (not p.prosecdef or p.proconfig is null or not ('search_path=' = any(p.proconfig)));
  if found then raise exception 'an analytics_* function is not security-definer/empty-search_path'; end if;

  raise notice 'postcheck OK: 8 functions present and hardened. Now verify non-admin REST rejection with a real JWT.';
end $$;

rollback;
