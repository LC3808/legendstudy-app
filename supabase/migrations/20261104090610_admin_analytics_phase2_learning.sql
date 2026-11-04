begin;
set local lock_timeout='5s';
create function public.admin_exam_learning(p_from timestamptz,p_to timestamptz) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare v jsonb;
begin
 if not public.admin_operator() then raise insufficient_privilege;end if;
 if p_from is null or p_to is null or not isfinite(p_from) or not isfinite(p_to) or p_from>=p_to or p_to-p_from>interval '400 days' then raise invalid_parameter_value;end if;
 with eligible as materialized(select r.*,ca.user_id from essay_exam_private.runs r join public.credit_accounts ca on ca.id=r.account_id where account_private.allowed(ca.user_id)),
 requested as materialized(select * from eligible where created_at>=p_from and created_at<p_to),
 completed as materialized(select * from eligible where state='completed' and completed_at>=p_from and completed_at<p_to),
 loops as materialized(select c.* from completed c join eligible p on p.id=c.parent_id and p.account_id=c.account_id and p.exam_id=c.exam_id
 where p.state='completed' and p.completed_at<=c.created_at and c.created_at<=c.completed_at
 and (select array_agg(a->>'questionId' order by a->>'questionId') from jsonb_array_elements(c.snapshot->'answers') a)
   =(select array_agg(a->>'questionId' order by a->>'questionId') from jsonb_array_elements(p.snapshot->'answers') a)),
 weekly as materialized(select date_trunc('week',completed_at at time zone 'Asia/Seoul')::date week,count(distinct user_id) users from loops group by 1),
 exams as materialized(select r.exam_id,count(distinct r.user_id) users,count(*) runs,sum(jsonb_array_length(r.snapshot->'answers')) questions from requested r group by r.exam_id),
 counts as (select (select count(distinct user_id) from requested) users,(select count(*) from requested) runs,
 (select count(*) from completed) completed,
 (select count(*) from completed c join public.essay_billing_decisions d on d.id=c.decision_id where c.parent_id is not null and d.reason='included_revision' and d.credits_required=0) free_rewrites,
 (select count(distinct user_id) from loops) loop_users)
 select jsonb_build_object('formula_version','exam-learning-v1','as_of',statement_timestamp(),'from',p_from,'to',p_to,'environment','UNKNOWN',
 'scope','exam_runs_only','state',case when users=0 then 'EMPTY' when users<5 then 'SUPPRESSED' else 'READY' end,
 'metrics',case when users>=5 and not exists(select 1 from (values ((select count(distinct user_id) from completed)),((select count(distinct user_id) from loops)),((select count(distinct c.user_id) from completed c join public.essay_billing_decisions d on d.id=c.decision_id where c.parent_id is not null and d.reason='included_revision' and d.credits_required=0))) sub(n) where n between 1 and 4) then to_jsonb(c) else null end,
 'weekly_state',case when exists(select 1 from weekly where users<5) then 'SUPPRESSED' else 'READY' end,
 'weekly',case when exists(select 1 from weekly where users<5) then '[]' else coalesce((select jsonb_agg(jsonb_build_object('week',week,'users',users,'partial',week+7>(statement_timestamp() at time zone 'Asia/Seoul')::date or week<(p_from at time zone 'Asia/Seoul')::date or week+7>(p_to at time zone 'Asia/Seoul')::date) order by week) from weekly),'[]') end,
 'exams_state',case when exists(select 1 from exams where users<5) then 'SUPPRESSED' else 'READY' end,
 'exams',case when exists(select 1 from exams where users<5) then '[]' else coalesce((select jsonb_agg(to_jsonb(x)) from (select e.*,ex.exam_name,u.name university from exams e left join public.essay_exams ex on ex.id=e.exam_id left join public.universities u on u.id=ex.university_id order by e.runs desc,e.exam_id limit 100)x),'[]') end,
 'learning_levels_state','NOT_CONNECTED','legacy_math_coverage','SEPARATE_SOURCE_NOT_ADDED') into v from counts c;
 return v;
end$$;
revoke all on function public.admin_exam_learning(timestamptz,timestamptz) from public,anon,authenticated,service_role;
grant execute on function public.admin_exam_learning(timestamptz,timestamptz) to authenticated;
CREATE OR REPLACE FUNCTION public.analytics_api_cost(p_from timestamp with time zone, p_to timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
      sum(case when (case when call_id like 'exam/%' then run_no>0 when call_id like 'legacy/%' then run_no>1 else false end) then 1 else 0 end) as reprocess_calls,
      sum(input_tokens) as input_tokens,
      sum(output_tokens) as output_tokens,
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
    'reprocess_calls',(select count(*) from runs where (case when call_id like 'exam/%' then run_no>0 when call_id like 'legacy/%' then run_no>1 else false end)),
    'total_reported_cost',(select sum(cost_amount) from runs where cost_basis='provider_reported'),
    'cost_missing_runs',(select count(*) from runs where cost_amount is null),
    'by_model',(select coalesce(jsonb_agg(jsonb_build_object(
        'provider',provider,'model',model_name,'calls',calls,'reprocess_calls',reprocess_calls,
        'input_tokens',input_tokens,'output_tokens',output_tokens,'total_tokens',total_tokens,
        'reported_cost',reported_cost,'cost_missing',cost_missing) order by calls desc),'[]'::jsonb) from by_model),
    'daily',(select coalesce(jsonb_agg(jsonb_build_object('day',day,'reported_cost',reported_cost,'calls',calls) order by day),'[]'::jsonb) from daily)
  ) into result;
  return result;
end $function$;

commit;
