-- Disable only the additive reporting surface; do not touch sources or old overloads.
begin;
revoke execute on function public.admin_learning_analytics(timestamptz,timestamptz), public.admin_essay_operations(timestamptz,timestamptz,jsonb,integer,uuid) from authenticated;
revoke execute on function public.analytics_admin_check(), public.analytics_kpi_overview(timestamptz,timestamptz), public.analytics_funnel(timestamptz,timestamptz), public.analytics_free_credit(timestamptz,timestamptz), public.analytics_revenue(timestamptz,timestamptz), public.analytics_reliability(timestamptz,timestamptz), public.analytics_api_cost(timestamptz,timestamptz), public.analytics_university_usage(timestamptz,timestamptz) from authenticated;
commit;
