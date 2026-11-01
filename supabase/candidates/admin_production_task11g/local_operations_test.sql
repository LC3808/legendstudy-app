-- Disposable empty local DB ONLY; first install TASK06 local_fixture.sql and operations_readonly.sql.
\set ON_ERROR_STOP on
-- Sentinel bodies must never leave narrow projections.
insert into public.universities values('10000000-0000-4000-8000-000000000001','Fixture University');
insert into public.essay_exams values('10000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','Fixture Exam');
insert into essay_exam_private.runs
select ('20000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'10000000-0000-4000-8000-000000000002',case when i=4 then '20000000-0000-4000-8000-000000000001'::uuid end,('30000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
'2026-10-30T15:00Z'::timestamptz,case when i<>3 then '2026-10-30T15:02Z'::timestamptz end,case when i=2 then 'failed' when i=3 then 'reserved' else 'completed' end,
'{"evaluationType":"humanities","answers":[{"questionId":"ffffffff-0000-4000-8000-000000000001","body":"PRIVATE_ANSWER_SENTINEL"},{"questionId":"00000000-0000-4000-8000-000000000001","body":"PRIVATE_ANSWER_SENTINEL"}]}'::jsonb
from generate_series(1,4)i;
insert into essay_exam_private.retry_requests values('20000000-0000-4000-8000-000000000003',gen_random_uuid(),1,'{"0":1}','2026-10-30T15:01Z',null);
insert into essay_exam_private.checkpoints values
('20000000-0000-4000-8000-000000000003','q0','checkpoint','{"state":"failed"}'),
('20000000-0000-4000-8000-000000000003','q0-retry-1','checkpoint','{"state":"failed"}'),
('20000000-0000-4000-8000-000000000003','q1','checkpoint','{"state":"completed","answer":"PRIVATE_ANSWER_SENTINEL"}'),
('20000000-0000-4000-8000-000000000003','q0-a1-execution-failure','checkpoint','{"component":"execution_failure","stage":"provider","code":"PROVIDER_HTTP_ERROR","http_status":429,"raw":"SECRET_SENTINEL"}'),
('20000000-0000-4000-8000-000000000001','q0-a0-receipt-a','checkpoint','{"provider":"fixture","model":"fixture","input_tokens":100,"output_tokens":20,"total_tokens":120,"latency_ms":1000,"cost_amount":10,"raw":"SECRET_SENTINEL"}'),
('20000000-0000-4000-8000-000000000001','q0-a0-review','checkpoint','{"component":"independent_review","telemetry":{"p_input_tokens":1000}}'),
('20000000-0000-4000-8000-000000000001','q0-a0-receipt-review','checkpoint','{"component":"independent_review","telemetry":{"p_input_tokens":1000,"p_output_tokens":20,"p_latency_ms":1000},"assessment":"PRIVATE_ANSWER_SENTINEL"}');
insert into public.credit_grants select ('40000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,case i when 1 then 'purchase' when 2 then 'signup_bonus' else 'essay_beta_daily' end from generate_series(1,3)i;
insert into public.credit_transactions select gen_random_uuid(),g.id,('30000000-0000-4000-8000-'||right(g.id::text,12))::uuid,'reserve',0,1,'2026-10-30T15:00Z' from public.credit_grants g;
insert into public.credit_transactions select gen_random_uuid(),g.id,('30000000-0000-4000-8000-'||right(g.id::text,12))::uuid,case when g.origin='purchase' then 'consume' else 'release' end,case when g.origin='purchase' then -1 else 0 end,-1,'2026-10-30T15:02Z' from public.credit_grants g where origin<>'essay_beta_daily';
insert into public.essay_ai_processing_runs values
('50000000-0000-4000-8000-000000000001',gen_random_uuid(),'2026-10-30T15:00Z','fixture','fixture',1000000,1000000,2000,null,null,null,'completed',0),
('50000000-0000-4000-8000-000000000002',gen_random_uuid(),'2026-10-30T14:59Z','fixture','fixture',10,20,1000,'provider_reported','USD',0.1,'completed',0);
create temp table baseline as select md5((select jsonb_agg(to_jsonb(r))::text from essay_exam_private.runs r)||(select jsonb_agg(to_jsonb(t))::text from public.credit_transactions t)||(select jsonb_agg(to_jsonb(c))::text from essay_exam_private.checkpoints c)) hash;
set test.actor='90000000-0000-4000-8000-000000000001';set test.admin='true';
do $$declare x jsonb;n int;p uuid;begin
 x:=public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{}',0,'20000000-0000-4000-8000-000000000003');
 assert x->>'total'='4'; assert (x#>>'{summary,success_rate}')::numeric between 66.66 and 66.67;
 assert x#>>'{summary,processing}'='1';assert x#>>'{summary,retry_pending}'='1';assert x#>>'{summary,p95_seconds}'='120';
 assert x#>>'{cost_coverage,receipts}'='2';assert x#>>'{cost_coverage,unknown}'='2';
 assert x#>>'{detail,run,questions,0,question_id}'='ffffffff-0000-4000-8000-000000000001';assert x#>>'{detail,run,questions,1,state}'='completed';
 assert x#>>'{detail,diagnostics,0,http_status}'='429';
 assert x::text not like '%SENTINEL%';assert x#>>'{summary,consumed}'='1';assert x#>>'{summary,released}'='1';assert x->>'free_rewrite_count'='1';
 assert jsonb_array_length(x->'credit_groups')=3;
 assert (public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{"issues":true}')->>'total')='2';
 assert (public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{"source":"free_rewrite"}')->>'total')='1';
 assert (public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{"type":"math"}')->>'total')='0';
 assert (public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{"source":"paid"}')->>'total')='1';
 assert (public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z','{"retry":true}')->>'total')='1';
 assert (select count(*)=1 from essay_ops_private.calls where cost_status='ACTUAL');
 assert x->>'read_only'='true';
 assert (select hash=md5((select jsonb_agg(to_jsonb(r))::text from essay_exam_private.runs r)||(select jsonb_agg(to_jsonb(t))::text from public.credit_transactions t)||(select jsonb_agg(to_jsonb(c))::text from essay_exam_private.checkpoints c)) from baseline);
end$$;
begin read only;
set role authenticated;
select public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z')->>'total' as owner_visible;
set test.admin='false';
do $$begin begin perform public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z');raise exception 'NONADMIN_ACCEPTED';exception when insufficient_privilege then null;end;end$$;
set test.admin='true';set test.allowed='false';
do $$begin begin perform public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z');raise exception 'DISALLOWED_ACCEPTED';exception when insufficient_privilege then null;end;end$$;
reset role;
set test.actor='';set test.allowed='true';
do $$begin begin perform public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z');raise exception 'UNAUTHENTICATED_ACCEPTED';exception when insufficient_privilege then null;end;end$$;
set role anon;
do $$begin begin perform public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z');raise exception 'ANON_ACCEPTED';exception when insufficient_privilege then null;end;end$$;
reset role;
set role service_role;
do $$begin begin perform public.admin_essay_operations('2026-10-30T15:00Z','2026-10-31T15:00Z');raise exception 'SERVICE_ACCEPTED';exception when insufficient_privilege then null;end;end$$;
reset role;
do $$begin
 assert to_regprocedure('public.admin_essay_operations_estimate()') is null;
 assert to_regclass('essay_ops_private.access_log') is null;
 assert not has_schema_privilege('authenticated','essay_ops_private','usage');
end$$;
rollback;
select 'TASK11G READONLY LOCAL PASS' as result;
