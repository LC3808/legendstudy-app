-- READ ONLY. Execute preflight.sql again first and compare source/child digests.
select to_regnamespace('support_private') is not null as installed;
select has_function_privilege('anon','public.support_admin_list(jsonb)','execute') as must_be_false,
 has_function_privilege('authenticated','public.claim_support_notifications(integer)','execute') as must_be_false_worker,
 has_function_privilege('authenticated','public.support_admin_list(jsonb)','execute') as must_be_true;
select source,id,category,title,created_at,status,reply_count from support_private.items
where id='65f48fbf-c386-4491-aef0-b697b6952356';
select source,status,count(*) from support_private.items group by source,status;
select count(*) as must_be_zero from public.inquiries where id='65f48fbf-c386-4491-aef0-b697b6952356';
select count(*) as must_be_zero from public.inquiry_replies where feedback_id='65f48fbf-c386-4491-aef0-b697b6952356';
-- Owner must also verify with their normal browser JWT, never a fabricated SQL JWT.
