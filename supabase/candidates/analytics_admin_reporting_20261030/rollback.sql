-- Reverts apply.sql. Drops only the analytics reporting functions this candidate
-- created. Touches no existing table, policy, or other function.
begin;
drop function if exists public.analytics_university_usage(timestamptz,timestamptz);
drop function if exists public.analytics_api_cost(timestamptz,timestamptz);
drop function if exists public.analytics_reliability(timestamptz,timestamptz);
drop function if exists public.analytics_revenue(timestamptz,timestamptz);
drop function if exists public.analytics_free_credit(timestamptz,timestamptz);
drop function if exists public.analytics_funnel(timestamptz,timestamptz);
drop function if exists public.analytics_kpi_overview(timestamptz,timestamptz);
drop function if exists public.analytics_admin_check();
commit;
