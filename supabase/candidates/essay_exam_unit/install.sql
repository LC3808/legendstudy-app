-- LOCAL CANDIDATE ONLY. No public RPC, role grant, activation or production apply.
-- Trusted runtime must supply Auth-verified account, reviewed snapshot and output.
-- Invoker functions intentionally remain inaccessible to API/worker roles until
-- lifecycle, content authority and deployment ownership integration are reviewed.
begin;
create schema essay_exam_private;
revoke all on schema essay_exam_private from public,anon,authenticated,service_role;
create table essay_exam_private.runs (
 id uuid primary key,
 account_id uuid not null references public.credit_accounts(id),
 exam_id uuid not null references public.essay_exams(id),
 parent_id uuid references essay_exam_private.runs(id),
 decision_id uuid not null unique references public.essay_billing_decisions(id),
 request_key uuid not null,
 snapshot jsonb not null,
 state text not null check(state in ('reserved','completed','failed')),
 result jsonb,
 created_at timestamptz not null default clock_timestamp(),
 completed_at timestamptz,
 unique(account_id,request_key),
 check((state='completed')=(result is not null and completed_at is not null))
);
create index exam_runs_account_time on essay_exam_private.runs(account_id,created_at desc,id desc);
create unique index exam_included_once on essay_exam_private.runs(parent_id) where parent_id is not null and state<>'failed';
alter table essay_exam_private.runs enable row level security;
alter table essay_exam_private.runs force row level security;
revoke all on essay_exam_private.runs from public,anon,authenticated,service_role;
create function essay_exam_private.guard() returns trigger language plpgsql set search_path='' as $$
begin
 if old.state<>'reserved' or new.state not in ('completed','failed') or
 (to_jsonb(old)-array['state','result','completed_at']) is distinct from
 (to_jsonb(new)-array['state','result','completed_at']) then
 raise exception 'EXAM_RUN_IMMUTABLE';end if;
 return new;
end $$;
create trigger exam_run_immutable before update on essay_exam_private.runs
 for each row execute function essay_exam_private.guard();

-- Answers are normalized by the existing freezeExam contract. The DB independently
-- checks nonempty distinct question membership and answers; reevaluation preserves
-- pinned versions. Initial content/version authority remains a runtime prerequisite.
create function essay_exam_private.reserve(p_account uuid,p_exam uuid,p_key uuid,p_snapshot jsonb,p_parent uuid default null)
returns uuid language plpgsql set search_path='' as $$
declare r essay_exam_private.runs; parent essay_exam_private.runs; q jsonb; g uuid;
 rid uuid=gen_random_uuid(); did uuid=gen_random_uuid(); n integer; keys jsonb; parentkeys jsonb;
begin
 perform 1 from public.credit_accounts where id=p_account and user_id is not null for update;
 if not found then raise exception 'ACCOUNT_UNAVAILABLE';end if;
 select * into r from essay_exam_private.runs where account_id=p_account and request_key=p_key;
 if found then
  if r.exam_id<>p_exam or r.parent_id is distinct from p_parent or r.snapshot is distinct from p_snapshot then
   raise exception 'IDEMPOTENCY_CONFLICT';end if;
  return r.id;
 end if;
 if p_key is null or p_snapshot is null or jsonb_typeof(p_snapshot)<>'object' or
 jsonb_typeof(p_snapshot->'answers') is distinct from 'array' then raise exception 'INVALID_SNAPSHOT';end if;
 n=jsonb_array_length(p_snapshot->'answers');
 if n<1 or n>100 then raise exception 'INVALID_QUESTION_SET';end if;
 select jsonb_agg(x->>'questionId' order by x->>'questionId') into keys from jsonb_array_elements(p_snapshot->'answers') x;
 if (select count(distinct x->>'questionId') from jsonb_array_elements(p_snapshot->'answers') x)<>n then
 raise exception 'INVALID_QUESTION_SET';end if;
 for q in select value from jsonb_array_elements(p_snapshot->'answers') loop
  if not exists(select 1 from public.essay_questions where id=(q->>'questionId')::uuid and essay_exam_id=p_exam) then
   raise exception 'QUESTION_NOT_IN_EXAM';end if;
  if jsonb_typeof(q->'body') is distinct from 'string' or length(btrim(q->>'body'))=0 or length(q->>'body')>30000 or
   coalesce(q->>'revision','') !~ '^[0-9]+$' or coalesce(q->>'rubricVersion','')='' or coalesce(q->>'evidenceVersion','')='' then
   raise exception 'INVALID_ANSWER';end if;
 end loop;
 if p_parent is not null then
  select * into parent from essay_exam_private.runs where id=p_parent and account_id=p_account for update;
  if not found or parent.exam_id<>p_exam or parent.parent_id is not null or parent.state<>'completed' or
   clock_timestamp()>parent.completed_at+interval '14 days' then raise exception 'REEVALUATION_NOT_INCLUDED';end if;
  if exists(select 1 from essay_exam_private.runs where parent_id=p_parent and state in ('reserved','completed')) then
   raise exception 'REEVALUATION_ALREADY_USED';end if;
  if exists(select 1 from public.credit_transactions where decision_id=parent.decision_id and transaction_type='refund') then
   raise exception 'REEVALUATION_NOT_INCLUDED';end if;
  select jsonb_agg(x->>'questionId' order by x->>'questionId') into parentkeys from jsonb_array_elements(parent.snapshot->'answers') x;
  if keys is distinct from parentkeys or (p_snapshot-'answers') is distinct from (parent.snapshot-'answers') then
   raise exception 'FROZEN_QUESTION_SET';end if;
  if exists(select 1 from jsonb_array_elements(p_snapshot->'answers') a join jsonb_array_elements(parent.snapshot->'answers') b
    on a->>'questionId'=b->>'questionId' where
    a->>'rubricVersion' is distinct from b->>'rubricVersion' or a->>'evidenceVersion' is distinct from b->>'evidenceVersion' or
    (a->>'revision')::bigint<(b->>'revision')::bigint or
    (a->>'body'<>b->>'body' and (a->>'revision')::bigint<=(b->>'revision')::bigint)) then
   raise exception 'STALE_REVISION_OR_CONTEXT';end if;
 else
  select cg.id into g from public.credit_grants cg where cg.account_id=p_account and
   (cg.expires_at is null or cg.expires_at>clock_timestamp()) and
   (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=cg.id)>=1
   order by cg.expires_at nulls last,cg.created_at,cg.id limit 1 for update;
  if g is null then raise exception 'INSUFFICIENT_CREDIT';end if;
 end if;
 insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,reserved_at,included_by_decision_id)
 values(did,p_account,did,'essay-exam-cycle','candidate-v1',case when p_parent is null then 'paid_cycle' else 'included_revision' end,
 case when p_parent is null then 1 else 0 end,'reserved',clock_timestamp(),parent.decision_id);
 insert into essay_exam_private.runs(id,account_id,exam_id,parent_id,decision_id,request_key,snapshot,state)
 values(rid,p_account,p_exam,p_parent,did,p_key,p_snapshot,'reserved');
 if g is not null then
 insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
 values(p_account,g,did,'reserve',0,1,'exam:'||did||':reserve','essay_exam_initial');end if;
 return rid;
end $$;

-- The reviewed runtime's validation is still required. This boundary additionally
-- refuses missing/extra/duplicate question results and stale Rubric/Evidence pins.
create function essay_exam_private.finish(p_run uuid,p_result jsonb,p_failed boolean default false)
returns text language plpgsql set search_path='' as $$
declare r essay_exam_private.runs; account_key uuid; t public.credit_transactions; target text;
begin
 if p_failed is null or (p_failed and p_result is not null) then raise exception 'INVALID_FINALIZATION';end if;
 select account_id into account_key from essay_exam_private.runs where id=p_run;
 perform 1 from public.credit_accounts where id=account_key for update;
 select * into r from essay_exam_private.runs where id=p_run for update;
 if not found then raise exception 'EXAM_NOT_FOUND';end if;
 target=case when p_failed then 'failed' else 'completed' end;
 if r.state<>'reserved' then
  if r.state=target and r.result is not distinct from p_result then return r.state;end if;
  raise exception 'FINALIZATION_CONFLICT';end if;
 if not p_failed then
  if jsonb_typeof(p_result) is distinct from 'object' or jsonb_typeof(p_result->'questions') is distinct from 'array' or
   jsonb_typeof(p_result->'summary') is distinct from 'string' or length(btrim(p_result->>'summary'))=0 then
   raise exception 'INCOMPLETE_EXAM_RESULT';end if;
  if jsonb_array_length(p_result->'questions')<>jsonb_array_length(r.snapshot->'answers') or
   (select count(distinct x->>'questionId') from jsonb_array_elements(p_result->'questions') x)<>jsonb_array_length(r.snapshot->'answers') or
   exists(select 1 from jsonb_array_elements(r.snapshot->'answers') a where not exists(
    select 1 from jsonb_array_elements(p_result->'questions') q where q->>'questionId'=a->>'questionId' and
     q->>'rubricVersion'=a->>'rubricVersion' and q->>'evidenceVersion'=a->>'evidenceVersion' and
     jsonb_typeof(q->'evaluation')='object' and q->'evaluation'<>'{}'::jsonb)) then
   raise exception 'INCOMPLETE_EXAM_RESULT';end if;
 end if;
 for t in select * from public.credit_transactions where decision_id=r.decision_id and transaction_type='reserve' loop
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(r.account_id,t.grant_id,r.decision_id,case when p_failed then 'release' else 'consume' end,
   case when p_failed then 0 else -t.reserved_delta end,-t.reserved_delta,
   'exam:'||r.decision_id||case when p_failed then ':release' else ':consume' end,'essay_exam_finalization');
 end loop;
 update public.essay_billing_decisions set status=case when p_failed then 'released' else 'settled' end,
  released_at=case when p_failed then clock_timestamp() end,settled_at=case when not p_failed then clock_timestamp() end where id=r.decision_id;
 update essay_exam_private.runs set state=target,result=p_result,completed_at=case when not p_failed then clock_timestamp() end where id=p_run;
 return target;
end $$;
revoke all on all functions in schema essay_exam_private from public,anon,authenticated,service_role;
commit;
