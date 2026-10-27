-- NOT APPLIED. Owner approval required. No campaign activation or real grants.
begin;
set local lock_timeout='5s';
do $guard$ begin
if md5(pg_get_functiondef('public.math_session_submit(uuid,uuid,uuid[],uuid)'::regprocedure))<>'a34c4fe9b65a645e02d0ca61fced2603' then raise exception 'BASELINE_CHANGED: public.math_session_submit(uuid,uuid,uuid[],uuid)';end if;
if md5(pg_get_functiondef('essay_private.scaffold_legacy_essay_request_evaluation(uuid,uuid,text)'::regprocedure))<>'28ffc04b579fe1d174172fb37b13d61c' then raise exception 'BASELINE_CHANGED: essay_private.scaffold_legacy_essay_request_evaluation(uuid,uuid,text)';end if;
if md5(pg_get_functiondef('essay_private.scaffold_request_v13(uuid,uuid,text)'::regprocedure))<>'c7434fc61c8e952e633d2b915f670853' then raise exception 'BASELINE_CHANGED: essay_private.scaffold_request_v13(uuid,uuid,text)';end if;
if md5(pg_get_functiondef('essay_private.credit_request_v2(uuid,uuid,text)'::regprocedure))<>'43ba761b2143dcd1187fc6127295e003' then raise exception 'BASELINE_CHANGED: essay_private.credit_request_v2(uuid,uuid,text)';end if;
if md5(pg_get_functiondef('math_private.authorize_billing(uuid)'::regprocedure))<>'0154a967dde40918213692e93cb4f5b0' then raise exception 'BASELINE_CHANGED: math_private.authorize_billing(uuid)';end if;
if md5(pg_get_functiondef('essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)'::regprocedure))<>'ddab49ee9a5682389d0e839c058e6cfb' then raise exception 'BASELINE_CHANGED: essay_exam_private.reserve(uuid,uuid,uuid,jsonb,uuid)';end if;
end $guard$;
-- CANDIDATE ONLY: requires Owner approval. No campaign is activated by this file.
create schema essay_beta_private;
revoke all on schema essay_beta_private from public, anon, authenticated, service_role;

create table essay_beta_private.campaigns (
 id uuid primary key default gen_random_uuid(),
 starts_on date not null,
 ends_on date not null,
 enabled boolean not null default false,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default clock_timestamp(),
 check (ends_on-starts_on between 4 and 6)
);
-- One program at a time. Changing a program never resets a user's daily grant.
create unique index beta_one_enabled on essay_beta_private.campaigns ((true)) where enabled;
create table essay_beta_private.exam_scope (
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 exam_id uuid not null references public.essay_exams(id),
 runtime_policy jsonb not null,
 question_ids uuid[] not null check(cardinality(question_ids)>0),
 has_math boolean not null,
 owner_math_qa_reference text,
 approval_reference text not null check(length(btrim(approval_reference))>0),
 primary key(campaign_id,exam_id),
 check(coalesce(runtime_policy->>'evaluation_type','') in ('humanities','business')),
 check(not has_math or coalesce(length(btrim(owner_math_qa_reference)),0)>0)
);
create table essay_beta_private.daily_grants (
 user_id uuid not null references auth.users(id),
 grant_day date not null,
 campaign_id uuid not null references essay_beta_private.campaigns(id),
 grant_id uuid not null unique references public.credit_grants(id),
 created_at timestamptz not null default clock_timestamp(),
 primary key(user_id,grant_day)
);
alter table essay_beta_private.campaigns enable row level security;
alter table essay_beta_private.exam_scope enable row level security;
alter table essay_beta_private.daily_grants enable row level security;
revoke all on all tables in schema essay_beta_private from public,anon,authenticated,service_role;

create function essay_beta_private.immutable() returns trigger language plpgsql set search_path='' as $$begin raise exception 'BETA_GRANT_BINDING_IMMUTABLE';end $$;
create trigger beta_daily_immutable before update or delete on essay_beta_private.daily_grants
 for each row execute function essay_beta_private.immutable();

create function essay_beta_private.is_beta(p_grant uuid) returns boolean
language sql stable set search_path='' as $$
 select exists(select 1 from essay_beta_private.daily_grants where grant_id=p_grant)
$$;

-- Additional spending restriction. Existing gateway public allowlist, preflight,
-- material approval and provider binding checks remain mandatory and unchanged.
create function essay_beta_private.eligible(p_grant uuid,p_exam uuid) returns boolean
language sql volatile set search_path='' as $$
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
  and (not s.has_math or length(btrim(s.owner_math_qa_reference))>0)
 )
$$;

create function public.essay_beta_daily_claim() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); c essay_beta_private.campaigns; d essay_beta_private.daily_grants;
 a uuid; t timestamptz; day date; expiry timestamptz; g uuid; balance bigint;
begin
 if u is null or account_private.allowed(u) is not true then
  raise sqlstate 'PT403' using message='ACCOUNT_REQUIRED';
 end if;
 if not exists(select 1 from essay_beta_private.campaigns where enabled and (essay_private.clock() at time zone 'Asia/Seoul')::date between starts_on and ends_on) then
  return jsonb_build_object('version','essay-beta-credit-v1','active',false);
 end if;
 perform account_private.lock_subject(u);
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into a from public.credit_accounts where user_id=u for update;
 -- Take the clock AFTER the shared account lock, including concurrent devices.
 t:=essay_private.clock(); day:=(t at time zone 'Asia/Seoul')::date;
 select * into c from essay_beta_private.campaigns where enabled and day between starts_on and ends_on for share;
 if c.id is null then return jsonb_build_object('version','essay-beta-credit-v1','active',false);end if;
 if not exists(select 1 from essay_beta_private.exam_scope where campaign_id=c.id) then
  return jsonb_build_object('version','essay-beta-credit-v1','active',false);
 end if;
 select * into d from essay_beta_private.daily_grants where user_id=u and grant_day=day;
 if d.grant_id is null then
  expiry:=(day+1)::timestamp at time zone 'Asia/Seoul';
  g:=essay_private.credit_post_grant(u,2,'promotion','lab-beta:daily:'||u||':'||day,
   'essay_beta_daily','beta_campaign/'||c.id,expiry);
  insert into essay_beta_private.daily_grants(user_id,grant_day,campaign_id,grant_id) values(u,day,c.id,g);
 else
  g:=d.grant_id;
  select expires_at into expiry from public.credit_grants where id=g;
 end if;
 select greatest(0,coalesce(sum(balance_delta-reserved_delta),0)) into balance
 from public.credit_transactions where grant_id=g;
 return jsonb_build_object('version','essay-beta-credit-v1','active',true,'grant_id',g,'day',day,
  'available',case when expiry>essay_private.clock() and (d.grant_id is null or d.campaign_id=c.id) then balance else 0 end,'expires_at',expiry);
end $$;
revoke all on all functions in schema essay_beta_private from public,anon,authenticated,service_role;
revoke all on function public.essay_beta_daily_claim() from public,anon,service_role;
grant execute on function public.essay_beta_daily_claim() to authenticated;
CREATE OR REPLACE FUNCTION public.math_session_submit(p_exam uuid, p_key uuid, p_attempts uuid[], p_parent uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=auth.uid(); account uuid; r math_private.session_runs; parent math_private.session_runs;
 a public.math_attempts; ids uuid[]; leaves uuid[]; parent_leaves uuid[]; selected_grant uuid;
 rid uuid=gen_random_uuid(); did uuid=gen_random_uuid(); aid uuid; evaluation uuid; catalog jsonb;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u for update;
 if account is null then raise insufficient_privilege;end if;
 if p_key is null or p_exam is null or coalesce(cardinality(p_attempts),0) not between 1 and 100 or array_position(p_attempts,null) is not null then raise invalid_parameter_value;end if;
 select array_agg(v order by v) into ids from unnest(p_attempts) v;
 if cardinality(ids)<>(select count(distinct v) from unnest(ids) v) then raise invalid_parameter_value;end if;
 select * into r from math_private.session_runs where student_id=u and request_key=p_key;
 if found then
  if r.exam_id<>p_exam or r.attempt_ids<>ids or r.parent_id is distinct from p_parent then raise unique_violation using message='SESSION_REPLAY_CONFLICT';end if;
  return r.id;
 end if;
 catalog=public.math_catalog(50);
 foreach aid in array ids loop
  select * into a from public.math_attempts where id=aid and student_id=u for update;
  if a.id is null or exists(select 1 from public.math_evaluations where attempt_id=aid) or exists(select 1 from math_private.session_members where attempt_id=aid) then raise invalid_parameter_value using message='SESSION_INPUT_UNAVAILABLE';end if;
  if (select count(*) from jsonb_array_elements(catalog) x where x->>'leaf_id'=a.leaf_id::text and x->>'essay_exam_id'=p_exam::text and exists(select 1 from public.essay_questions q where q.id=(x->>'essay_question_id')::uuid and q.essay_exam_id=p_exam))<>1 then raise invalid_parameter_value using message='QUESTION_NOT_RELEASED';end if;
  if not exists(select 1 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id where l.id=a.leaf_id and s.essay_exam_id=p_exam and p.state='ACTIVE' and s.state='ACTIVE') then raise invalid_parameter_value using message='QUESTION_NOT_IN_EXAM';end if;
 end loop;
 select array_agg(leaf_id order by leaf_id) into leaves from public.math_attempts where id=any(ids);
 if cardinality(leaves)<>(select count(distinct v) from unnest(leaves) v) then raise invalid_parameter_value;end if;
 if p_parent is not null then
  select * into parent from math_private.session_runs where id=p_parent and student_id=u for update;
  if parent.id is null or parent.exam_id<>p_exam or parent.parent_id is not null or parent.state<>'completed' or clock_timestamp()>=parent.completed_at+interval '336 hours'
    or exists(select 1 from math_private.session_runs where parent_id=parent.id)
    or exists(select 1 from public.credit_transactions where decision_id=parent.decision_id and transaction_type='refund') then raise invalid_parameter_value using message='REEVALUATION_NOT_INCLUDED';end if;
  select array_agg(leaf_id order by leaf_id) into parent_leaves from math_private.session_members where run_id=parent.id;
  if leaves<>parent_leaves then raise invalid_parameter_value using message='FROZEN_QUESTION_SET';end if;
  if exists(select 1 from public.math_attempts child where child.id=any(ids) and not exists(
    select 1 from math_private.session_members pm join math_private.session_evaluations x on x.attempt_id=pm.attempt_id join public.math_evaluations pe on pe.id=x.evaluation_id
    where pm.run_id=parent.id and pm.leaf_id=child.leaf_id and child.predecessor_id=pm.attempt_id and child.prior_evaluation_id=pe.id and pe.state='COMPLETED')) then raise invalid_parameter_value using message='INVALID_REWRITE_SOURCE';end if;
 else
  select g.id into selected_grant from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id) and (g.expires_at is null or g.expires_at>clock_timestamp()) and
   (select coalesce(sum(balance_delta-reserved_delta),0) from public.credit_transactions where grant_id=g.id)>=1 order by g.expires_at nulls last,g.created_at,g.id limit 1 for update;
  if selected_grant is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT';end if;
 end if;
 insert into public.essay_billing_decisions(id,account_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(did,account,rid,'essay-exam-cycle','math-session-v1',case when p_parent is null then 'paid_cycle' else 'included_revision' end,case when p_parent is null then 1 else 0 end,'authorized',parent.decision_id);
 insert into math_private.session_runs(id,student_id,account_id,exam_id,request_key,parent_id,decision_id,attempt_ids) values(rid,u,account,p_exam,p_key,p_parent,did,ids);
 if selected_grant is not null then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(account,selected_grant,did,'reserve',0,1,'math-session:'||rid||':reserve','essay_exam_initial');
  update public.essay_billing_decisions set status='reserved',reserved_at=clock_timestamp() where id=did;
 end if;
 insert into math_private.session_members select rid,ar.id,ar.leaf_id,(x->>'essay_question_id')::uuid from public.math_attempts ar join jsonb_array_elements(catalog) x on x->>'leaf_id'=ar.leaf_id::text where ar.id=any(ids);
 foreach aid in array ids loop
  -- Existing readiness, extraction confirmation, pins, admission and ownership checks.
  evaluation=public.math_request_evaluation(aid,gen_random_uuid());
 end loop;
 return rid;
end$function$
;

CREATE OR REPLACE FUNCTION essay_private.scaffold_legacy_essay_request_evaluation(p_attempt uuid, p_key uuid, p_regime text DEFAULT 'essay-v1.2'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.essay_attempts; e public.essay_evaluations; account uuid; u uuid; snapshot jsonb; criteria jsonb; evidence jsonb; h text; parent public.essay_billing_decisions; b uuid; grant_id uuid; reason text; amount integer=1;
begin
 select * into a from public.essay_attempts where id=p_attempt;
 u=essay_private.owner(a.session_id);
 if p_key is null or p_regime not in ('essay-v1.2','essay-v1.2-next-model') or p_regime is null then raise sqlstate 'PT422' using message='INVALID_REGIME'; end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=u for update;
 perform 1 from public.essay_practice_sessions where id=a.session_id for update;
 perform 1 from public.credit_grants where account_id=account order by id for update;
 h=essay_private.hash(jsonb_build_array(p_attempt,a.body_sha256,p_regime)::text);
 select * into e from public.essay_evaluations where idempotency_key=p_key;
 if e.id is not null then
  if e.request_hash<>h or e.attempt_id<>p_attempt then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return e.id;
 end if;
 select * into e from public.essay_evaluations where attempt_id=p_attempt and regime_key=p_regime and request_kind='student' and status in ('requested','processing','completed');
 if e.id is not null then return e.id; end if;
 select jsonb_agg(jsonb_build_object('id',c.id,'version',c.definition_version) order by c.id) into criteria from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id;
 select jsonb_agg(jsonb_build_object('id',v.id,'role',v.role,'hash',v.source_sha256,'version',v.mapping_version,'locator',v.source_locator) order by v.id) into evidence
 from public.essay_question_evidence v join public.essay_practice_sessions s on s.question_id=v.question_id
 join public.essay_exam_resources m on (m.essay_exam_id,m.resource_id,m.role)=(v.essay_exam_id,v.resource_id,v.role)
 where s.id=a.session_id and v.role in ('question','passage','exam_intent','scoring_criteria') and m.provenance='official' and m.verification_status='verified' and m.is_active;
 if criteria is null or evidence is null or (select count(distinct x->>'role') from jsonb_array_elements(evidence) x)<>4 then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 if exists(select 1 from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id and not exists(select 1 from jsonb_array_elements(evidence) x where (x->>'id')::uuid=c.source_evidence_id)) then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 snapshot=jsonb_build_object('attempt_id',a.id,'answer_hash',a.body_sha256,'criteria',criteria,'evidence',evidence,'contract_version','1.2','model_policy',p_regime,'package_version','deterministic-v1');
 select bd.* into parent from public.essay_billing_decisions bd join public.essay_evaluations ev on ev.id=bd.evaluation_id
 where ev.session_id=a.session_id and bd.status='settled' and bd.reason='paid_cycle' and bd.policy_key='essay_cycle' and bd.policy_version='v1' order by bd.created_at,bd.id limit 1;
 reason=case when parent.id is null then 'paid_cycle' else 'additional_revision' end;
 if parent.id is not null and exists(select 1 from public.essay_evaluations pe join public.essay_attempts pa on pa.id=pe.attempt_id where pe.id=parent.evaluation_id and pa.id<>a.id and pa.submitted_at<=a.submitted_at)
 and not exists(select 1 from public.essay_billing_decisions where included_by_decision_id=parent.id and status in ('authorized','reserved','settled')) then reason='included_revision';amount=0;end if;
 if amount=1 then
  select g.id into grant_id from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id) and (g.expires_at is null or g.expires_at>essay_private.clock())
  and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1 order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if grant_id is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT'; end if;
 end if;
 insert into public.essay_evaluations(attempt_id,session_id,question_id,idempotency_key,request_hash,status,evaluation_version,contract_version,regime_key,evidence_manifest_sha256,evidence_completeness,input_snapshot)
 select a.id,a.session_id,s.question_id,p_key,h,'requested','1.2','1.2',p_regime,essay_private.hash(snapshot::text),'complete',snapshot from public.essay_practice_sessions s where s.id=a.session_id returning * into e;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,e.id,p_key,'essay_cycle','v1',reason,amount,'authorized',case when amount=0 then parent.id end) returning id into b;
 if amount=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(account,grant_id,b,'reserve',0,1,'reserve/'||b::text,'essay_cycle_v1');
  update public.essay_billing_decisions set status='reserved',reserved_at=essay_private.clock() where id=b;
 end if;
 return e.id;
end$function$
;

CREATE OR REPLACE FUNCTION essay_private.scaffold_request_v13(p_attempt uuid, p_key uuid, p_regime text DEFAULT 'essay-v1.2'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.essay_attempts; e public.essay_evaluations; account uuid; u uuid; snapshot jsonb; criteria jsonb; evidence jsonb; h text; parent public.essay_billing_decisions; b uuid; grant_id uuid; reason text; amount integer=1;
begin
 select * into a from public.essay_attempts where id=p_attempt;
 u=essay_private.owner(a.session_id);
 if p_key is null or p_regime not in ('essay-v1.3','essay-v1.3-next-model') or p_regime is null then raise sqlstate 'PT422' using message='INVALID_REGIME'; end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=u for update;
 perform 1 from public.essay_practice_sessions where id=a.session_id for update;
 perform 1 from public.credit_grants where account_id=account order by id for update;
 h=essay_private.hash(jsonb_build_array(p_attempt,a.body_sha256,p_regime)::text);
 select * into e from public.essay_evaluations where idempotency_key=p_key;
 if e.id is not null then
  if e.request_hash<>h or e.attempt_id<>p_attempt then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return e.id;
 end if;
 select * into e from public.essay_evaluations where attempt_id=p_attempt and regime_key=p_regime and request_kind='student' and status in ('requested','processing','completed');
 if e.id is not null then return e.id; end if;
 select jsonb_agg(jsonb_build_object('id',c.id,'version',c.definition_version) order by c.id) into criteria from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id;
 select jsonb_agg(jsonb_build_object('id',v.id,'role',v.role,'hash',v.source_sha256,'version',v.mapping_version,'locator',v.source_locator) order by v.id) into evidence
 from public.essay_question_evidence v join public.essay_practice_sessions s on s.question_id=v.question_id
 join public.essay_exam_resources m on (m.essay_exam_id,m.resource_id,m.role)=(v.essay_exam_id,v.resource_id,v.role)
 where s.id=a.session_id and v.role in ('question','passage','exam_intent','scoring_criteria') and m.provenance='official' and m.verification_status='verified' and m.is_active;
 if criteria is null or evidence is null or (select count(distinct x->>'role') from jsonb_array_elements(evidence) x)<>4 then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 if exists(select 1 from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id and not exists(select 1 from jsonb_array_elements(evidence) x where (x->>'id')::uuid=c.source_evidence_id)) then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 snapshot=jsonb_build_object('attempt_id',a.id,'answer_hash',a.body_sha256,'criteria',criteria,'evidence',evidence,'contract_version','1.3','model_policy',p_regime,'package_version','deterministic-v1');
 snapshot=snapshot||jsonb_build_object('scaffolding_context',essay_private.scaffold_context(a.id,p_regime,criteria,evidence));
 select bd.* into parent from public.essay_billing_decisions bd join public.essay_evaluations ev on ev.id=bd.evaluation_id
 where ev.session_id=a.session_id and bd.status='settled' and bd.reason='paid_cycle' and bd.policy_key='essay_cycle' and bd.policy_version='v1' order by bd.created_at,bd.id limit 1;
 reason=case when parent.id is null then 'paid_cycle' else 'additional_revision' end;
 if parent.id is not null and exists(select 1 from public.essay_evaluations pe join public.essay_attempts pa on pa.id=pe.attempt_id where pe.id=parent.evaluation_id and pa.id<>a.id and pa.submitted_at<=a.submitted_at)
 and not exists(select 1 from public.essay_billing_decisions where included_by_decision_id=parent.id and status in ('authorized','reserved','settled')) then reason='included_revision';amount=0;end if;
 if amount=1 then
  select g.id into grant_id from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id) and (g.expires_at is null or g.expires_at>essay_private.clock())
  and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1 order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if grant_id is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT'; end if;
 end if;
 insert into public.essay_evaluations(attempt_id,session_id,question_id,idempotency_key,request_hash,status,evaluation_version,contract_version,regime_key,evidence_manifest_sha256,evidence_completeness,input_snapshot)
 select a.id,a.session_id,s.question_id,p_key,h,'requested','1.3','1.3',p_regime,essay_private.hash(snapshot::text),'complete',snapshot from public.essay_practice_sessions s where s.id=a.session_id returning * into e;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,e.id,p_key,'essay_cycle','v1',reason,amount,'authorized',case when amount=0 then parent.id end) returning id into b;
 if amount=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(account,grant_id,b,'reserve',0,1,'reserve/'||b::text,'essay_cycle_v1');
  update public.essay_billing_decisions set status='reserved',reserved_at=essay_private.clock() where id=b;
 end if;
 return e.id;
end$function$
;

CREATE OR REPLACE FUNCTION essay_private.credit_request_v2(p_attempt uuid, p_key uuid, p_regime text DEFAULT 'essay-v1.2'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.essay_attempts; e public.essay_evaluations; account uuid; u uuid; snapshot jsonb; criteria jsonb; evidence jsonb; h text; parent public.essay_billing_decisions; b uuid; grant_id uuid; reason text; amount integer=1;
begin
 select * into a from public.essay_attempts where id=p_attempt;
 u=essay_private.owner(a.session_id);
 if p_key is null or p_regime not in ('essay-v1.2','essay-v1.2-next-model','essay-v1.3','essay-v1.3-next-model') or p_regime is null then raise sqlstate 'PT422' using message='INVALID_REGIME'; end if;
 insert into public.credit_accounts(user_id) values(u) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=u for update;
 perform 1 from public.essay_practice_sessions where id=a.session_id for update;
 perform 1 from public.credit_grants where account_id=account order by id for update;
 h=essay_private.hash(jsonb_build_array(p_attempt,a.body_sha256,p_regime)::text);
 select * into e from public.essay_evaluations where idempotency_key=p_key;
 if e.id is not null then
  if e.request_hash<>h or e.attempt_id<>p_attempt then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return e.id;
 end if;
 select * into e from public.essay_evaluations where attempt_id=p_attempt and regime_key=p_regime and request_kind='student' and status in ('requested','processing','completed');
 if e.id is not null then return e.id; end if;
 select jsonb_agg(jsonb_build_object('id',c.id,'version',c.definition_version) order by c.id) into criteria from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id;
 select jsonb_agg(jsonb_build_object('id',v.id,'role',v.role,'hash',v.source_sha256,'version',v.mapping_version,'locator',v.source_locator) order by v.id) into evidence
 from public.essay_question_evidence v join public.essay_practice_sessions s on s.question_id=v.question_id
 join public.essay_exam_resources m on (m.essay_exam_id,m.resource_id,m.role)=(v.essay_exam_id,v.resource_id,v.role)
 where s.id=a.session_id and v.role in ('question','passage','exam_intent','scoring_criteria') and m.provenance='official' and m.verification_status='verified' and m.is_active;
 if criteria is null or evidence is null or (select count(distinct x->>'role') from jsonb_array_elements(evidence) x)<>4 then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 if exists(select 1 from public.essay_evaluation_criteria c join public.essay_practice_sessions s on s.question_id=c.question_id where s.id=a.session_id and not exists(select 1 from jsonb_array_elements(evidence) x where (x->>'id')::uuid=c.source_evidence_id)) then raise sqlstate 'PT422' using message='INVALID_EVIDENCE'; end if;
 if exists(select 1 from public.essay_evaluations where session_id=a.session_id and status in ('requested','processing')) then raise sqlstate 'PT409' using message='EVALUATION_IN_PROGRESS';end if;
 snapshot=jsonb_build_object('attempt_id',a.id,'answer_hash',a.body_sha256,'criteria',criteria,'evidence',evidence,'contract_version',case when p_regime like 'essay-v1.3%' then '1.3' else '1.2' end,'model_policy',p_regime,'package_version','deterministic-v1');
 if p_regime like 'essay-v1.3%' then snapshot=snapshot||jsonb_build_object('scaffolding_context',essay_private.scaffold_context(a.id,p_regime,criteria,evidence));end if;
 select bd.* into parent from public.essay_billing_decisions bd join public.essay_evaluations ev on ev.id=bd.evaluation_id
 where ev.session_id=a.session_id and bd.status='settled' and bd.reason='paid_cycle' and bd.policy_key='essay_cycle' and bd.policy_version='v2'
 and not exists(select 1 from public.essay_billing_decisions ch where ch.included_by_decision_id=bd.id and ch.status in ('authorized','reserved','settled'))
 and not exists(select 1 from public.credit_transactions t where t.decision_id=bd.id and t.transaction_type='refund')
 order by bd.created_at desc,bd.id desc limit 1;
 reason='paid_cycle';
 if parent.id is not null and exists(select 1 from public.essay_evaluations pe join public.essay_attempts pa on pa.id=pe.attempt_id where pe.id=parent.evaluation_id and pa.id<>a.id and pa.submitted_at<a.submitted_at)
 and not exists(select 1 from public.essay_billing_decisions where included_by_decision_id=parent.id and status in ('authorized','reserved','settled')) then reason='included_revision';amount=0;end if;
 if amount=1 then
  select g.id into grant_id from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id) and (g.expires_at is null or g.expires_at>essay_private.clock())
  and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1 order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if grant_id is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT'; end if;
 end if;
 insert into public.essay_evaluations(attempt_id,session_id,question_id,idempotency_key,request_hash,status,evaluation_version,contract_version,regime_key,evidence_manifest_sha256,evidence_completeness,input_snapshot)
 select a.id,a.session_id,s.question_id,p_key,h,'requested',snapshot->>'contract_version',snapshot->>'contract_version',p_regime,essay_private.hash(snapshot::text),'complete',snapshot from public.essay_practice_sessions s where s.id=a.session_id returning * into e;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,e.id,p_key,'essay_cycle','v2',reason,amount,'authorized',case when amount=0 then parent.id end) returning id into b;
 if amount=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(account,grant_id,b,'reserve',0,1,'reserve/'||b::text,'essay_cycle_v2');
  update public.essay_billing_decisions set status='reserved',reserved_at=essay_private.clock() where id=b;
 end if;
 return e.id;
end$function$
;

CREATE OR REPLACE FUNCTION math_private.authorize_billing(uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare e public.math_evaluations; a public.math_attempts; account uuid; parent public.essay_billing_decisions; decision uuid; selected_grant uuid; quantity integer=1; reason text='paid_cycle';
begin
 decision=math_private.session_finance($1,'authorize'); if decision is not null then return decision;end if;
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select * into a from public.math_attempts where id=e.attempt_id;
 if exists(select 1 from public.math_billing_bindings where math_evaluation_id=e.id) then raise unique_violation using message='BINDING_ALREADY_EXISTS';end if;
 if e.state<>'REQUESTED' then raise invalid_parameter_value;end if;
 if e.request_kind='MATH_REEVALUATION' then
  select d.* into parent from public.essay_billing_decisions d
  join public.math_billing_bindings b on b.billing_decision_id=d.id
  join public.math_evaluations pe on pe.id=b.math_evaluation_id
  join public.math_attempts pa on pa.id=pe.attempt_id
  where d.account_id=account and d.status='settled' and d.reason='paid_cycle' and d.policy_key='essay_cycle' and d.policy_version='v2'
   and pa.lineage_id=a.lineage_id and pa.student_id=a.student_id and pa.id<>a.id and pa.created_at<a.created_at
   and pe.state='COMPLETED' and pe.request_kind='MATH_INITIAL_EVALUATION' and clock_timestamp()<pe.completed_at+interval '336 hours'
   and not exists(select 1 from public.essay_billing_decisions ch where ch.included_by_decision_id=d.id and ch.status in ('authorized','reserved','settled'))
   and not exists(select 1 from public.credit_transactions t where t.decision_id=d.id and t.transaction_type='refund')
  order by pe.completed_at desc,pe.id desc limit 1;
  if parent.id is not null then quantity=0;reason='included_revision';end if;
 end if;
 if quantity=1 then
  select g.id into selected_grant from public.credit_grants g where g.account_id=account and not essay_beta_private.is_beta(g.id)
   and (g.expires_at is null or g.expires_at>clock_timestamp())
   and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1
  order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if selected_grant is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT';end if;
 end if;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,null,e.idempotency_key,'essay_cycle','v2',reason,quantity,'authorized',parent.id) returning id into decision;
 insert into public.math_billing_bindings(math_evaluation_id,billing_decision_id,account_id) values(e.id,decision,account);
 if quantity=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(account,selected_grant,decision,'reserve',0,1,'reserve/'||decision::text,'essay_cycle_v2');
  update public.essay_billing_decisions set status='reserved',reserved_at=clock_timestamp() where id=decision;
 end if;
 return decision;
end$function$
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
   (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=cg.id)>=1
   order by case when essay_beta_private.is_beta(cg.id) then 0 else 1 end, cg.expires_at nulls last,cg.created_at,cg.id limit 1 for update;
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
commit;
