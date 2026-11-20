-- Owner-authorized RPC-only archive eligibility correction. No existing row mutations.
-- Existing state/snapshot/checkpoints/billing/ledger and historical statistics remain unchanged.
begin;
do $$declare x record;begin
 for x in select * from (values
('public.admin_essay_operations(timestamp with time zone,timestamp with time zone,jsonb,integer,uuid)','6b60463d6f68140d53d20a0f83465d75'),
('public.admin_lab_manage_run(uuid,text,uuid)','7490f7adc5d490121540aa53d7fd1f05'),
('public.admin_lab_run_capabilities(uuid)','a552036fa62ee763aabb100e81a7235c'),
('public.admin_lab_set_run_hidden(uuid,boolean)','e64687bcbd0988d0e0f4b8db0d471458'),
('public.essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','f99bc33ca07235aabbf06a8e71818bf4'),
('public.essay_exam_claim(uuid,uuid,uuid)','831184243ee955cd591dbb9f32a50905'),
('public.essay_exam_observation(uuid)','e360af489bbadb077970de7745b9f0e3'),
('public.essay_exam_retry(uuid,uuid,uuid,uuid)','5636d454391c76aa60411f2a64a44286'),
('public.essay_exam_session_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','19323172ce32422aee6f36b786ecf507'),
('public.essay_exam_session_status(uuid)','3e7f7c53c76b7623cfabbede642f4e25')) v(signature,expected_md5) loop
  if md5(pg_get_functiondef(x.signature::regprocedure))<>x.expected_md5 then raise exception 'PREIMAGE_CHANGED: %',x.signature;end if;
 end loop;
 if to_regprocedure('public.essay_exam_dispatch_guard(uuid,uuid)') is not null then raise exception 'DISPATCH_GUARD_ALREADY_EXISTS';end if;
end$$;
CREATE OR REPLACE FUNCTION public.admin_essay_operations(p_from timestamp with time zone, p_to timestamp with time zone, p_filters jsonb DEFAULT '{}'::jsonb, p_offset integer DEFAULT 0, p_run uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
 SET statement_timeout TO '8s'
AS $function$
declare result jsonb;detail jsonb;
begin
 perform essay_ops_private.require_admin();
 if p_from is null or p_to is null or p_from>=p_to or p_to-p_from>interval '93 days' or p_offset is null or p_offset<0 or p_offset>100000 or jsonb_typeof(p_filters) is distinct from 'object' then raise exception 'INVALID_FILTER';end if;
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
 'live',(select jsonb_build_object('processing',count(*) filter(where f.state='reserved' and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden)),'retry_pending',count(*) filter(where f.state='reserved' and f.failed_questions>0 and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden)),'archived',count(*) filter(where exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=f.evaluation_id and h.hidden))) from essay_ops_private.run_facts f),
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
 'detail',detail,'read_only',true,'alerts','[]'::jsonb,'thresholds','[]'::jsonb) into result;
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_lab_manage_run(p_run uuid, p_action text, p_key uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
 SET statement_timeout TO '8s'
AS $function$
declare r essay_exam_private.runs; a uuid; subject uuid; caps jsonb; result jsonb; prior essay_ops_private.run_actions;
begin
 perform essay_ops_private.require_admin();
 if p_run is null or p_key is null or p_action is null or p_action not in ('retry','delete','archive','restore') then raise invalid_parameter_value;end if;
 -- Same account -> run -> billing lock order as existing Worker/Credit paths.
 select account_id into a from essay_exam_private.runs where id=p_run;
 select user_id into subject from public.credit_accounts where id=a for update;
 select * into r from essay_exam_private.runs where id=p_run for update;
 -- Archived retry intents cannot replay into a queue after an operator pauses the run.
 if p_action='retry' and exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;
 select * into prior from essay_ops_private.run_actions where id=p_key;
 if found then
  if prior.actor<>auth.uid() or prior.run_id<>p_run or prior.action<>p_action then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;
  -- An old retry intent must never dispatch a different/latest generation or a finished run.
  if p_action='retry' and (r.id is null or r.state<>'reserved' or not exists(select 1 from essay_exam_private.retry_requests where run_id=p_run and request_key=p_key and generation=(select max(generation) from essay_exam_private.retry_requests where run_id=p_run))) then raise sqlstate 'PT409' using message='ACTION_SUPERSEDED';end if;
  return prior.outcome;
 end if;
 if r.id is null then raise sqlstate 'PT404' using message='RUN_NOT_FOUND';end if;
 perform 1 from public.essay_billing_decisions where id=r.decision_id for update;
 caps=public.admin_lab_run_capabilities(p_run);
 if p_action='retry' then
  if not (caps->>'retry_allowed')::boolean then raise sqlstate 'PT409' using message=caps->>'retry_reason';end if;
  result=public.essay_exam_retry(subject,p_run,p_key,r.exam_id)||jsonb_build_object('subject_id',subject,'exam_id',r.exam_id);
 elsif p_action='delete' then
  if not (caps->>'delete_allowed')::boolean then raise sqlstate 'PT409' using message=caps->>'delete_reason';end if;
  -- Only run/checkpoint/retry data. Billing decisions and ledger remain immutable.
  delete from essay_ops_private.hidden_runs where run_id=p_run;
  delete from essay_exam_private.runs where id=p_run;
  result=jsonb_build_object('deleted',true);
 else
  result=public.admin_lab_set_run_hidden(p_run,p_action='archive');
 end if;
 result=result||jsonb_build_object('version','admin-run-management-v1','run_id',p_run,'action',p_action,'action_id',p_key);
 insert into essay_ops_private.run_actions(id,run_id,actor,action,outcome) values(p_key,p_run,auth.uid(),p_action,result);
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.admin_lab_run_capabilities(p_run uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
 SET statement_timeout TO '5s'
AS $function$
declare r essay_exam_private.runs; b public.essay_billing_decisions; attempts jsonb; cp essay_exam_private.checkpoints;
 ledger_count integer; live boolean; verified boolean; retry_reason text; delete_reason text; archived boolean; archive_reason text;
 failures integer=0; i integer; n integer; latest_retry timestamptz; latest_lease timestamptz;
begin
 perform essay_ops_private.require_admin();
 select * into r from essay_exam_private.runs where id=p_run;
 if r.id is null then raise sqlstate 'PT404' using message='RUN_NOT_FOUND';end if;
 select * into b from public.essay_billing_decisions where id=r.decision_id;
 select count(*) into ledger_count from public.credit_transactions where decision_id=r.decision_id;
 select t.attempts,t.created_at,t.lease_until into attempts,latest_retry,latest_lease from essay_exam_private.retry_requests t where run_id=p_run order by generation desc limit 1;
 live=coalesce(r.lease_until>clock_timestamp(),false) or exists(select 1 from essay_exam_private.retry_requests where run_id=p_run and lease_until>clock_timestamp());
 verified=exists(select 1 from essay_ops_private.verified_test_runs where run_id=p_run);
 archived=exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden);
 archive_reason=case when archived then 'ALREADY_ARCHIVED' when live then 'ACTIVE_LEASE' when r.state='reserved' and (r.dispatch_key is null or r.lease_token is null or exists(select 1 from essay_exam_private.checkpoints c where c.run_id=p_run and (c.key='final' or c.state='pending' or c.payload->>'state'='reconciling'))) then 'RECONCILIATION_REQUIRED' end;
 if archived then retry_reason='RUN_ARCHIVED';
 elsif live then retry_reason='ACTIVE_LEASE';
 elsif r.state<>'reserved' then retry_reason='FINALIZED_RUN';
 elsif r.lease_token is null or exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key='final') then retry_reason='RECONCILIATION_REQUIRED';
 elsif b.id is null or b.status<>'reserved' then retry_reason='BILLING_NOT_RESERVED';
 else
  for i in 0..jsonb_array_length(r.snapshot->'answers')-1 loop
   n=coalesce((attempts->>i::text)::integer,0);
   select * into cp from essay_exam_private.checkpoints where run_id=p_run and key='q'||i||case when n=0 then '' else '-retry-'||n end;
   if cp.run_id is null or cp.state<>'checkpoint' or coalesce(cp.payload->>'state','') not in ('completed','failed') then retry_reason='RECONCILIATION_REQUIRED';exit;end if;
   if cp.payload->>'state'='failed' then failures=failures+1;end if;
  end loop;
  if retry_reason is null and failures=0 then retry_reason='NO_FAILED_QUESTIONS';end if;
 end if;
 if not verified then delete_reason='TEST_NOT_VERIFIED';
 elsif live then delete_reason='ACTIVE_LEASE';
 elsif exists(select 1 from pg_catalog.pg_constraint where contype='f' and confrelid='essay_exam_private.runs'::regclass and conrelid not in ('essay_exam_private.runs'::regclass,'essay_exam_private.checkpoints'::regclass,'essay_exam_private.retry_requests'::regclass,'math_private.mixed_coaching_disclosures'::regclass,'math_private.mixed_coaching_hints'::regclass,'public.human_quality_judgments'::regclass)) then delete_reason='UNREVIEWED_DEPENDENCY';
 elsif r.state='completed' then delete_reason='COMPLETED_RUN';
 elsif b.id is null or ledger_count>0 or b.credits_required>0 or b.status in ('reserved','settled') then delete_reason='CREDIT_LINKED';
 elsif r.parent_id is not null or r.previous_paid_run_id is not null or exists(select 1 from essay_exam_private.runs where parent_id=p_run or previous_paid_run_id=p_run) then delete_reason='RELATED_RUNS';
 elsif exists(select 1 from essay_ops_private.calls where evaluation_id=p_run)
  or exists(select 1 from public.human_quality_judgments where exam_run_id=p_run)
  or exists(select 1 from math_private.mixed_coaching_disclosures where run_id=p_run)
  or exists(select 1 from math_private.mixed_coaching_hints where run_id=p_run)
  or exists(select 1 from feedback_private.essay_context where run_id=p_run)
  or exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and (state='pending' or payload->>'state' in ('completed','reconciling'))) then delete_reason='RELATED_EVALUATION';
 end if;
 return jsonb_build_object('version','admin-run-management-v1','run_id',p_run,'state',r.state,'exam_id',r.exam_id,'subject_id',(select user_id from public.credit_accounts where id=r.account_id),
  'created_at',r.created_at,'completed_at',r.completed_at,'lease_until',r.lease_until,'retry_created_at',latest_retry,'retry_lease_until',latest_lease,
  'as_of',clock_timestamp(),'active_lease',live,'verified_test',verified,'classification',case when verified then 'verified_test' when ledger_count>0 then 'credit_linked' else 'unverified' end,
  'billing_status',b.status,'credits_required',b.credits_required,'ledger_count',ledger_count,'decision_id',r.decision_id,
  'retry_allowed',retry_reason is null,'retry_reason',retry_reason,'delete_allowed',delete_reason is null,'delete_reason',delete_reason,
  'hidden',archived,'archive_allowed',archive_reason is null,'archive_reason',archive_reason,'restore_allowed',archived);
end $function$;

CREATE OR REPLACE FUNCTION public.admin_lab_set_run_hidden(p_run uuid, p_hidden boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
 SET statement_timeout TO '5s'
AS $function$
DECLARE r essay_exam_private.runs; a uuid;
BEGIN
 PERFORM essay_ops_private.require_admin();
 IF auth.uid() IS NULL THEN RAISE insufficient_privilege; END IF;
 IF p_run IS NULL OR p_hidden IS NULL THEN RAISE invalid_parameter_value; END IF;
 -- Same account -> run lock order as claim/retry, including this legacy entry.
 SELECT account_id INTO a FROM essay_exam_private.runs WHERE id=p_run;
 PERFORM 1 FROM public.credit_accounts WHERE id=a FOR UPDATE;
 SELECT * INTO r FROM essay_exam_private.runs WHERE id=p_run FOR UPDATE;
 IF r.id IS NULL THEN RAISE SQLSTATE 'PT404' USING MESSAGE='RUN_NOT_FOUND'; END IF;
 IF p_hidden AND NOT exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) THEN
  IF coalesce(r.lease_until>clock_timestamp(),false) OR EXISTS(SELECT 1 FROM essay_exam_private.retry_requests WHERE run_id=p_run AND lease_until>clock_timestamp()) THEN
   RAISE SQLSTATE 'PT409' USING MESSAGE='ACTIVE_LEASE';
  END IF;
  IF r.state='reserved' AND (r.dispatch_key is null or r.lease_token is null or exists(select 1 from essay_exam_private.checkpoints c where c.run_id=p_run and (c.key='final' or c.state='pending' or c.payload->>'state'='reconciling'))) THEN RAISE SQLSTATE 'PT409' USING MESSAGE='RECONCILIATION_REQUIRED';END IF;
 END IF;
 INSERT INTO essay_ops_private.hidden_runs(run_id,hidden,changed_by) VALUES(p_run,p_hidden,auth.uid())
 ON CONFLICT(run_id) DO UPDATE SET hidden=excluded.hidden,changed_by=excluded.changed_by,changed_at=now();
 RETURN jsonb_build_object('version','admin-lab-visibility-v1','run_id',p_run,'hidden',p_hidden);
END $function$;

CREATE OR REPLACE FUNCTION public.essay_exam_checkpoint(p_subject uuid, p_run uuid, p_token uuid, p_key text, p_action text, p_writer uuid DEFAULT NULL::uuid, p_payload jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r essay_exam_private.runs; c essay_exam_private.checkpoints; account uuid; inserted int;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;
 -- Preserve reads and the original writer's late evidence; block new execution only.
 if p_action='begin' and exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;
 if p_key is null or p_key !~ '^[a-zA-Z0-9_-]{1,100}$' or p_action is null or p_action not in ('read','begin','write') then raise sqlstate 'PT422';end if;
 select * into c from essay_exam_private.checkpoints where run_id=p_run and key=p_key;
 if p_action='read' then
  return case when c.run_id is null then null else jsonb_build_object('state',c.state,'payload',c.payload) end;
 end if;
 if r.state<>'reserved' or p_writer is null then raise sqlstate 'PT409';end if;
 if p_action='begin' then
  if r.lease_until is null or r.lease_until<=clock_timestamp() then raise sqlstate 'PT409' using message='DISPATCH_LEASE_EXPIRED';end if;
  -- Never renew or steal even the SAME writer: lost begin response is ambiguous.
  insert into essay_exam_private.checkpoints values(p_run,p_key,p_writer,'pending',null) on conflict do nothing;
  get diagnostics inserted=row_count;
  return jsonb_build_object('started',inserted=1);
 end if;
 if c.run_id is null or c.writer<>p_writer or p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>8388608 then raise sqlstate 'PT409';end if;
 if c.state='checkpoint' and c.payload is distinct from p_payload then raise sqlstate 'PT409' using message='CHECKPOINT_IMMUTABLE';end if;
 -- Original writer may persist after dispatch expiry; no new Provider execution.
 update essay_exam_private.checkpoints set state='checkpoint',payload=p_payload where run_id=p_run and key=p_key;
 return jsonb_build_object('stored',true);
end$function$;

CREATE OR REPLACE FUNCTION public.essay_exam_claim(p_subject uuid, p_run uuid, p_dispatch uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r essay_exam_private.runs; account uuid;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_dispatch is null then raise sqlstate 'PT403';end if;
 if exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) then return jsonb_build_object('state','archived','run_id',r.id,'dispatch_allowed',false);end if;
 if r.state<>'reserved' then return jsonb_build_object('state',r.state,'run_id',r.id);end if;
 if r.dispatch_key is null then
  update essay_exam_private.runs set dispatch_key=p_dispatch,lease_token=gen_random_uuid(),lease_until=clock_timestamp()+interval '15 minutes'
  where id=r.id returning * into r;
 elsif r.dispatch_key<>p_dispatch then
  raise sqlstate 'PT409' using message='RECONCILIATION_REQUIRED';
 end if;
 return jsonb_build_object('state','reserved','dispatch_allowed',r.lease_until>clock_timestamp(),'run_id',r.id,'subject_id',p_subject,'exam_id',r.exam_id,
 'snapshot',r.snapshot,'parent_id',r.parent_id,'parent_result',(select p.result from essay_exam_private.runs p where p.id=r.parent_id and p.account_id=r.account_id),'lease_token',r.lease_token,'lease_until',r.lease_until);
end$function$;

CREATE OR REPLACE FUNCTION public.essay_exam_observation(p_run uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); result jsonb; expected integer;
begin
 perform math_private.require_active(array[u]);
 -- One SELECT snapshot binds retry generation, checkpoint state and official
 -- labels. Never combine status from one generation with a later generation.
 with owned as (
   select r.* from essay_exam_private.runs r join public.credit_accounts a on a.id=r.account_id
   where r.id=p_run and a.user_id=u
 ), context as (
   select r.*,coalesce(t.attempts,'{}'::jsonb) attempts,coalesce(t.generation,0) generation
   from owned r left join lateral (select * from essay_exam_private.retry_requests
     where run_id=r.id order by generation desc limit 1) t on true
 ), states as (
   select r.id,a.ordinality,q.display_order,jsonb_build_object('question_id',a.value->>'questionId','label',q.label,'state',
     case when r.state='completed' then 'completed'
     when c.state='checkpoint' and c.payload->>'state' in ('completed','failed','reconciling') then c.payload->>'state'
     when c.state='pending' then 'processing' else 'waiting' end) value
   from context r cross join lateral jsonb_array_elements(r.snapshot->'answers') with ordinality a(value,ordinality)
   join public.essay_questions q on q.id=(a.value->>'questionId')::uuid and q.essay_exam_id=r.exam_id
   left join essay_exam_private.checkpoints c on c.run_id=r.id and c.key='q'||(a.ordinality-1)||
     case when coalesce((r.attempts->>(a.ordinality-1)::text)::integer,0)=0 then '' else '-retry-'||(r.attempts->>(a.ordinality-1)::text) end
 )
 select jsonb_build_object('version','exam-session-v1','run_id',r.id,'exam_id',r.exam_id,'state',r.state,'generation',r.generation,
   'questions',(select jsonb_agg(s.value order by s.display_order,s.ordinality) from states s),
   'retry_allowed',r.state='reserved' and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) and not exists(select 1 from essay_exam_private.checkpoints where run_id=r.id and key='final')
     and exists(select 1 from states s where s.value->>'state'='failed')
     and not exists(select 1 from states s where s.value->>'state' not in ('completed','failed')))
 ,jsonb_array_length(r.snapshot->'answers')
 into result,expected from context r;
 if result is null then raise sqlstate 'PT404';end if;
 if jsonb_array_length(result->'questions') is distinct from expected then raise exception 'QUESTION_METADATA_UNAVAILABLE';end if;
 return result;
end $function$;

CREATE OR REPLACE FUNCTION public.essay_exam_retry(p_subject uuid, p_run uuid, p_key uuid, p_exam uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r essay_exam_private.runs; account uuid; previous essay_exam_private.retry_requests;
 attempts jsonb='{}'; next_attempts jsonb='{}'; cp essay_exam_private.checkpoints;
 i integer; n integer; checkpoint_key text; failures integer=0;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_key is null or p_exam is null or r.exam_id<>p_exam then raise sqlstate 'PT403';end if;
 if exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;
 select * into previous from essay_exam_private.retry_requests where run_id=p_run and request_key=p_key;
 if found then return jsonb_build_object('run_id',r.id,'generation',previous.generation);end if;
 if r.state<>'reserved' or r.lease_token is null or exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key='final') then
  raise sqlstate 'PT409' using message='RETRY_NOT_AVAILABLE';end if;
 select * into previous from essay_exam_private.retry_requests where run_id=p_run order by generation desc limit 1;
 attempts=coalesce(previous.attempts,'{}'::jsonb);next_attempts=attempts;
 for i in 0..jsonb_array_length(r.snapshot->'answers')-1 loop
  n=coalesce((attempts->>i::text)::integer,0);
  checkpoint_key='q'||i||case when n=0 then '' else '-retry-'||n end;
  select * into cp from essay_exam_private.checkpoints where run_id=p_run and key=checkpoint_key;
  if cp.run_id is null or cp.state<>'checkpoint' or coalesce(cp.payload->>'state','') not in ('completed','failed') then
   raise sqlstate 'PT409' using message='RECONCILIATION_REQUIRED';end if;
  if cp.payload->>'state'='failed' then
   failures=failures+1;next_attempts=jsonb_set(next_attempts,array[i::text],to_jsonb(n+1));
  end if;
 end loop;
 if failures=0 then raise sqlstate 'PT409' using message='RETRY_NOT_AVAILABLE';end if;
 insert into essay_exam_private.retry_requests(run_id,request_key,generation,attempts)
 values(p_run,p_key,coalesce(previous.generation,0)+1,next_attempts) returning * into previous;
 return jsonb_build_object('run_id',r.id,'generation',previous.generation);
end $function$;

CREATE OR REPLACE FUNCTION public.essay_exam_session_checkpoint(p_subject uuid, p_run uuid, p_token uuid, p_key text, p_action text, p_writer uuid DEFAULT NULL::uuid, p_payload jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r essay_exam_private.runs; account uuid; inserted integer;
begin
 -- Original read/write authorization and immutable writer checks are unchanged.
 if p_action is distinct from 'begin' then
  return public.essay_exam_checkpoint(p_subject,p_run,p_token,p_key,p_action,p_writer,p_payload);
 end if;
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;
 -- Preserve reads and the original writer's late evidence; block new execution only.
 if p_action='begin' and exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) then raise sqlstate 'PT409' using message='RUN_ARCHIVED';end if;
 if p_key is null or p_key !~ '^[a-zA-Z0-9_-]{1,100}$' or p_writer is null then raise sqlstate 'PT422';end if;
 if r.state<>'reserved' or not (r.lease_until>clock_timestamp() or exists(
  select 1 from essay_exam_private.retry_requests t where t.run_id=p_run and t.lease_until>clock_timestamp())) then
  raise sqlstate 'PT409' using message='DISPATCH_LEASE_EXPIRED';end if;
 -- Append-only keys; never steal a pending or overwrite a completed checkpoint.
 insert into essay_exam_private.checkpoints values(p_run,p_key,p_writer,'pending',null) on conflict do nothing;
 get diagnostics inserted=row_count;
 return jsonb_build_object('started',inserted=1);
end $function$;

CREATE OR REPLACE FUNCTION public.essay_exam_session_status(p_run uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); r essay_exam_private.runs; attempts jsonb; rows jsonb; retryable boolean;
begin
 perform math_private.require_active(array[u]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id where x.id=p_run and a.user_id=u;
 if r.id is null then raise sqlstate 'PT404';end if;
 select t.attempts into attempts from essay_exam_private.retry_requests t where t.run_id=p_run order by generation desc limit 1;
 select jsonb_agg(jsonb_build_object('question_id',a.answer->>'questionId','state',
  case when r.state='completed' then 'completed' when c.state='checkpoint' and c.payload->>'state' in ('completed','failed','reconciling') then c.payload->>'state' when c.state='pending' then 'processing' else 'waiting' end) order by a.idx) into rows
 from jsonb_array_elements(r.snapshot->'answers') with ordinality a(answer,idx)
 left join essay_exam_private.checkpoints c on c.run_id=p_run and c.key='q'||(a.idx-1)||
  case when coalesce((attempts->>(a.idx-1)::text)::integer,0)=0 then '' else '-retry-'||(attempts->>(a.idx-1)::text) end;
 retryable=r.state='reserved' and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden) and not exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key='final') and
  exists(select 1 from jsonb_array_elements(rows) q where q->>'state'='failed') and
  not exists(select 1 from jsonb_array_elements(rows) q where q->>'state' not in ('completed','failed'));
 return jsonb_build_object('version','exam-session-v1','run_id',r.id,'exam_id',r.exam_id,'state',r.state,'questions',rows,'retry_allowed',retryable);
end $function$;
CREATE FUNCTION public.essay_exam_dispatch_guard(p_subject uuid,p_run uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
declare r essay_exam_private.runs;
begin
 perform math_private.require_active(array[p_subject]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id
  where x.id=p_run and a.user_id=p_subject;
 if r.id is null then raise sqlstate 'PT403';end if;
 return jsonb_build_object('run_id',r.id,'state',case when exists(
  select 1 from essay_ops_private.hidden_runs h where h.run_id=r.id and h.hidden) then 'archived' else r.state end);
end$$;
revoke all on function public.essay_exam_dispatch_guard(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_dispatch_guard(uuid,uuid) to essay_worker;
notify pgrst,'reload schema';
commit;
