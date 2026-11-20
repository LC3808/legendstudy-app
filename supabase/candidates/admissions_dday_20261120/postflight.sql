-- Read-only. Compare preserved digests with the SAME deployment's preflight receipt.
begin read only;
select jsonb_build_object(
 'table_rls',(select jsonb_object_agg(c.relname,c.relrowsecurity) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname in ('admission_schedule_events','admission_schedule_revisions','application_schedule_links','student_schedule_preferences','student_schedule_actions')),
 'rpc_acl',(select jsonb_agg(jsonb_build_object('name',p.proname,'owner',pg_get_userbyid(p.proowner),'definer',p.prosecdef,'config',p.proconfig,'anon',has_function_privilege('anon',p.oid,'EXECUTE'),'authenticated',has_function_privilege('authenticated',p.oid,'EXECUTE'))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('my_admission_day_events','my_admission_day_event_action','my_set_primary_day_target','admin_admission_schedules','admin_admission_schedule_save')),
 'schedule_counts',(select jsonb_object_agg(verification_status,n) from (select verification_status,count(*) n from public.admission_schedule_events group by verification_status) c),
 'linked_applications',(select count(distinct application_id) from public.application_schedule_links where sync_status='MATCHED'),
 'generated_day_targets',(select count(*) from public.student_schedule_preferences where status='ACTIVE' and day_target_id is not null),
 'duplicate_projections',(select count(*) from (select owner_id,official_event_id,count(*) from public.student_schedule_preferences where day_target_id is not null group by owner_id,official_event_id having count(*)>1) d),
 'applications_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.student_applications t),
 'application_events_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.student_application_events t),
 'manual_day_targets_count',(select count(*) from public.day_targets d where not exists(select 1 from public.student_schedule_preferences p where p.day_target_id=d.id)),
 'manual_day_targets_digest',(select md5(coalesce(string_agg(to_jsonb(d)::text,'|' order by d.id),'')) from public.day_targets d where not exists(select 1 from public.student_schedule_preferences p where p.day_target_id=d.id)),
 'essay_exams_digest',(select md5(coalesce(string_agg(to_jsonb(t)::text,'|' order by id),'')) from public.essay_exams t)
) as postflight;
rollback;
