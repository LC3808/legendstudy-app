-- READ ONLY. Run against LegendStudy only; retain output privately for comparison.
select current_database(), now(), to_regnamespace('support_private') as candidate_already_installed;
select 'feedback' source,count(*) rows,md5(coalesce(string_agg(md5(row_to_json(t)::text),'' order by id),'')) digest from public.feedback_submissions t
union all select 'inquiries',count(*),md5(coalesce(string_agg(md5(row_to_json(t)::text),'' order by id),'')) from public.inquiries t;
-- For child rows exclude the new additive column, so before/after hashes are comparable.
select 'replies' kind,count(*) rows,md5(coalesce(string_agg(md5((to_jsonb(t)-'feedback_id')::text),'' order by id),'')) digest from public.inquiry_replies t
union all select 'events',count(*),md5(coalesce(string_agg(md5((to_jsonb(t)-'feedback_id')::text),'' order by id),'')) from public.inquiry_status_events t;
select status,count(*) from public.inquiry_notifications group by status;
select p.oid::regprocedure routine,md5(pg_get_functiondef(p.oid)) definition_hash from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('inquiry_submit','inquiry_mine','admin_inquiry_list','admin_inquiry_detail','admin_inquiry_reply','admin_inquiry_set_status','claim_inquiry_notifications','admin_operator');
select relname,relrowsecurity from pg_class where oid in ('public.inquiry_replies'::regclass,'public.inquiry_notifications'::regclass,'public.inquiry_status_events'::regclass);

select to_regprocedure('public.account_service_allowed()') is not null as lifecycle_dependency_required;
