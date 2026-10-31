-- REVIEW CANDIDATE ONLY. Does not activate beta.
begin;
do $guard$ begin
if to_regprocedure('essay_beta_private.credit_source(uuid,uuid)') is null or md5(pg_get_functiondef('essay_beta_private.credit_source(uuid,uuid)'::regprocedure))<>'09fc9d66ee9286fac0f6bfed03046d3b' then raise exception 'BASELINE_CHANGED: essay_beta_private.credit_source(uuid,uuid)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres}' from pg_proc where oid='essay_beta_private.credit_source(uuid,uuid)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: essay_beta_private.credit_source(uuid,uuid)';end if;
if to_regprocedure('essay_beta_private.eligible(uuid,uuid)') is null or md5(pg_get_functiondef('essay_beta_private.eligible(uuid,uuid)'::regprocedure))<>'17a33f0897d2a5dd485372fe2ef338ae' then raise exception 'BASELINE_CHANGED: essay_beta_private.eligible(uuid,uuid)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres}' from pg_proc where oid='essay_beta_private.eligible(uuid,uuid)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: essay_beta_private.eligible(uuid,uuid)';end if;
if to_regprocedure('essay_exam_private.finish(uuid,jsonb,boolean)') is null or md5(pg_get_functiondef('essay_exam_private.finish(uuid,jsonb,boolean)'::regprocedure))<>'d97e32341f90484d1d3523265172d6a3' then raise exception 'BASELINE_CHANGED: essay_exam_private.finish(uuid,jsonb,boolean)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres}' from pg_proc where oid='essay_exam_private.finish(uuid,jsonb,boolean)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: essay_exam_private.finish(uuid,jsonb,boolean)';end if;
if to_regprocedure('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)') is null or md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))<>'200db5574ba2d27ce95d34bcbd0534b4' then raise exception 'BASELINE_CHANGED: essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres}' from pg_proc where oid='essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)';end if;
if to_regprocedure('public.credit_summary()') is null or md5(pg_get_functiondef('public.credit_summary()'::regprocedure))<>'b3341a21ddc3262ca1fb7f71103d902f' then raise exception 'BASELINE_CHANGED: public.credit_summary()';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,authenticated=X/postgres}' from pg_proc where oid='public.credit_summary()'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: public.credit_summary()';end if;
if to_regprocedure('public.essay_beta_daily_claim()') is null or md5(pg_get_functiondef('public.essay_beta_daily_claim()'::regprocedure))<>'2b71bb957adc54b5d5b44f9646936f2a' then raise exception 'BASELINE_CHANGED: public.essay_beta_daily_claim()';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,authenticated=X/postgres}' from pg_proc where oid='public.essay_beta_daily_claim()'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: public.essay_beta_daily_claim()';end if;
if to_regprocedure('public.essay_exam_history(uuid)') is null or md5(pg_get_functiondef('public.essay_exam_history(uuid)'::regprocedure))<>'3ad2b3594bde3944d032ae5f46d3989b' then raise exception 'BASELINE_CHANGED: public.essay_exam_history(uuid)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,authenticated=X/postgres}' from pg_proc where oid='public.essay_exam_history(uuid)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: public.essay_exam_history(uuid)';end if;
if to_regprocedure('public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid)') is null or md5(pg_get_functiondef('public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid)'::regprocedure))<>'12763bd92ccc95f16162214941058072' then raise exception 'BASELINE_CHANGED: public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid)';end if;
if (select pg_get_userbyid(proowner)<>'postgres' or proacl::text is distinct from '{postgres=X/postgres,essay_worker=X/postgres}' from pg_proc where oid='public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid)'::regprocedure) then raise exception 'BASELINE_SECURITY_CHANGED: public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid)';end if;
if exists(select 1 from essay_beta_private.daily_grants) or exists(select 1 from essay_beta_private.campaigns) then raise exception 'REVIEW_EXISTING_BETA_HISTORY_FIRST';end if;
end $guard$;
-- OWNER APPLY CANDIDATE. No campaign activation, financial writes or run execution.
alter table essay_beta_private.campaigns drop constraint campaigns_check;
alter table essay_beta_private.campaigns add constraint beta_dates check(ends_on>=starts_on);
alter table essay_beta_private.campaigns add column daily_limit integer not null default 1 check(daily_limit=1);
alter table essay_beta_private.campaigns add column policy_version text not null default 'daily-v2' check(policy_version='daily-v2');
alter table essay_beta_private.campaigns add column notice_id uuid;
alter table essay_beta_private.daily_grants add column revision_cutoff timestamptz not null;
create table essay_beta_private.notice_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 policy_version text not null,
 seen_at timestamptz not null default clock_timestamp(),
 primary key(user_id,campaign_id,policy_version)
);
alter table essay_beta_private.notice_receipts enable row level security;
revoke all on essay_beta_private.notice_receipts from public,anon,authenticated,service_role;

create function essay_beta_private.freeze_campaign() returns trigger language plpgsql set search_path='' as $$
begin
 if (new.starts_on,new.ends_on,new.daily_limit,new.policy_version) is distinct from
    (old.starts_on,old.ends_on,old.daily_limit,old.policy_version)
 and exists(select 1 from essay_beta_private.daily_grants where campaign_id=old.id) then
  raise exception 'BETA_ISSUED_POLICY_IMMUTABLE';
 end if;
 return new;
end $$;
create trigger beta_campaign_policy before update on essay_beta_private.campaigns
 for each row execute function essay_beta_private.freeze_campaign();

-- Funding comes from the existing immutable reserve ledger, never a client flag.
create function essay_beta_private.revision_open(p_run uuid) returns boolean
language sql volatile set search_path='' as $$
 select r.completed_at is not null and essay_private.clock()<=r.completed_at+interval '14 days'
 and not exists(select 1 from public.credit_transactions t join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve' and essay_private.clock()>=d.revision_cutoff)
 from essay_exam_private.runs r where r.id=p_run
$$;
create function essay_beta_private.revision_deadline(p_run uuid) returns timestamptz
language sql stable set search_path='' as $$
 select least(r.completed_at+interval '14 days',
 (select min(d.revision_cutoff) from public.credit_transactions t join essay_beta_private.daily_grants d on d.grant_id=t.grant_id
 where t.decision_id=r.decision_id and t.transaction_type='reserve'))
 from essay_exam_private.runs r where r.id=p_run
$$;

create function public.essay_beta_daily_claim_v2() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 a uuid; t timestamptz; day date; expiry timestamptz; cutoff timestamptz; g uuid; balance bigint;
begin
 if u is null or account_private.allowed(u) is not true then
  raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';
 end if;
 perform account_private.lock_subject(u);
 -- Account creation is kept inside the same transaction as a successful claim.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled order by starts_on desc limit 1 for share;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');end if;
 cutoff:=(c.ends_on+1)::timestamp at time zone 'Asia/Seoul';
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 if day<c.starts_on or not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id and not has_math and runtime_policy->>'evaluation_type'='humanities') then
  return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','inactive');
 end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into a from public.credit_accounts where user_id=u for update;
 -- Sample after both shared locks: a request waiting across midnight uses the new day.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 if t>=cutoff then return jsonb_build_object('version','essay-beta-credit-v2','active',false,'status','ended','ends_at',cutoff);end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 if d.grant_id is null then
  expiry:=(day+1)::timestamp at time zone 'Asia/Seoul';
  g:=essay_private.credit_post_grant(u,1,'promotion','lab-beta:daily:'||u||':'||day,
   'essay_beta_daily','beta_campaign/'||c.id,expiry);
  insert into essay_beta_private.daily_grants(user_id,grant_day,campaign_id,grant_id,revision_cutoff) values(u,day,c.id,g,cutoff);
 else
  g:=d.grant_id;
  select expires_at into expiry from public.credit_grants where id=g;
 end if;
 select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)) into balance from public.credit_transactions where grant_id=g;
 return jsonb_build_object('version','essay-beta-credit-v2','active',true,'status','active','grant_id',g,'day',day,
  'available',case when expiry>essay_private.clock() and (d.grant_id is null or d.campaign_id=c.id) then balance else 0 end,
  'expires_at',expiry,'ends_at',cutoff,'campaign_id',c.id,'policy_version',c.policy_version,'notice_id',c.notice_id,
  'notice_seen',exists(select 1 from essay_beta_private.notice_receipts where user_id=u and campaign_id=c.id and policy_version=c.policy_version));
end $$;
-- Compatibility for the previous clients; new clients require v2 before showing the new policy.
create or replace function public.essay_beta_daily_claim() returns jsonb
language sql security definer set search_path='' as $$
 select public.essay_beta_daily_claim_v2()||jsonb_build_object('version','essay-beta-credit-v1')
$$;
create function public.essay_beta_notice_ack(p_campaign uuid) returns void
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();
begin
 if u is null or account_private.allowed(u) is not true then raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';end if;
 perform account_private.lock_subject(u);
 insert into essay_beta_private.notice_receipts(user_id,campaign_id,policy_version)
 select u,c.id,c.policy_version from essay_beta_private.campaigns c
 where c.id=p_campaign and exists(select 1 from essay_beta_private.daily_grants d where d.user_id=u and d.campaign_id=c.id)
 on conflict do nothing;
end $$;
revoke all on function essay_beta_private.freeze_campaign(),essay_beta_private.revision_open(uuid),essay_beta_private.revision_deadline(uuid) from public,anon,authenticated,service_role;
revoke all on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) from public,anon,service_role;
grant execute on function public.essay_beta_daily_claim_v2(),public.essay_beta_notice_ack(uuid) to authenticated;

CREATE OR REPLACE FUNCTION essay_beta_private.eligible(p_grant uuid, p_exam uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$
 select exists(
  select 1 from essay_beta_private.daily_grants d
  join essay_beta_private.campaigns c on c.id=d.campaign_id
  join essay_beta_private.exam_scope s on s.campaign_id=c.id and s.exam_id=p_exam
  join public.credit_grants g on g.id=d.grant_id
  where d.grant_id=p_grant and c.enabled
  and (essay_private.clock() at time zone 'Asia/Seoul')::date between c.starts_on and c.ends_on
  and d.grant_day=(essay_private.clock() at time zone 'Asia/Seoul')::date
  and g.expires_at>essay_private.clock()
  and s.runtime_policy=essay_exam_private.runtime_policy(p_exam)
  and (select array_agg(q.id order by q.id) from public.essay_questions q where q.essay_exam_id=p_exam)
      =(select array_agg(q order by q) from unnest(s.question_ids) q)
  and not s.has_math and s.runtime_policy->>'evaluation_type'='humanities'
 )
$function$
;
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
   not essay_beta_private.revision_open(parent.id) then raise exception 'REEVALUATION_NOT_INCLUDED';end if;
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
CREATE OR REPLACE FUNCTION public.credit_summary()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=essay_private.uid(); result jsonb;
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 with grants as (
 select g.id,g.origin,g.expires_at,coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved,
 exists(select 1 from public.payment_orders o where o.grant_id=g.id and o.state='CANCEL_PENDING') fenced
 from public.credit_accounts a join public.credit_grants g on g.account_id=a.id
 left join public.credit_transactions t on t.grant_id=g.id where a.user_id=u and not essay_beta_private.is_beta(g.id)
 group by g.id
 ), spend as(select *,greatest(0,balance-reserved) available from grants where (expires_at is null or expires_at>statement_timestamp()) and not fenced)
 select jsonb_build_object('dto_version','credit-v1','as_of',statement_timestamp(),
 'spendable',coalesce(sum(available),0),'paid',coalesce(sum(available) filter(where origin='purchase'),0),
 'free',coalesce(sum(available) filter(where origin='signup_bonus'),0),
 'other',coalesce(sum(available) filter(where origin not in ('purchase','signup_bonus')),0),
 'reserved',coalesce(sum(reserved),0),'next_expiry',min(expires_at) filter(where available>0)) into result from spend;
 return result;
end$function$
;
CREATE OR REPLACE FUNCTION public.essay_exam_history(p_run uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); account uuid; result jsonb;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u;
 select coalesce(jsonb_agg(x.row order by x.created_at desc,x.id desc),'[]'::jsonb) into result from (
 select r.id,r.created_at,jsonb_build_object('id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,
 'university',v.name,'year',e.admission_year,'title',e.exam_name,'state',r.state,
 'created_at',r.created_at,'completed_at',r.completed_at,
 'previous_paid_run_id',r.previous_paid_run_id,'submission_index',r.submission_index,
 'continuous_cycles_supported',true,
 'question_ids',(select jsonb_agg(a->'questionId' order by a->>'questionId') from jsonb_array_elements(r.snapshot->'answers') a),
 'answers',case when p_run is not null then r.snapshot->'answers' else null end,
 'result',case when p_run is not null and r.result is not null then
  jsonb_set(r.result,'{questions}',(select jsonb_agg(jsonb_set(q-'telemetry','{evaluation}',(q->'evaluation')-'local_reviews')) from jsonb_array_elements(r.result->'questions') q)) else null end,
 'free_rewrite_expires_at',essay_beta_private.revision_deadline(r.id),
 'free_rewrite_available',r.state='completed' and r.parent_id is null and essay_beta_private.revision_open(r.id)
 and not exists(select 1 from essay_exam_private.runs c where c.parent_id=r.id and c.state<>'failed')
 and not exists(select 1 from public.credit_transactions t where t.decision_id=r.decision_id and t.transaction_type='refund')) as row
 from essay_exam_private.runs r join public.essay_exams e on e.id=r.exam_id join public.universities v on v.id=e.university_id
 where r.account_id=account and (p_run is null or r.id=p_run)
 order by r.created_at desc,r.id desc limit 50) x;
 return jsonb_build_object('version','essay-exam-history-v1','runs',result);
end$function$
;
CREATE OR REPLACE FUNCTION public.essay_exam_quote(p_subject uuid, p_exam uuid, p_questions uuid[], p_parent uuid DEFAULT NULL::uuid, p_previous uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare account uuid; r essay_exam_private.runs; keys uuid[];
begin
 perform math_private.require_active(array[p_subject]);
 perform public.essay_exam_preflight(p_subject,p_exam);
 select id into account from public.credit_accounts where user_id=p_subject;
 if account is null then raise exception 'ACCOUNT_UNAVAILABLE';end if;
 select array_agg(q order by q) into keys from unnest(p_questions) q;
 if coalesce(cardinality(keys),0)=0 or cardinality(keys)<>(select count(distinct q) from unnest(keys) q)
 or exists(select 1 from unnest(keys) q where not exists(select 1 from public.essay_questions where id=q and essay_exam_id=p_exam)) then raise exception 'INVALID_QUESTION_SET';end if;
 if p_parent is not null and p_previous is not null then raise exception 'INVALID_PAID_CYCLE';end if;
 if coalesce(p_parent,p_previous) is not null then
  select * into r from essay_exam_private.runs where id=coalesce(p_parent,p_previous) and account_id=account;
  if r.id is null or r.exam_id<>p_exam or r.parent_id is not null or r.state<>'completed'
  or keys is distinct from (select array_agg((x->>'questionId')::uuid order by (x->>'questionId')::uuid) from jsonb_array_elements(r.snapshot->'answers') x)
  or exists(select 1 from public.credit_transactions where decision_id=r.decision_id and transaction_type='refund') then raise exception 'INVALID_CYCLE_SOURCE';end if;
  if p_parent is not null and (not essay_beta_private.revision_open(r.id) or exists(select 1 from essay_exam_private.runs where parent_id=r.id and state<>'failed')) then raise exception 'REEVALUATION_NOT_INCLUDED';end if;
  if p_previous is not null and exists(select 1 from essay_exam_private.runs where (previous_paid_run_id=r.id and parent_id is null or parent_id=r.id) and state='reserved' or previous_paid_run_id=r.id and parent_id is null and state='completed') then raise exception 'PAID_CYCLE_ALREADY_STARTED';end if;
 end if;
 return jsonb_build_object('version','essay-exam-quote-v1','credits',case when p_parent is null then 1 else 0 end,
 'free_rewrite_expires_at',case when p_parent is not null then essay_beta_private.revision_deadline(p_parent) end,
 'kind',case when p_parent is not null then 'included' when p_previous is not null then 'additional' else 'initial' end,'question_ids',to_jsonb(keys));
end$function$
;
commit;
