select jsonb_build_object(
'checked_at_kst',to_char(clock_timestamp() at time zone 'Asia/Seoul','YYYY-MM-DD HH24:MI:SS'),
'candidate_relations',(select coalesce(jsonb_agg(relname),'[]') from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and relname in ('home_configuration_revisions','university_official_sources','university_news_revisions')),
'candidate_functions',(select coalesce(jsonb_agg(p.oid::regprocedure::text),'[]') from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('my_home_configuration','save_my_home_configuration','university_news_feed','task04_news_immutable')),
'lifecycle',(select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'hash',md5(pg_get_functiondef(p.oid)))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where (n.nspname='account_private' and p.proname in ('allowed','lock_subject')) or (n.nspname='public' and p.proname='account_service_allowed')),
'parents',(select jsonb_agg(jsonb_build_object('schema',table_schema,'table',table_name,'column',column_name,'type',data_type)) from information_schema.columns where (table_schema='auth' and table_name='users' and column_name='id') or (table_schema='public' and table_name='universities' and column_name in ('id','name'))),
'candidate_data_tables',(select jsonb_agg(jsonb_build_object('table',schemaname||'.'||relname,'estimated_rows',n_live_tup)) from pg_stat_user_tables where schemaname='public' and (relname in ('profiles','student_applications','student_application_events','account_deletion_requests','day_targets') or relname like 'study_%' or relname like '%scoring%')),
'lifecycle_denied_existing',(select count(*) from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING')),
'lifecycle_false_negative',(select count(*) from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING') and account_private.allowed(subject_id))
) as preflight;
