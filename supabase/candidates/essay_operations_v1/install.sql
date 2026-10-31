-- OWNER APPROVAL CANDIDATE. No evaluation, billing or Worker functions replaced.
begin;
create schema essay_ops_private;
revoke all on schema essay_ops_private from public,anon,authenticated,service_role;
create function essay_ops_private.require_admin() returns void language plpgsql set search_path='' as $$
begin
 if auth.uid() is null or public.admin_operator() is not true or account_private.allowed(auth.uid()) is not true then raise exception 'ADMIN_REQUIRED' using errcode='42501';end if;
end $$;
create table essay_ops_private.access_log(id bigint generated always as identity primary key,actor uuid not null,recorded_at timestamptz not null default now(),action text not null,run_id uuid);
-- Versioned rates are approved server configuration, never guessed from model names.
-- NULL cached rate means cache pricing is unknown; equal rates explicitly ignore discount.
create table essay_ops_private.prices(id uuid primary key default gen_random_uuid(),provider text not null,model text not null,valid_from timestamptz not null,valid_to timestamptz not null,input_per_million numeric not null check(input_per_million>=0),output_per_million numeric not null check(output_per_million>=0),cached_per_million numeric check(cached_per_million>=0),source text not null,recorded_at timestamptz not null default now(),check(valid_from<valid_to));
create function essay_ops_private.freeze() returns trigger language plpgsql set search_path='' as $$begin raise exception 'IMMUTABLE_OBSERVATION';end $$;
create trigger prices_immutable before update or delete on essay_ops_private.prices for each row execute function essay_ops_private.freeze();
create trigger access_immutable before update or delete on essay_ops_private.access_log for each row execute function essay_ops_private.freeze();
-- Explicit approved call-to-price attribution freezes estimates even if later prices overlap.
create table essay_ops_private.cost_snapshots(call_id text primary key,price_id uuid not null references essay_ops_private.prices(id),usd numeric not null check(usd>=0),recorded_at timestamptz not null default now());
create trigger costs_immutable before update or delete on essay_ops_private.cost_snapshots for each row execute function essay_ops_private.freeze();
create table essay_ops_private.thresholds(rule text primary key,threshold numeric check(threshold>0),unit text not null);
insert into essay_ops_private.thresholds values ('daily_cost',null,'USD known subtotal'),('failure_rate',null,'percent'),('average_seconds',null,'seconds'),('provider_errors',null,'count'),('retry_count',null,'count'),('recovery_pending',null,'count'),('stuck_seconds',null,'seconds');
create table essay_ops_private.alerts(id bigint generated always as identity primary key,rule text not null references essay_ops_private.thresholds(rule),opened_at timestamptz not null default now(),resolved_at timestamptz,value numeric not null,threshold numeric not null);
create unique index alert_one_open on essay_ops_private.alerts(rule) where resolved_at is null;
create view essay_ops_private.run_facts as
select r.id evaluation_id,r.exam_id,r.parent_id,r.created_at,r.completed_at,r.state,
 u.id university_id,u.name university,e.exam_name,
 case when r.completed_at>=r.created_at then extract(epoch from r.completed_at-r.created_at) end duration_seconds,
 -- No guess from university names or exam kind: subject policy is not uniform.
 coalesce(r.snapshot->>'evaluationType','UNKNOWN') evaluation_type,
 coalesce(retry.retry_count,0) retry_count,
 coalesce(cp.failed_questions,0) failed_questions,coalesce(cp.questions,'[]') questions,
 (select coalesce(jsonb_agg(distinct payload->>'code'),'[]') from essay_exam_private.checkpoints where run_id=r.id and state='checkpoint' and payload->>'component' in ('execution_failure','validation_failure') and payload->>'code' ~ '^[A-Z_0-9]{1,80}$') failure_codes,
 coalesce(tx.reserved,0) reserved,coalesce(tx.consumed,0) consumed,coalesce(tx.released,0) released,coalesce(tx.refunded,0) refunded,
 coalesce(tx.sources,'[]') credit_sources,
 (r.state='failed' and coalesce(tx.reserved,0)>coalesce(tx.consumed,0)+coalesce(tx.released,0)) recovery_pending,
 (coalesce(tx.consumed,0)>coalesce(tx.reserved,0) or coalesce(tx.released,0)+coalesce(tx.consumed,0)>coalesce(tx.reserved,0) or (r.parent_id is not null and coalesce(tx.consumed,0)>0)) duplicate_suspected
from essay_exam_private.runs r
left join public.essay_exams e on e.id=r.exam_id left join public.universities u on u.id=e.university_id
left join lateral(select count(*) retry_count from essay_exam_private.retry_requests where run_id=r.id) retry on true
left join lateral(select * from essay_exam_private.retry_requests where run_id=r.id order by generation desc limit 1) latest on true
left join lateral(select count(*) filter(where c.payload->>'state'='failed') failed_questions,
 jsonb_agg(jsonb_build_object('question_id',a.value->>'questionId','ordinal',a.ordinality,'state',coalesce(c.payload->>'state','waiting')) order by a.ordinality) questions
 from jsonb_array_elements(r.snapshot->'answers') with ordinality a(value,ordinality)
 left join essay_exam_private.checkpoints c on c.run_id=r.id and c.key='q'||(a.ordinality-1)||case when coalesce(latest.attempts->>(a.ordinality-1)::text,'0')='0' then '' else '-retry-'||(latest.attempts->>(a.ordinality-1)::text) end)cp on true
left join lateral(select sum(t.reserved_delta) filter(where t.transaction_type='reserve') reserved,
 -sum(t.balance_delta) filter(where t.transaction_type='consume') consumed,
 -sum(t.reserved_delta) filter(where t.transaction_type='release') released,
 sum(t.balance_delta) filter(where t.transaction_type='refund') refunded,
 jsonb_agg(distinct case when g.origin='signup_bonus' then 'signup' when g.origin='purchase' then 'paid' when g.origin='essay_beta_daily' then 'beta_daily' else 'other' end) filter(where t.transaction_type='reserve') sources
 from public.credit_transactions t left join public.credit_grants g on g.id=t.grant_id where t.decision_id=r.decision_id)tx on true;

-- Only receipt keys, never q result copies or usage summaries (avoids double counting).
create view essay_ops_private.calls as
with receipts as (
 select c.run_id,c.key,c.payload,
 case when c.payload->>'component'='independent_review' then c.payload->'telemetry' else c.payload end t
 from essay_exam_private.checkpoints c where c.state='checkpoint' and c.key ~ '(^|-)receipt-' and (c.payload ? 'input_tokens' or c.payload->>'component'='independent_review')
), raw as (
 select 'exam/'||run_id||'/'||key call_id,run_id evaluation_id,
 null::timestamptz called_at,
 payload->>'provider' provider,payload->>'model' model,
 coalesce(t->>'input_tokens',t->>'p_input_tokens')::bigint input_tokens,
 coalesce(t->>'output_tokens',t->>'p_output_tokens')::bigint output_tokens,
 coalesce(t->>'total_tokens',t->>'p_total_tokens')::bigint total_tokens,
 null::bigint cached_tokens,coalesce(t->>'latency_ms',t->>'p_latency_ms')::numeric/1000 duration_seconds,
 null::numeric actual_usd,null::numeric recorded_estimate_usd, 'receipt'::text call_state,
 case when key ~ '^q[0-9]+-a[0-9]+-' then substring(key from '^q[0-9]+-a([0-9]+)-')::integer end attempt,
 case when payload->>'component'='independent_review' then 'independent_review' else 'generation' end stage
 from receipts
 union all
 select 'legacy/'||p.id,p.evaluation_id,p.started_at,p.provider,p.model_name,p.input_tokens,p.output_tokens,p.input_tokens+p.output_tokens,null,p.latency_ms/1000.0,
 case when p.cost_basis='provider_reported' and p.currency='USD' and p.cost_amount>=0 then p.cost_amount end,case when p.cost_basis='estimate' and p.currency='USD' and p.cost_amount>=0 then p.cost_amount end,p.status,p.run_no,'legacy_provider'
 from public.essay_ai_processing_runs p
 where not exists(select 1 from receipts c where coalesce(c.payload->>'run_id',c.payload->>'evaluation_id')=p.evaluation_id::text)
)
select raw.*,s.price_id,case when actual_usd is not null then 'ACTUAL' when coalesce(s.usd,recorded_estimate_usd) is not null then 'ESTIMATED' else 'UNKNOWN' end cost_status,coalesce(actual_usd,s.usd,recorded_estimate_usd) cost_usd
from raw left join essay_ops_private.cost_snapshots s using(call_id);

-- Pure cost function: no cache assumption and no price auto-selection.
create function essay_ops_private.estimate(p_input bigint,p_output bigint,p_cached bigint,p_price uuid) returns numeric language sql stable set search_path='' as $$
 select case when p_input>=0 and p_output>=0 and p_cached between 0 and p_input and cached_per_million is not null
 then ((p_input-p_cached)*input_per_million+p_cached*cached_per_million+p_output*output_per_million)/1000000
 when p_input>=0 and p_output>=0 and input_per_million=cached_per_million and p_cached is null
 then (p_input*input_per_million+p_output*output_per_million)/1000000 end
 from essay_ops_private.prices where id=p_price
$$;

create function public.admin_essay_operations(p_from timestamptz,p_to timestamptz,p_filters jsonb default '{}',p_offset integer default 0,p_run uuid default null) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare result jsonb;detail jsonb;
begin
 perform essay_ops_private.require_admin();
 if p_from is null or p_to is null or p_from>=p_to or p_to-p_from>interval '93 days' or p_offset is null or p_offset<0 or p_offset>100000 or jsonb_typeof(p_filters) is distinct from 'object' then raise exception 'INVALID_FILTER';end if;
 insert into essay_ops_private.access_log(actor,action,run_id) values(auth.uid(),'report',p_run);
 if p_run is not null then
 select jsonb_build_object('run',to_jsonb(f),'retries',(select coalesce(jsonb_agg(jsonb_build_object('generation',generation,'requested_at',created_at,'attempts',attempts) order by generation),'[]') from essay_exam_private.retry_requests where run_id=p_run),
 'diagnostics',(select coalesce(jsonb_agg(jsonb_build_object('key',key,'stage',case when payload->>'stage' ~ '^[a-z_]{1,40}$' then payload->>'stage' end,'code',case when payload->>'code' ~ '^[A-Z_0-9]{1,80}$' then payload->>'code' end,'http_status',case when payload->>'http_status' ~ '^[1-5][0-9]{2}$' then (payload->>'http_status')::integer end,'message',case when payload->>'http_status'='429' then 'HTTP 429: 요청 제한·계정 조건은 Provider 별도 확인 필요' when payload->>'code' like '%TIMEOUT%' then '기록된 처리 시간 초과' else '기록된 오류 코드와 단계를 확인하세요. 원문 오류는 개인정보 보호를 위해 제외합니다.' end,'occurred_at',null)),'[]') from essay_exam_private.checkpoints where run_id=p_run and state='checkpoint' and payload->>'component' in ('execution_failure','validation_failure')),
 'calls',(select coalesce(jsonb_agg(to_jsonb(c)),'[]') from essay_ops_private.calls c where evaluation_id=p_run),
 'ledger',(select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'at',t.created_at,'type',t.transaction_type,'balance_delta',t.balance_delta,'reserved_delta',t.reserved_delta,'origin',g.origin) order by t.created_at),'[]') from essay_exam_private.runs r join public.credit_transactions t on t.decision_id=r.decision_id left join public.credit_grants g on g.id=t.grant_id where r.id=p_run)) into detail from essay_ops_private.run_facts f where evaluation_id=p_run;
 end if;
 with filtered as materialized(select * from essay_ops_private.run_facts f where created_at>=p_from and created_at<p_to
 and (not p_filters?'university' or university_id::text=p_filters->>'university')
 and (not p_filters?'type' or evaluation_type=p_filters->>'type')
 and (not p_filters?'state' or state=p_filters->>'state')
 and (not p_filters?'source' or credit_sources ? (p_filters->>'source') or (p_filters->>'source'='free_rewrite' and parent_id is not null))
 and (not p_filters?'issues' or (retry_count>0 or failed_questions>0 or state='failed'))
 and (not p_filters?'retry' or (retry_count>0)=(p_filters->>'retry')::boolean)),
 calls as materialized(select c.*,f.created_at request_at,f.parent_id,f.state final_state,f.evaluation_type from filtered f join essay_ops_private.calls c on c.evaluation_id=f.evaluation_id),
 cost_groups as(select dimension,label,cost_status,sum(cost_usd) usd,count(*) calls from calls c cross join lateral(values
 ('day',(request_at at time zone 'Asia/Seoul')::date::text),('month',to_char(request_at at time zone 'Asia/Seoul','YYYY-MM')),('model',coalesce(model,'UNKNOWN')),('type',evaluation_type),('request',case when parent_id is null then 'initial_or_paid' else 'free_rewrite' end),('final_state',final_state),('attempt',case when attempt>0 then 'retry' when attempt=0 then 'initial' else 'UNKNOWN' end))v(dimension,label) group by dimension,label,cost_status)
 select jsonb_build_object('coverage','exam_runs; costs by REQUEST date, not invoice/call date; legacy calls separate; missing receipts not counted',
 'from',p_from,'to',p_to,'total',(select count(*) from filtered),
 'live',(select jsonb_build_object('processing',count(*) filter(where state='reserved'),'retry_pending',count(*) filter(where state='reserved' and failed_questions>0)) from essay_ops_private.run_facts),
 'calendar_costs',(select jsonb_build_object('today_known_usd',sum(cost_usd) filter(where called_at>=date_trunc('day',now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul'),'month_known_usd',sum(cost_usd) filter(where called_at>=date_trunc('month',now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul'),'undated_receipts',count(*) filter(where called_at is null),'unknown_receipts',count(*) filter(where cost_status='UNKNOWN')) from essay_ops_private.calls),
 'today_credit',(select coalesce(jsonb_agg(to_jsonb(g)),'[]') from(select g.origin,-sum(t.balance_delta) consumed from public.credit_transactions t join public.credit_grants g on g.id=t.grant_id where t.transaction_type='consume' and t.created_at>=date_trunc('day',now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul' and t.created_at<now() group by g.origin)g),
 'credit_groups',(select coalesce(jsonb_agg(to_jsonb(g)),'[]') from(select g.origin,f.state,-sum(t.balance_delta) filter(where t.transaction_type='consume') consumed,-sum(t.reserved_delta) filter(where t.transaction_type='release') released from filtered f join essay_exam_private.runs r on r.id=f.evaluation_id join public.credit_transactions t on t.decision_id=r.decision_id join public.credit_grants g on g.id=t.grant_id group by g.origin,f.state)g),
 'free_rewrite_count',(select count(*) from filtered where parent_id is not null),
 'summary',(select jsonb_build_object('requests',count(*),'completed',count(*) filter(where state='completed'),'failed',count(*) filter(where state='failed'), 'processing',count(*) filter(where state='reserved'),'retry_pending',count(*) filter(where state='reserved' and failed_questions>0),
 'success_rate',100.0*count(*) filter(where state='completed')/nullif(count(*) filter(where state in ('completed','failed')),0),
 'avg_seconds',avg(duration_seconds),'p50_seconds',percentile_cont(.5) within group(order by duration_seconds),'p90_seconds',percentile_cont(.9) within group(order by duration_seconds),'p95_seconds',percentile_cont(.95) within group(order by duration_seconds),'max_seconds',max(duration_seconds),
 'retries',sum(retry_count),'reserved',sum(reserved),'reserved_current',sum(reserved-consumed-released),'consumed',sum(consumed),'released',sum(released),'refunded',sum(refunded),'recovery_pending',count(*) filter(where recovery_pending),'duplicate_suspected',count(*) filter(where duplicate_suspected)) from filtered),
 'rows',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from(select * from filtered order by created_at desc,evaluation_id limit 25 offset p_offset)x),
 'costs',(select coalesce(jsonb_agg(to_jsonb(g)),'[]') from cost_groups g),
 'cost_coverage',(select jsonb_build_object('receipts',count(*),'unknown',count(*) filter(where cost_status='UNKNOWN'),'time_unknown',count(*) filter(where called_at is null),'input_tokens',sum(input_tokens),'output_tokens',sum(output_tokens),'known_subtotal_per_receipted_run_usd',sum(cost_usd)/nullif(count(distinct evaluation_id),0)) from calls),
 'legacy_costs',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from(select cost_status,model,sum(cost_usd) usd,count(*) calls from essay_ops_private.calls where call_id like 'legacy/%' and called_at>=p_from and called_at<p_to group by cost_status,model)x),
 'detail',detail,'alerts',(select coalesce(jsonb_agg(to_jsonb(a) order by id desc),'[]') from (select * from essay_ops_private.alerts order by id desc limit 50)a),'thresholds',(select jsonb_agg(to_jsonb(t)) from essay_ops_private.thresholds t)) into result;
 return result;
end $$;

-- Approved immutable server rates only; ambiguous or missing pricing stays UNKNOWN.
create function public.admin_essay_operations_estimate() returns integer language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare n integer;
begin
 perform essay_ops_private.require_admin();
 insert into essay_ops_private.cost_snapshots(call_id,price_id,usd)
 select c.call_id,p.id,essay_ops_private.estimate(c.input_tokens,c.output_tokens,c.cached_tokens,p.id)
 from essay_ops_private.calls c join essay_ops_private.prices p on p.provider=c.provider and p.model=c.model and c.called_at>=p.valid_from and c.called_at<p.valid_to
 where c.cost_status='UNKNOWN' and essay_ops_private.estimate(c.input_tokens,c.output_tokens,c.cached_tokens,p.id) is not null
 and (select count(*) from essay_ops_private.prices p2 where p2.provider=c.provider and p2.model=c.model and c.called_at>=p2.valid_from and c.called_at<p2.valid_to)=1
 on conflict(call_id) do nothing;
 get diagnostics n=row_count;
 insert into essay_ops_private.access_log(actor,action) values(auth.uid(),'estimate_cost');return n;
end $$;

-- Explicit admin check; no scheduler installed. NULL thresholds are disabled.
create function public.admin_essay_operations_check_alerts() returns jsonb language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare t record;v numeric;today timestamptz=date_trunc('day',now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul';
begin
 perform essay_ops_private.require_admin(); perform pg_advisory_xact_lock(640006);
 for t in select * from essay_ops_private.thresholds loop
 v:=null;
 if t.rule='daily_cost' then select sum(cost_usd) into v from essay_ops_private.calls where called_at>=today and called_at<today+interval '1 day';
 elsif t.rule='failure_rate' then select 100.0*count(*) filter(where state='failed')/nullif(count(*) filter(where state in ('failed','completed')),0) into v from essay_ops_private.run_facts where created_at>=today;
 elsif t.rule='average_seconds' then select avg(duration_seconds) into v from essay_ops_private.run_facts where created_at>=today;
 elsif t.rule='provider_errors' then select count(*) into v from essay_exam_private.checkpoints c join essay_exam_private.runs r on r.id=c.run_id where r.created_at>=today and c.payload->>'component'='execution_failure' and c.payload->>'stage'='provider';
 elsif t.rule='retry_count' then select count(*) into v from essay_exam_private.retry_requests where created_at>=today;
 elsif t.rule='recovery_pending' then select count(*) into v from essay_ops_private.run_facts where recovery_pending;
 elsif t.rule='stuck_seconds' then select coalesce(max(extract(epoch from now()-created_at)),0) into v from essay_ops_private.run_facts where state='reserved';end if;
 if t.threshold is not null and v>=t.threshold then
 insert into essay_ops_private.alerts(rule,value,threshold) values(t.rule,v,t.threshold) on conflict(rule) where resolved_at is null do update set value=excluded.value;
 elsif v is not null or t.threshold is null then update essay_ops_private.alerts set resolved_at=now() where rule=t.rule and resolved_at is null;end if;
 end loop;
 insert into essay_ops_private.access_log(actor,action) values(auth.uid(),'check_alerts');
 return jsonb_build_object('checked_at',now(),'note','Observed at admin check; unknown metrics never imply recovery');
end $$;
do $$declare t text;begin foreach t in array array['access_log','prices','cost_snapshots','thresholds','alerts'] loop execute format('alter table essay_ops_private.%I enable row level security',t);end loop;end$$;
revoke all on all tables in schema essay_ops_private from public,anon,authenticated,service_role;
revoke all on all sequences in schema essay_ops_private from public,anon,authenticated,service_role;
revoke all on all functions in schema essay_ops_private from public,anon,authenticated,service_role;
revoke all on function public.admin_essay_operations(timestamptz,timestamptz,jsonb,integer,uuid),public.admin_essay_operations_check_alerts(),public.admin_essay_operations_estimate() from public,anon,service_role;
grant execute on function public.admin_essay_operations(timestamptz,timestamptz,jsonb,integer,uuid),public.admin_essay_operations_check_alerts(),public.admin_essay_operations_estimate() to authenticated;
commit;
