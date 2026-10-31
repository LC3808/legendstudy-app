-- Analytics Admin Reporting v1 — Owner-apply. READ-ONLY aggregates over existing
-- tables. No schema change to existing tables, no new fact/event table, no change
-- to evaluation/credit/payment contracts. Every function is admin-gated and
-- security definer with an empty search_path. PostgreSQL stays the official SoT.
begin;

-- TASK08: one exam run is one request, never one request per answer/checkpoint.
-- Projection only. Source rows, snapshots, ledgers and identities stay immutable.
create schema if not exists analytics_private;
revoke all on schema analytics_private from public,anon,authenticated,service_role;
create or replace view analytics_private.sessions as
 select s.id,s.user_id,s.question_id,s.created_at from public.essay_practice_sessions s
 where not exists(select 1 from essay_exam_private.runs r where r.id=s.id)
 union all select r.id,a.user_id,null::uuid,r.created_at from essay_exam_private.runs r
 join public.credit_accounts a on a.id=r.account_id;
create or replace view analytics_private.attempts as
 select a.id,a.session_id,a.attempt_no,a.submitted_at from public.essay_attempts a
 where not exists(select 1 from essay_exam_private.runs r where r.id=a.id)
 union all select r.id,r.id,case when r.parent_id is null then 1 else 2 end,r.created_at from essay_exam_private.runs r;
create or replace view analytics_private.evaluations as
 select e.id,e.attempt_id,e.session_id,e.question_id,e.status::text,e.request_kind::text,e.requested_at,e.completed_at,e.error_code::text
 from public.essay_evaluations e where not exists(select 1 from essay_exam_private.runs r where r.id=e.id)
 union all select r.id,r.id,r.id,null::uuid,r.state::text,'student',r.created_at,r.completed_at,
 (select case when count(distinct c.payload->>'code')=1 then max(c.payload->>'code') end from essay_exam_private.checkpoints c where c.run_id=r.id and c.state='checkpoint'
   and c.payload->>'component' in ('execution_failure','validation_failure')
   and c.payload->>'code' ~ '^[A-Z_0-9]{1,80}$')
 from essay_exam_private.runs r;
revoke all on all tables in schema analytics_private from public,anon,authenticated,service_role;

-- Caller gate helper, mirroring the existing operational admin surface
-- (public.admin_member_list). Reused by the Flutter dashboard for its entry gate.
create or replace function public.analytics_admin_check() returns boolean
language sql stable security definer set search_path='' as $$
  select coalesce(auth.uid() is not null and public.admin_operator() and account_private.allowed((select auth.uid())), false)
$$;

-- Shared window guard (inlined per function; no state).
-- [p_from, p_to); bounded to <= 400 days.

------------------------------------------------------------------------------
create or replace function public.analytics_kpi_overview(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with activity as (
    select s.user_id, a.submitted_at as ts
      from analytics_private.attempts a join analytics_private.sessions s on s.id=a.session_id
    union all
    select s.user_id, e.completed_at as ts
      from analytics_private.evaluations e join analytics_private.sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student' and e.completed_at is not null
  ),
  completed as (
    select distinct s.user_id
      from analytics_private.evaluations e join analytics_private.sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student'
        and e.completed_at>=p_from and e.completed_at<p_to
  ),
  free_completed as (
    select distinct s.user_id
      from analytics_private.evaluations e join analytics_private.sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student'
        and e.completed_at>=p_from and e.completed_at<p_to
        and (
          exists(select 1 from public.essay_billing_decisions d where (d.evaluation_id=e.id or d.id=(select r.decision_id from essay_exam_private.runs r where r.id=e.id)) and d.reason='included_revision')
          or exists(
            select 1 from public.essay_billing_decisions d
              join public.credit_transactions t on t.decision_id=d.id and t.transaction_type='consume'
              join public.credit_grants g on g.id=t.grant_id
             where (d.evaluation_id=e.id or d.id=(select r.decision_id from essay_exam_private.runs r where r.id=e.id)) and g.origin in ('signup_bonus','promotion','compensation','b2b_program','essay_beta_daily')
          )
        )
  ),
  paid as (
    select subject_id, amount from public.payment_orders
     where paid_at is not null and currency='KRW' and mode='LIVE' and paid_at>=p_from and paid_at<p_to and subject_id is not null
  ),
  student_evals as (
    select status from analytics_private.evaluations
     where request_kind='student' and requested_at>=p_from and requested_at<p_to
  )
  select jsonb_build_object(
    'version','analytics-kpi-v1','as_of',statement_timestamp(),
    'from',p_from,'to',p_to,
    'active_learners', jsonb_build_object(
      'dau',(select count(distinct user_id) from activity where ts>=p_to-interval '1 day' and ts<p_to),
      'wau',(select count(distinct user_id) from activity where ts>=p_to-interval '7 days' and ts<p_to),
      'mau',(select count(distinct user_id) from activity where ts>=p_to-interval '30 days' and ts<p_to),
      'basis','server_learning_activity'
    ),
    'new_signups',(select count(*) from auth.users where created_at>=p_from and created_at<p_to),
    'completed_eval_users',(select count(*) from completed),
    'free_eval_completed_users',(select count(*) from free_completed),
    'paid_buyers',(select count(distinct subject_id) from paid),
    'revenue_krw',(select coalesce(sum(amount),0) from paid),
    'eval_success_rate', (
      select case when count(*) filter (where status in ('completed','failed'))=0 then null
        else round(100.0*count(*) filter (where status='completed')
          /count(*) filter (where status in ('completed','failed')),1) end
      from student_evals)
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_funnel(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with signups as (
    select id as user_id from auth.users where created_at>=p_from and created_at<p_to
  ),
  first_submit as (
    select distinct s.user_id
      from analytics_private.attempts a join analytics_private.sessions s on s.id=a.session_id
      join signups u on u.user_id=s.user_id
  ),
  first_completed as (
    select distinct s.user_id
      from analytics_private.evaluations e join analytics_private.sessions s on s.id=e.session_id
      join signups u on u.user_id=s.user_id
      where e.status='completed' and e.request_kind='student'
  ),
  rewrote as (
    select distinct s.user_id
      from analytics_private.attempts a join analytics_private.sessions s on s.id=a.session_id
      join signups u on u.user_id=s.user_id
      where a.attempt_no>=2
  ),
  full_loop as (
    -- first attempt completed, then a later attempt (>=2) in the same session completed
    select distinct s1.user_id
      from analytics_private.sessions s1
      join signups u on u.user_id=s1.user_id
      join analytics_private.attempts a1 on a1.session_id=s1.id and a1.attempt_no=1
      join analytics_private.evaluations e1 on e1.attempt_id=a1.id and e1.status='completed' and e1.request_kind='student'
      join analytics_private.attempts a2 on a2.session_id=s1.id and a2.attempt_no>=2
      join analytics_private.evaluations e2 on e2.attempt_id=a2.id and e2.status='completed' and e2.request_kind='student'
    union
    select ca.user_id from essay_exam_private.runs child
    join essay_exam_private.runs parent on parent.id=child.parent_id and parent.account_id=child.account_id and parent.exam_id=child.exam_id
    join public.credit_accounts ca on ca.id=child.account_id join signups u on u.user_id=ca.user_id
    where parent.state='completed' and child.state='completed'

  )
  select jsonb_build_object(
    'version','analytics-funnel-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'note','Counts cohort by signup in window; later stages measured over all time for that cohort.',
    'stages', jsonb_build_array(
      jsonb_build_object('key','signup','count',(select count(*) from signups)),
      jsonb_build_object('key','first_submit','count',(select count(*) from first_submit)),
      jsonb_build_object('key','first_eval_completed','count',(select count(*) from first_completed)),
      jsonb_build_object('key','rewrite_submit','count',(select count(*) from rewrote)),
      jsonb_build_object('key','full_loop_nsm','count',(select count(*) from full_loop))
    )
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_free_credit(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with free_grant as (
    select g.account_id, g.id as grant_id
      from public.credit_grants g
      where g.origin='signup_bonus' and g.created_at>=p_from and g.created_at<p_to
  ),
  granted_units as (
    select t.account_id, sum(t.balance_delta) as units
      from public.credit_transactions t
      join free_grant fg on fg.grant_id=t.grant_id
      where t.transaction_type='signup_bonus'
      group by t.account_id
  ),
  used as (
    select t.account_id, -sum(t.balance_delta) as used_units
      from public.credit_transactions t
      join free_grant fg on fg.grant_id=t.grant_id
      where t.transaction_type='consume'
      group by t.account_id
  ),
  per_account as (
    select gu.account_id, gu.units as granted, coalesce(u.used_units,0) as used
      from granted_units gu left join used u on u.account_id=gu.account_id
  ),
  paid_accounts as (
    select distinct ca.id as account_id
      from public.payment_orders po
      join public.credit_accounts ca on ca.user_id=po.subject_id
      where po.paid_at is not null and po.mode='LIVE'
  )
  select jsonb_build_object(
    'version','analytics-free-credit-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'granted_users',(select count(*) from per_account),
    'used_users',(select count(*) from per_account where used>0),
    'avg_used_per_user',(select round(avg(used),2) from per_account),
    'dropoff_after_1',(select count(*) from per_account where used=1),
    'dropoff_after_2',(select count(*) from per_account where used=2),
    'dropoff_after_3',(select count(*) from per_account where used>=3),
    'exhausted_users',(select count(*) from per_account where used>=granted and granted>0),
    'free_to_paid_users',(select count(*) from per_account pa where exists(select 1 from paid_accounts p where p.account_id=pa.account_id))
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_revenue(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with paid as (
    select id, subject_id, sku, amount from public.payment_orders
     where paid_at is not null and currency='KRW' and mode='LIVE' and paid_at>=p_from and paid_at<p_to
  ),
  refunds as (
    select coalesce(sum(op.amount),0) as refunded
      from public.payment_operations op
      join public.payment_orders po on po.id=op.order_id
      where op.kind='CANCEL' and op.state='SUCCEEDED' 
        and po.mode='LIVE' and po.currency='KRW' and op.completed_at>=p_from and op.completed_at<p_to
  ),
  by_sku as (
    select sku, count(*) as orders, coalesce(sum(amount),0) as revenue
      from paid group by sku
  ),
  buyers as (select count(distinct subject_id) as n from paid),
  repeat_buyers as (
    select count(*) as n from (select subject_id from paid group by subject_id having count(*)>1) r
  )
  select jsonb_build_object(
    'version','analytics-revenue-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'currency','KRW','mode','LIVE',
    'currency_policy','KRW only; no FX conversion. Other currencies excluded.',
    'excluded_currency_orders',(select count(*) from public.payment_orders where mode='LIVE' and paid_at>=p_from and paid_at<p_to and currency is distinct from 'KRW'),
    'credit_released_units',(select coalesce(-sum(reserved_delta),0) from public.credit_transactions where transaction_type='release' and created_at>=p_from and created_at<p_to),
    'credit_refunded_units',(select coalesce(sum(balance_delta),0) from public.credit_transactions where transaction_type='refund' and created_at>=p_from and created_at<p_to),
    'gross_revenue',(select coalesce(sum(amount),0) from paid),
    'paid_orders',(select count(*) from paid),
    'buyers',(select n from buyers),
    'repeat_buyers',(select n from repeat_buyers),
    'aov',(select case when count(*)=0 then null else round(sum(amount)::numeric/count(*),0) end from paid),
    'arppu',(select case when (select n from buyers)=0 then null else round((select sum(amount) from paid)::numeric/(select n from buyers),0) end),
    'refunded',(select refunded from refunds),
    'net_revenue',(select coalesce(sum(amount),0) from paid)-(select refunded from refunds),
    'by_sku',(select coalesce(jsonb_agg(jsonb_build_object('sku',sku,'orders',orders,'revenue',revenue) order by sku),'[]'::jsonb) from by_sku)
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_reliability(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with ev as (
    select * from analytics_private.evaluations
     where request_kind='student' and requested_at>=p_from and requested_at<p_to
  ),
  runs as (
    select r.* from public.essay_ai_processing_runs r
      join analytics_private.evaluations e on e.id=r.evaluation_id
      where e.requested_at>=p_from and e.requested_at<p_to
  ),
  fail_by_question as (
    select q.question_key, ex.exam_key, count(*) as failures
      from ev e
      join public.essay_questions q on q.id=e.question_id
      join public.essay_exams ex on ex.id=q.essay_exam_id
      where e.status='failed'
      group by q.question_key, ex.exam_key
      order by failures desc limit 20
  ),
  err as (
    select coalesce(error_code,'unknown') as code, count(*) as n
      from ev where status='failed' group by coalesce(error_code,'unknown')
  )
  select jsonb_build_object(
    'version','analytics-reliability-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'requested',(select count(*) from ev),
    'completed',(select count(*) from ev where status='completed'),
    'failed',(select count(*) from ev where status='failed'),
    'cancelled',(select count(*) from ev where status='cancelled'),
    'processing',(select count(*) from ev where status in ('requested','processing','reserved')),
    'reprocess_requested',(select count(*) from runs where run_no>1 and not exists(select 1 from essay_exam_private.runs x where x.id=runs.evaluation_id)) + (select count(*) from essay_exam_private.retry_requests rr join ev on ev.id=rr.run_id),
    'exam_reprocess_outcome','Individual generation success not inferred from current run state',
    'reprocess_success',(select count(*) from runs where run_no>1 and status='completed' and not exists(select 1 from essay_exam_private.runs x where x.id=runs.evaluation_id)),
    'exam_runs_completed_after_retry',(select count(*) from ev where status='completed' and exists(select 1 from essay_exam_private.retry_requests rr where rr.run_id=ev.id)),
    'latency_scope','legacy provider calls only; use operations dashboard for exam run duration',
    'question_failure_scope','legacy evaluations only; exam checkpoint failures are in operations dashboard',
    'error_code_scope','exam diagnostic code only when unambiguous across recorded failures',
    'latency_ms_p50',(select percentile_cont(0.5) within group (order by latency_ms) from runs where status='completed' and latency_ms is not null),
    'latency_ms_p95',(select percentile_cont(0.95) within group (order by latency_ms) from runs where status='completed' and latency_ms is not null),
    'failures_by_question',(select coalesce(jsonb_agg(jsonb_build_object('exam',exam_key,'question',question_key,'failures',failures)),'[]'::jsonb) from fail_by_question),
    'error_types',(select coalesce(jsonb_agg(jsonb_build_object('code',code,'count',n) order by n desc),'[]'::jsonb) from err),
    'credit_integrity', jsonb_build_object(
      'A_failed_but_settled',(select count(*) from ev e where e.status='failed'
        and exists(select 1 from public.essay_billing_decisions d where (d.evaluation_id=e.id or d.id=(select r.decision_id from essay_exam_private.runs r where r.id=e.id)) and d.status='settled')),
      'E_included_but_consumed',(select count(*) from public.essay_billing_decisions d
        where d.reason='included_revision' and d.created_at>=p_from and d.created_at<p_to
        and exists(select 1 from public.credit_transactions t where t.decision_id=d.id and t.transaction_type='consume')),
      'F_paid_but_not_settled',(select count(*) from public.essay_billing_decisions d
        where d.reason='paid_cycle' and d.created_at>=p_from and d.created_at<p_to and d.status not in ('settled','released','rejected'))
    )
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_api_cost(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with runs as (
    select c.*,c.model model_name,c.attempt run_no,c.cost_usd cost_amount,
      case when c.cost_status='ACTUAL' then 'provider_reported' else c.cost_status end cost_basis,
      c.called_at started_at, case when r.parent_id is not null then r.id end rewrite_id
    from essay_ops_private.calls c left join essay_exam_private.runs r on r.id=c.evaluation_id
    where (c.called_at>=p_from and c.called_at<p_to)
       or (c.called_at is null and r.created_at>=p_from and r.created_at<p_to)
  ),
  by_model as (
    select provider, model_name,
      count(*) as calls,
      sum(case when run_no>1 then 1 else 0 end) as reprocess_calls,
      sum(coalesce(input_tokens,0)) as input_tokens,
      sum(coalesce(output_tokens,0)) as output_tokens,
      sum(input_tokens + output_tokens) as total_tokens,
      sum(cost_amount) filter (where cost_basis='provider_reported') as reported_cost,
      count(*) filter (where cost_amount is null) as cost_missing
      from runs group by provider, model_name
  ),
  daily as (
    select date_trunc('day', started_at at time zone 'Asia/Seoul') as day,
      sum(cost_amount) filter (where cost_basis='provider_reported') as reported_cost,
      count(*) as calls
      from runs where started_at is not null group by date_trunc('day', started_at at time zone 'Asia/Seoul') order by day
  )
  select jsonb_build_object(
    'version','analytics-api-cost-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'currency','USD',
    'note','ACTUAL/ESTIMATED known USD subtotals only; UNKNOWN is not zero. Undated exam receipts use request cohort, not daily call date.',
    'actual_calls',(select count(*) from runs where cost_status='ACTUAL'),
    'estimated_calls',(select count(*) from runs where cost_status='ESTIMATED'),
    'unknown_calls',(select count(*) from runs where cost_status='UNKNOWN'),
    'undated_calls',(select count(*) from runs where started_at is null),
    'total_estimated_cost',(select sum(cost_amount) from runs where cost_status='ESTIMATED'),
    'eval_calls',(select count(*) from runs where evaluation_id is not null),
    'rewrite_calls',(select count(*) from runs where rewrite_id is not null),
    'reprocess_calls',(select count(*) from runs where run_no>1),
    'total_reported_cost',(select sum(cost_amount) from runs where cost_basis='provider_reported'),
    'cost_missing_runs',(select count(*) from runs where cost_amount is null),
    'by_model',(select coalesce(jsonb_agg(jsonb_build_object(
        'provider',provider,'model',model_name,'calls',calls,'reprocess_calls',reprocess_calls,
        'input_tokens',input_tokens,'output_tokens',output_tokens,'total_tokens',total_tokens,
        'reported_cost',reported_cost,'cost_missing',cost_missing) order by calls desc),'[]'::jsonb) from by_model),
    'daily',(select coalesce(jsonb_agg(jsonb_build_object('day',day,'reported_cost',reported_cost,'calls',calls) order by day),'[]'::jsonb) from daily)
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
create or replace function public.analytics_university_usage(
  p_from timestamptz, p_to timestamptz
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
  if public.analytics_admin_check() is not true then
    raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
  end if;
  if p_from is null or p_to is null or p_to<=p_from or p_to-p_from>interval '400 days' then
    raise sqlstate '22023' using message='INVALID_WINDOW';
  end if;
  with source_usage as (
    select u.id university_id,u.name university_name,count(distinct s.id) sessions,count(distinct a.id) attempts,
      count(distinct e.id) filter(where e.status='completed' and e.request_kind='student') completed
    from public.essay_practice_sessions s join public.essay_questions q on q.id=s.question_id
    join public.essay_exams ex on ex.id=q.essay_exam_id join public.universities u on u.id=ex.university_id
    left join analytics_private.attempts a on a.session_id=s.id and a.submitted_at>=p_from and a.submitted_at<p_to
    left join analytics_private.evaluations e on e.session_id=s.id and e.completed_at>=p_from and e.completed_at<p_to
    group by u.id,u.name having count(distinct a.id)>0 or count(distinct e.id)>0
    union all
    select u.id,u.name,count(*),count(*) filter(where r.created_at>=p_from and r.created_at<p_to),
      count(*) filter(where r.state='completed' and r.completed_at>=p_from and r.completed_at<p_to)
    from essay_exam_private.runs r join public.essay_exams ex on ex.id=r.exam_id join public.universities u on u.id=ex.university_id
    where (r.created_at>=p_from and r.created_at<p_to) or (r.completed_at>=p_from and r.completed_at<p_to)
    group by u.id,u.name
  ), usage as (
    select university_id,university_name,sum(sessions) sessions,sum(attempts) attempts,sum(completed) completed
    from source_usage group by university_id,university_name order by attempts desc limit 60
  )
  select jsonb_build_object(
    'version','analytics-university-usage-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'universities',(select coalesce(jsonb_agg(jsonb_build_object(
      'university_id',university_id,'name',university_name,'sessions',sessions,'attempts',attempts,'completed',completed)),'[]'::jsonb) from usage)
  ) into result;
  return result;
end $$;

------------------------------------------------------------------------------
-- Owner + grants, matching the existing admin RPC surface (authenticated only;
-- the security-definer body enforces admin_operator()).
do $$
declare fn text;
begin
  foreach fn in array array[
    'public.analytics_admin_check()',
    'public.analytics_kpi_overview(timestamptz,timestamptz)',
    'public.analytics_funnel(timestamptz,timestamptz)',
    'public.analytics_free_credit(timestamptz,timestamptz)',
    'public.analytics_revenue(timestamptz,timestamptz)',
    'public.analytics_reliability(timestamptz,timestamptz)',
    'public.analytics_api_cost(timestamptz,timestamptz)',
    'public.analytics_university_usage(timestamptz,timestamptz)'
  ] loop
    execute format('alter function %s owner to postgres', fn);
    execute format('revoke all on function %s from public, anon, authenticated, service_role', fn);
    execute format('grant execute on function %s to authenticated', fn);
  end loop;
end $$;

commit;
