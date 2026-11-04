-- Read only. Expected new RPC absent; existing dependencies present.
select to_regprocedure('public.admin_dashboard_study(timestamptz,timestamptz)') is null as new_rpc_absent,
 to_regprocedure('public.admin_operator()') is not null as operator_check,
 to_regprocedure('account_private.allowed(uuid)') is not null as lifecycle_check,
 to_regprocedure('public.admin_learning_analytics(timestamptz,timestamptz)') is not null as fallback_present;
select table_name,column_name,data_type from information_schema.columns where table_schema='public' and table_name in ('study_sessions','profiles') order by table_name,ordinal_position;
-- Save preflight fingerprints; concurrent real activity can legitimately change them.
select count(*) records,md5(string_agg(row_to_json(s)::text,'' order by id)) fingerprint from public.study_sessions s;
