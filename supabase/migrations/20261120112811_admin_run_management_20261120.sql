-- Owner apply only. Additive admin adapter; no existing run/ledger changes on install.
begin;
create table essay_ops_private.run_actions (
 id uuid primary key, run_id uuid not null, actor uuid not null,
 action text not null check(action in ('retry','delete','archive','restore')),
 recorded_at timestamptz not null default clock_timestamp(), outcome jsonb not null
);
create table essay_ops_private.verified_test_runs (
 run_id uuid primary key, verified_by uuid not null, verified_at timestamptz not null default clock_timestamp(),
 evidence text not null check(length(btrim(evidence)) between 20 and 2000)
);
-- Explicit Owner-reviewed evidence only; no client registration endpoint or email heuristic.
create index if not exists retry_requests_created_at_idx on essay_exam_private.retry_requests(created_at);
alter table essay_ops_private.run_actions enable row level security;
alter table essay_ops_private.run_actions force row level security;
alter table essay_ops_private.verified_test_runs enable row level security;
alter table essay_ops_private.verified_test_runs force row level security;
revoke all on essay_ops_private.run_actions,essay_ops_private.verified_test_runs from public,anon,authenticated,service_role,essay_worker;
create function essay_ops_private.guard_run_action() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'ADMIN_AUDIT_IMMUTABLE';end $$;
create trigger immutable before update or delete on essay_ops_private.run_actions for each row execute function essay_ops_private.guard_run_action();

create function public.admin_lab_run_capabilities(p_run uuid) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='5s' as $fn$
declare r essay_exam_private.runs; b public.essay_billing_decisions; attempts jsonb; cp essay_exam_private.checkpoints;
 ledger_count integer; live boolean; verified boolean; retry_reason text; delete_reason text;
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
 if live then retry_reason='ACTIVE_LEASE';
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
  'hidden',coalesce((select hidden from essay_ops_private.hidden_runs where run_id=p_run),false));
end $fn$;

create function public.admin_lab_manage_run(p_run uuid,p_action text,p_key uuid) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='8s' as $fn$
declare r essay_exam_private.runs; a uuid; subject uuid; caps jsonb; result jsonb; prior essay_ops_private.run_actions;
begin
 perform essay_ops_private.require_admin();
 if p_run is null or p_key is null or p_action is null or p_action not in ('retry','delete','archive','restore') then raise invalid_parameter_value;end if;
 -- Same account -> run -> billing lock order as existing Worker/Credit paths.
 select account_id into a from essay_exam_private.runs where id=p_run;
 select user_id into subject from public.credit_accounts where id=a for update;
 select * into r from essay_exam_private.runs where id=p_run for update;
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
end $fn$;

create function public.admin_lab_operation_stats(p_from timestamptz,p_to timestamptz) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='5s' as $fn$
begin
 perform essay_ops_private.require_admin();
 if (p_from is null)<>(p_to is null) or p_from>=p_to or p_to-p_from>interval '93 days' then raise invalid_parameter_value;end if;
 return jsonb_build_object('version','admin-lab-operation-stats-v1','as_of',clock_timestamp(),'from',p_from,'to',p_to,
 'summary',(select jsonb_build_object('requests',count(*),'completed',count(*) filter(where state='completed'),'failed',count(*) filter(where state='failed'),
 'retries',(select count(*) from essay_exam_private.retry_requests where (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to))) from essay_exam_private.runs where (p_from is null or created_at>=p_from) and (p_to is null or created_at<p_to)));
end $fn$;
revoke all on function public.admin_lab_run_capabilities(uuid),public.admin_lab_manage_run(uuid,text,uuid),public.admin_lab_operation_stats(timestamptz,timestamptz) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.admin_lab_run_capabilities(uuid),public.admin_lab_manage_run(uuid,text,uuid),public.admin_lab_operation_stats(timestamptz,timestamptz) to authenticated;
revoke all on function essay_ops_private.guard_run_action() from public,anon,authenticated,service_role,essay_worker;
notify pgrst, 'reload schema';
commit;
