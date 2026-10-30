-- Run AFTER apply.sql. Read-only verification of the created surface.
-- NOTE: SQL Editor SET ROLE is NOT authoritative RLS/authorization evidence
-- (wiki). Verify non-admin rejection with a real authenticated (non-admin) JWT
-- over REST: each function must return HTTP 40x / 'OPERATOR_REQUIRED'.
begin read only;

do $$
declare fn text; missing text := ''; target oid;
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
    target := to_regprocedure(fn);
    if target is null then
      missing := missing||fn||' ';
    else
      if has_function_privilege('anon',target,'EXECUTE')
         or has_function_privilege('service_role',target,'EXECUTE')
         or not has_function_privilege('authenticated',target,'EXECUTE') then
        raise exception 'INVALID execute grants: %', fn;
      end if;
      if exists(select 1 from pg_proc p,
          lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
          where p.oid=target and a.grantee=0 and a.privilege_type='EXECUTE') then
        raise exception 'PUBLIC can execute: %',fn;
      end if;
      if not exists(select 1 from pg_proc p where p.oid=target
          and p.proowner='postgres'::regrole and p.prosecdef
          and exists(select 1 from unnest(p.proconfig) setting
            where setting in ('search_path=', 'search_path=""'))) then
        raise exception 'INVALID owner/security/search_path: %',fn;
      end if;
    end if;
  end loop;
  if missing <> '' then raise exception 'MISSING functions after apply: %', missing; end if;

  raise notice 'postcheck OK: 8 functions present and hardened. Now verify non-admin REST rejection with a real JWT.';
end $$;

rollback;
