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
end $function$;
