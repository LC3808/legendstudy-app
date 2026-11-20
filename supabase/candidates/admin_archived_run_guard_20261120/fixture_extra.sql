-- Local synthetic fixture only; minimal columns used by the exact captured RPCs.
create table essay_exam_private.retry_requests(
 run_id uuid references essay_exam_private.runs on delete cascade,
 request_key uuid not null,generation integer not null,attempts jsonb not null,
 created_at timestamptz not null default clock_timestamp(),
 lease_until timestamptz not null default clock_timestamp()+interval '15 minutes',
 primary key(run_id,request_key),unique(run_id,generation));
create table public.credit_grants(id uuid primary key,origin text);
alter table public.credit_transactions add column created_at timestamptz default now(),add column transaction_type text default 'reserve',add column grant_id uuid;
alter table essay_ops_private.calls add column call_id text,add column called_at timestamptz,add column provider text,add column model text,
 add column input_tokens bigint,add column output_tokens bigint,add column total_tokens bigint,add column cached_tokens bigint,
 add column duration_seconds numeric,add column actual_usd numeric,add column recorded_estimate_usd numeric,add column call_state text,
 add column attempt integer,add column stage text,add column price_id uuid,add column cost_status text,add column cost_usd numeric;
create table public.essay_questions(id uuid primary key,essay_exam_id uuid,label text,display_order integer);
create view essay_ops_private.run_facts as select r.id evaluation_id,r.exam_id,r.parent_id,r.created_at,r.completed_at,r.state,
 null::uuid university_id,'합성대'::text university,'합성 시험'::text exam_name,null::numeric duration_seconds,'humanities'::text evaluation_type,
 (select count(*) from essay_exam_private.retry_requests t where t.run_id=r.id) retry_count,
 (select count(*) from essay_exam_private.checkpoints c where c.run_id=r.id and c.state='checkpoint' and c.payload->>'state'='failed') failed_questions,
 '[]'::jsonb questions,'[]'::jsonb failure_codes,1::bigint reserved,0::bigint consumed,0::bigint released,0::bigint refunded,
 '["apple_purchase"]'::jsonb credit_sources,false recovery_pending,false duplicate_suspected from essay_exam_private.runs r;
revoke all on all tables in schema essay_exam_private,essay_ops_private,math_private,feedback_private from public,authenticated,anon,essay_worker,service_role;
