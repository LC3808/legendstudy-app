-- Analytics Admin Reporting v1 — Owner-apply. READ-ONLY aggregates over existing
-- tables. No schema change to existing tables, no new fact/event table, no change
-- to evaluation/credit/payment contracts. Every function is admin-gated and
-- security definer with an empty search_path. PostgreSQL stays the official SoT.
begin;

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
      from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id
    union all
    select s.user_id, e.completed_at as ts
      from public.essay_evaluations e join public.essay_practice_sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student' and e.completed_at is not null
  ),
  completed as (
    select distinct s.user_id
      from public.essay_evaluations e join public.essay_practice_sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student'
        and e.completed_at>=p_from and e.completed_at<p_to
  ),
  free_completed as (
    select distinct s.user_id
      from public.essay_evaluations e join public.essay_practice_sessions s on s.id=e.session_id
      where e.status='completed' and e.request_kind='student'
        and e.completed_at>=p_from and e.completed_at<p_to
        and (
          exists(select 1 from public.essay_billing_decisions d where d.evaluation_id=e.id and d.reason='included_revision')
          or exists(
            select 1 from public.essay_billing_decisions d
              join public.credit_transactions t on t.decision_id=d.id and t.transaction_type='consume'
              join public.credit_grants g on g.id=t.grant_id
             where d.evaluation_id=e.id and g.origin in ('signup_bonus','promotion','compensation','b2b_program')
          )
        )
  ),
  paid as (
    select subject_id, amount from public.payment_orders
     where state='PAID' and mode='LIVE' and paid_at>=p_from and paid_at<p_to and subject_id is not null
  ),
  student_evals as (
    select status from public.essay_evaluations
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
      from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id
      join signups u on u.user_id=s.user_id
  ),
  first_completed as (
    select distinct s.user_id
      from public.essay_evaluations e join public.essay_practice_sessions s on s.id=e.session_id
      join signups u on u.user_id=s.user_id
      where e.status='completed' and e.request_kind='student'
  ),
  rewrote as (
    select distinct s.user_id
      from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id
      join signups u on u.user_id=s.user_id
      where a.attempt_no>=2
  ),
  full_loop as (
    -- first attempt completed, then a later attempt (>=2) in the same session completed
    select distinct s1.user_id
      from public.essay_practice_sessions s1
      join signups u on u.user_id=s1.user_id
      join public.essay_attempts a1 on a1.session_id=s1.id and a1.attempt_no=1
      join public.essay_evaluations e1 on e1.attempt_id=a1.id and e1.status='completed' and e1.request_kind='student'
      join public.essay_attempts a2 on a2.session_id=s1.id and a2.attempt_no>=2
      join public.essay_evaluations e2 on e2.attempt_id=a2.id and e2.status='completed' and e2.request_kind='student'
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
      where po.state='PAID' and po.mode='LIVE'
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
     where state='PAID' and mode='LIVE' and paid_at>=p_from and paid_at<p_to
  ),
  refunds as (
    select coalesce(sum(op.amount),0) as refunded
      from public.payment_operations op
      join public.payment_orders po on po.id=op.order_id
      where op.kind='CANCEL' and op.state='SUCCEEDED' and op.reason='GENERAL_REFUND'
        and po.mode='LIVE' and op.completed_at>=p_from and op.completed_at<p_to
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
    select * from public.essay_evaluations
     where request_kind='student' and requested_at>=p_from and requested_at<p_to
  ),
  runs as (
    select r.* from public.essay_ai_processing_runs r
      join public.essay_evaluations e on e.id=r.evaluation_id
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
    'processing',(select count(*) from ev where status in ('requested','processing')),
    'reprocess_requested',(select count(*) from runs where run_no>1),
    'reprocess_success',(select count(*) from runs where run_no>1 and status='completed'),
    'latency_ms_p50',(select percentile_cont(0.5) within group (order by latency_ms) from runs where status='completed' and latency_ms is not null),
    'latency_ms_p95',(select percentile_cont(0.95) within group (order by latency_ms) from runs where status='completed' and latency_ms is not null),
    'failures_by_question',(select coalesce(jsonb_agg(jsonb_build_object('exam',exam_key,'question',question_key,'failures',failures)),'[]'::jsonb) from fail_by_question),
    'error_types',(select coalesce(jsonb_agg(jsonb_build_object('code',code,'count',n) order by n desc),'[]'::jsonb) from err),
    'credit_integrity', jsonb_build_object(
      'A_failed_but_settled',(select count(*) from ev e where e.status='failed'
        and exists(select 1 from public.essay_billing_decisions d where d.evaluation_id=e.id and d.status='settled')),
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
    select * from public.essay_ai_processing_runs
     where started_at>=p_from and started_at<p_to
  ),
  by_model as (
    select provider, model_name,
      count(*) as calls,
      sum(case when run_no>1 then 1 else 0 end) as reprocess_calls,
      sum(coalesce(input_tokens,0)) as input_tokens,
      sum(coalesce(output_tokens,0)) as output_tokens,
      sum(coalesce(total_tokens,0)) as total_tokens,
      sum(cost_amount) filter (where cost_basis='provider_reported') as reported_cost,
      count(*) filter (where cost_amount is null) as cost_missing
      from runs group by provider, model_name
  ),
  daily as (
    select date_trunc('day', started_at) as day,
      sum(cost_amount) filter (where cost_basis='provider_reported') as reported_cost,
      count(*) as calls
      from runs group by date_trunc('day', started_at) order by day
  )
  select jsonb_build_object(
    'version','analytics-api-cost-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,
    'note','cost_basis=provider_reported is actual; estimate/null is not billed truth. No evaluation is executed by this report.',
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
  with usage as (
    select u.id as university_id, u.name as university_name,
      count(distinct s.id) as sessions,
      count(distinct a.id) as attempts,
      count(distinct e.id) filter (where e.status='completed' and e.request_kind='student') as completed
      from public.essay_practice_sessions s
      join public.essay_questions q on q.id=s.question_id
      join public.essay_exams ex on ex.id=q.essay_exam_id
      join public.universities u on u.id=ex.university_id
      left join public.essay_attempts a on a.session_id=s.id and a.submitted_at>=p_from and a.submitted_at<p_to
      left join public.essay_evaluations e on e.session_id=s.id and e.completed_at>=p_from and e.completed_at<p_to
      where s.created_at>=p_from-interval '400 days'
      group by u.id, u.name
      having count(distinct a.id) > 0 or count(distinct e.id) > 0
      order by attempts desc limit 60
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
