-- SELECT-only. Run on LegendStudy stlhijzpjfgwwdgunlsd; stop on any mismatch.
begin read only;
select jsonb_build_object(
 'save_preimage_matches',md5(pg_get_functiondef('public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid)'::regprocedure))='65edac758433cde4a123b95be3da42ee',
 'private_schema_absent',to_regnamespace('admissions_private') is null,
 'new_tables_absent',not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in ('admission_schedule_events','admission_schedule_revisions','application_schedule_links','student_schedule_preferences','student_schedule_actions')),
 'new_rpcs_absent',not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('my_admission_day_events','my_admission_day_event_action','my_set_primary_day_target','admin_admission_schedules','admin_admission_schedule_save')),
 'application_count',(select count(*) from public.student_applications),
 'applications_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.student_applications t),
 'application_events_count',(select count(*) from public.student_application_events),
 'application_events_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.student_application_events t),
 'day_targets_count',(select count(*) from public.day_targets),
 'day_targets_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.day_targets t),
 'essay_exams_count',(select count(*) from public.essay_exams),
 'essay_exams_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.essay_exams t)
) as preflight;
rollback;
