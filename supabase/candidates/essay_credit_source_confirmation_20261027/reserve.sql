CREATE OR REPLACE FUNCTION essay_exam_private.reserve(p_account uuid, p_exam uuid, p_key uuid, p_snapshot jsonb, p_parent uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
   (not essay_beta_private.is_beta(cg.id) or essay_beta_private.eligible(cg.id,p_exam)) and
   (cg.expires_at is null or cg.expires_at>clock_timestamp()) and
   not exists(select 1 from public.payment_orders o where o.grant_id=cg.id and o.state='CANCEL_PENDING') and
   (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=cg.id)>=1
   order by case when essay_beta_private.is_beta(cg.id) then 0 else 1 end, cg.expires_at nulls last,cg.created_at,cg.id limit 1 for update;
  -- Check after exact request replay, but before any reservation/Ledger write.
  -- Old clients cannot silently fall back once this account has received beta.
  if nullif(current_setting('legendstudy.confirmed_credit_grant',true),'') is null then
   if current_setting('legendstudy.credit_confirmation_required',true)='true' or exists(select 1 from essay_beta_private.daily_grants d join public.credit_accounts a on a.user_id=d.user_id where a.id=p_account)
   then raise sqlstate 'PT409' using message='CREDIT_SOURCE_CONFIRMATION_REQUIRED';end if;
  elsif g is distinct from nullif(current_setting('legendstudy.confirmed_credit_grant',true),'')::uuid then
   raise sqlstate 'PT409' using message='CREDIT_SOURCE_CHANGED';
  end if;
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
end $function$
;
