-- OWNER APPROVAL REQUIRED. Installs a disabled exam API; no model/exam activation,
-- Provider call, seed, reservation or Credit posting is performed by this SQL.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
do $preflight$
begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user)
 or not (select rolbypassrls from pg_roles where rolname=current_user)
 then raise exception 'REVIEWED_POSTGRES_CONTEXT_REQUIRED';end if;
 if to_regnamespace('essay_exam_private') is not null
 or to_regprocedure('essay_private.provider_policy(text)') is not null
 or to_regprocedure('essay_private.provider_binding_valid(text,jsonb)') is not null
 then raise exception 'EXAM_API_ALREADY_INSTALLED_OR_DRIFT';end if;
 if to_regprocedure('math_private.require_active(uuid[])') is null
 or to_regprocedure('public.essay_material_runtime_package(uuid,text)') is null
 or to_regclass('public.credit_transactions') is null
 then raise exception 'EXAM_API_DEPENDENCY_MISSING';end if;
end $preflight$;
-- Source: install.sql

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

-- Source: provider-policy.sql

create function essay_private.provider_policy(p_regime text) returns jsonb
language sql immutable set search_path='' as $$select null::jsonb$$;

-- Content-addressed relation prevents changing a model while retaining the same regime.
create function essay_private.provider_binding_valid(p_regime text,b jsonb) returns boolean
language plpgsql immutable set search_path='' as $$
declare k text;
begin
 if b is null or jsonb_typeof(b)<>'object' or b-array['policy_version','provider','model','model_version','prompt_version','contract_version']<>'{}'::jsonb
 or b->>'contract_version' is distinct from '1.3' then return false;end if;
 foreach k in array array['policy_version','provider','model','model_version','prompt_version','contract_version'] loop
  if jsonb_typeof(b->k) is distinct from 'string' or not ((b->>k) ~ '^[A-Za-z0-9][A-Za-z0-9._:/+-]{0,159}$') then return false;end if;
 end loop;
 if b->>'provider'='unconfigured' or b->>'model'='unconfigured' then return false;end if;
 return coalesce(p_regime='essay-v1.3/policy/'||pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(b::text,'UTF8')),'hex'),false);
end$$;


revoke all on function essay_private.provider_policy(text),essay_private.provider_binding_valid(text,jsonb) from public,anon,authenticated,service_role,essay_worker;

-- Source: api.sql

create function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb
language sql stable set search_path='' as $$select null::jsonb$$;
revoke all on function essay_exam_private.runtime_policy(uuid) from public,anon,authenticated,service_role,essay_worker;
alter table essay_exam_private.runs add column dispatch_key uuid,
 add column lease_token uuid, add column lease_until timestamptz;
create or replace function essay_exam_private.guard() returns trigger language plpgsql set search_path='' as $$
begin
 if old.state<>'reserved' or new.state not in ('reserved','completed','failed') or
 (to_jsonb(old)-array['state','result','completed_at','dispatch_key','lease_token','lease_until']) is distinct from
 (to_jsonb(new)-array['state','result','completed_at','dispatch_key','lease_token','lease_until']) or
 (old.dispatch_key is not null and (old.dispatch_key,old.lease_token,old.lease_until) is distinct from
 (new.dispatch_key,new.lease_token,new.lease_until)) then raise exception 'EXAM_RUN_IMMUTABLE';end if;
 return new;
end$$;

create function public.essay_exam_preflight(p_subject uuid,p_exam uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare policy jsonb; binding jsonb; pkg jsonb;
begin
 perform math_private.require_active(array[p_subject]);
 policy=essay_exam_private.runtime_policy(p_exam);
 if policy is null or coalesce(policy->>'evaluation_type','') not in ('humanities','business') then raise sqlstate 'PT403' using message='EXAM_NOT_ACTIVATED';end if;
 binding=essay_private.provider_policy(policy->>'regime');
 if not essay_private.provider_binding_valid(policy->>'regime',binding) then raise sqlstate 'PT422' using message='MODEL_POLICY_NOT_APPROVED';end if;
 pkg=public.essay_material_runtime_package(p_exam,policy->>'package_digest');
 return policy||jsonb_build_object('binding',binding);
end$$;
revoke all on function public.essay_exam_preflight(uuid,uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_preflight(uuid,uuid) to essay_worker;

-- Caller is the private gateway, after online Auth + existing allowlist verification.
-- Client supplies answers/key only, never a model, criterion version or credit cost.
create function public.essay_exam_submit(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_parent uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare account uuid; policy jsonb; pkg jsonb; binding jsonb; snap jsonb; answers jsonb;
 e public.essay_exams; version text; q jsonb; parent essay_exam_private.runs;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 if account is null then raise sqlstate 'PT403' using message='ACCOUNT_UNAVAILABLE';end if;
 policy=essay_exam_private.runtime_policy(p_exam);
 if policy is null or coalesce(policy->>'evaluation_type','') not in ('humanities','business') then raise sqlstate 'PT403' using message='EXAM_NOT_ACTIVATED';end if;
 binding=essay_private.provider_policy(policy->>'regime');
 if not essay_private.provider_binding_valid(policy->>'regime',binding) then
 raise sqlstate 'PT422' using message='MODEL_POLICY_NOT_APPROVED';end if;
 pkg=public.essay_material_runtime_package(p_exam,policy->>'package_digest');
 select * into e from public.essay_exams where id=p_exam;
 if e.id is null or pkg->>'university_id' is distinct from e.university_id::text then raise sqlstate 'PT422';end if;
 version='material-'||(pkg->>'package_version')||'-'||(pkg->>'package_digest');
 if jsonb_typeof(p_answers) is distinct from 'array' or jsonb_array_length(p_answers) not between 1 and 100 then raise sqlstate 'PT422' using message='INVALID_ANSWERS';end if;
 for q in select value from jsonb_array_elements(p_answers) loop
  if jsonb_typeof(q) is distinct from 'object' or q-array['questionId','body','revision']<>'{}'::jsonb or
    not exists(select 1 from jsonb_array_elements(pkg->'questions') x where x->>'question_id'=q->>'questionId')
  then raise sqlstate 'PT422' using message='QUESTION_NOT_IN_PACKAGE';end if;
 end loop;
 if p_parent is not null then
  select * into parent from essay_exam_private.runs where id=p_parent and account_id=account;
  -- Cross-platform local Draft counters are not revision authority. Pin a
  -- rewrite revision to its immutable stored parent, independently of the client.
  select jsonb_agg(x||jsonb_build_object('revision',coalesce((select (a->>'revision')::bigint + case when a->>'body' is distinct from x->>'body' then 1 else 0 end from jsonb_array_elements(parent.snapshot->'answers') a where a->>'questionId'=x->>'questionId'),0)))
  into p_answers from jsonb_array_elements(p_answers) x;
 end if;
 select jsonb_agg(x||jsonb_build_object('rubricVersion',version,'evidenceVersion',version) order by x->>'questionId')
 into answers from jsonb_array_elements(p_answers) x;
 snap=jsonb_build_object('version','essay-exam-unit-v1','ownerId',p_subject,'examId',p_exam,
 'universityId',e.university_id,'kind',case when e.exam_kind='mock' then 'MOCK_ESSAY' else 'REGULAR_ADMISSION_ESSAY' end,
 'year',e.admission_year,'track',pkg->'exam_identity'->>'track','session',e.session_label,'campus',e.campus,
 'answers',answers,'runtime',jsonb_build_object('package_digest',pkg->>'package_digest','regime',policy->>'regime','binding',binding,'evaluation_type',policy->>'evaluation_type'));
 -- reserve owns exact request replay, frozen rewrite set/version, 14 days and 1 Credit.
 return essay_exam_private.reserve(account,p_exam,p_key,snap,p_parent);
end$$;

create function public.essay_exam_claim(p_subject uuid,p_run uuid,p_dispatch uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; account uuid;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_dispatch is null then raise sqlstate 'PT403';end if;
 if r.state<>'reserved' then return jsonb_build_object('state',r.state,'run_id',r.id);end if;
 if r.dispatch_key is null then
  update essay_exam_private.runs set dispatch_key=p_dispatch,lease_token=gen_random_uuid(),lease_until=clock_timestamp()+interval '15 minutes'
  where id=r.id returning * into r;
 elsif r.dispatch_key<>p_dispatch then
  raise sqlstate 'PT409' using message='RECONCILIATION_REQUIRED';
 end if;
 return jsonb_build_object('state','reserved','dispatch_allowed',r.lease_until>clock_timestamp(),'run_id',r.id,'subject_id',p_subject,'exam_id',r.exam_id,
 'snapshot',r.snapshot,'parent_id',r.parent_id,'parent_result',(select p.result from essay_exam_private.runs p where p.id=r.parent_id and p.account_id=r.account_id),'lease_token',r.lease_token,'lease_until',r.lease_until);
end$$;

create function public.essay_exam_finish(p_subject uuid,p_run uuid,p_token uuid,p_result jsonb,p_failed boolean default false)
returns text language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; account uuid;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;
 -- Lease is immutable and can never be reassigned. A reviewed checkpoint may
 -- settle after dispatch expiry using its exact original token, without redispatch.
 return essay_exam_private.finish(p_run,p_result,p_failed);
end$$;

-- Both platforms read this owner-scoped projection of existing exam runs.
-- No lease, internal reviewer receipts, model input or private source PDF is exposed.
create function public.essay_exam_history(p_run uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); account uuid; result jsonb;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u;
 select coalesce(jsonb_agg(x.row order by x.created_at desc,x.id desc),'[]'::jsonb) into result from (
 select r.id,r.created_at,jsonb_build_object('id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,
 'university',v.name,'year',e.admission_year,'title',e.exam_name,'state',r.state,
 'created_at',r.created_at,'completed_at',r.completed_at,
 'question_ids',(select jsonb_agg(a->'questionId' order by a->>'questionId') from jsonb_array_elements(r.snapshot->'answers') a),
 'answers',case when p_run is not null then r.snapshot->'answers' else null end,
 'result',case when p_run is not null and r.result is not null then
  jsonb_set(r.result,'{questions}',(select jsonb_agg(jsonb_set(q-'telemetry','{evaluation}',(q->'evaluation')-'local_reviews')) from jsonb_array_elements(r.result->'questions') q)) else null end,
 'free_rewrite_available',r.state='completed' and r.parent_id is null and clock_timestamp()<=r.completed_at+interval '14 days'
 and not exists(select 1 from essay_exam_private.runs c where c.parent_id=r.id and c.state<>'failed')
 and not exists(select 1 from public.credit_transactions t where t.decision_id=r.decision_id and t.transaction_type='refund')) as row
 from essay_exam_private.runs r join public.essay_exams e on e.id=r.exam_id join public.universities v on v.id=e.university_id
 where r.account_id=account and (p_run is null or r.id=p_run)
 order by r.created_at desc,r.id desc limit 50) x;
 return jsonb_build_object('version','essay-exam-history-v1','runs',result);
end$$;

-- No student write/claim/finance grant. The verified gateway forwards caller identity.
revoke all on function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid),
 public.essay_exam_claim(uuid,uuid,uuid),public.essay_exam_finish(uuid,uuid,uuid,jsonb,boolean),
 public.essay_exam_history(uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid),
 public.essay_exam_claim(uuid,uuid,uuid),public.essay_exam_finish(uuid,uuid,uuid,jsonb,boolean) to essay_worker;
grant execute on function public.essay_exam_history(uuid) to authenticated;
-- Follow the existing credit-account anonymization lifecycle; retain Ledger facts.
create function essay_exam_private.erase_account_runs() returns trigger
language plpgsql security definer set search_path='' as $$
declare r record;
begin
 if old.user_id is not null and new.user_id is null then
  for r in select id from essay_exam_private.runs where account_id=old.id and state='reserved' order by id for update loop
   perform essay_exam_private.finish(r.id,null,true);
  end loop;
  delete from essay_exam_private.runs where account_id=old.id;
 end if;
 return new;
end$$;
revoke all on function essay_exam_private.erase_account_runs() from public,anon,authenticated,service_role,essay_worker;
create trigger essay_exam_account_erasure before update of user_id on public.credit_accounts
 for each row execute function essay_exam_private.erase_account_runs();

commit;
