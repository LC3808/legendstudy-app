-- Growth G1: authorized implementation; NOT APPLIED TO PRODUCTION.
-- No AI/IAP/telemetry/real student fixture. Existing histories remain immutable.
begin;
grant essay_executor to current_user;
grant create on schema public,essay_private to essay_executor;
-- Existing sessions pin v1; subsequent inserts default v2. No existing fact UPDATE.
alter table public.essay_practice_sessions add column billing_policy_version text not null default 'v1'
 check(billing_policy_version in ('v1','v2'));
alter table public.essay_practice_sessions alter column billing_policy_version set default 'v2';
alter table public.credit_grants drop constraint credit_grants_origin_check;
alter table public.credit_grants add constraint credit_grants_origin_check check(origin in
 ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program'));
alter table public.credit_transactions drop constraint credit_transactions_transaction_type_check;
alter table public.credit_transactions add constraint credit_transactions_transaction_type_check check(transaction_type in
 ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program','reserve','consume','release','refund','expiration','adjustment'));
-- Preserve existing balance/sign checks and extend only positive grant postings.
alter table public.credit_transactions drop constraint credit_transactions_check;
alter table public.credit_transactions add constraint credit_transactions_check check(
 (transaction_type in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program','refund') and balance_delta>0 and reserved_delta=0)
 or (transaction_type='reserve' and balance_delta=0 and reserved_delta>0 and decision_id is not null)
 or (transaction_type='consume' and balance_delta<0 and reserved_delta=balance_delta and decision_id is not null)
 or (transaction_type='release' and balance_delta=0 and reserved_delta<0 and decision_id is not null)
 or (transaction_type='expiration' and balance_delta<0 and reserved_delta=0)
 or (transaction_type='adjustment' and balance_delta<>0 and reserved_delta=0));
create unique index credit_signup_once_per_account on public.credit_grants(account_id) where origin='signup_bonus';
alter table public.credit_grants add constraint credit_signup_reference_required check(origin<>'signup_bonus' or external_reference is not null);
create unique index essay_v2_included_once on public.essay_billing_decisions(included_by_decision_id)
 where policy_key='essay_cycle' and policy_version='v2' and included_by_decision_id is not null and status in ('authorized','reserved','settled');
grant insert on public.credit_grants to essay_executor;

-- Capture activation time once, not a moving now() eligibility threshold. No existing-user backfill.
-- Like existing uid bridge, owner is migration login; executor receives only this boolean capability.
do $install$ begin
 execute format($sql$create function essay_private.credit_signup_eligible(p_user uuid) returns boolean
 language sql stable security definer set search_path='' as $fn$
 select exists(select 1 from auth.users where id=p_user and created_at >= %L::timestamptz)
 $fn$$sql$,clock_timestamp());
end $install$;
revoke all on function essay_private.credit_signup_eligible(uuid) from public,anon,authenticated,service_role,essay_worker,essay_finance;
grant execute on function essay_private.credit_signup_eligible(uuid) to essay_executor;

-- Internal atomic grant posting. Caller cannot supply the signup key through manual RPC.
create function essay_private.credit_post_grant(p_user uuid,p_quantity integer,p_origin text,p_key text,p_reason text,p_actor text,p_expires timestamptz) returns uuid
language plpgsql security definer set search_path='' as $$
declare account uuid; g public.credit_grants; t public.credit_transactions;
begin
 if p_user is null or p_quantity is null or p_quantity<=0 or p_quantity>100000
 or p_origin is null or p_origin not in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program')
 or nullif(btrim(p_key),'') is null or length(p_key)>200 or nullif(btrim(p_reason),'') is null or nullif(btrim(p_actor),'') is null
 or not exists(select 1 from public.profiles where id=p_user) then raise sqlstate 'PT422' using message='INVALID_GRANT';end if;
 insert into public.credit_accounts(user_id) values(p_user) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=p_user for update;
 select * into g from public.credit_grants where external_reference=p_key;
 if g.id is not null then
  select * into t from public.credit_transactions where idempotency_key='grant/'||p_key;
  if g.account_id is distinct from account or g.origin is distinct from p_origin or g.expires_at is distinct from p_expires
  or t.balance_delta is distinct from p_quantity or t.reason_code is distinct from p_reason or t.actor_reference is distinct from p_actor
  then raise sqlstate 'PT409' using message='CONFLICT';end if;return g.id;
 end if;
 if p_expires is not null and p_expires<=essay_private.clock() then raise sqlstate 'PT422' using message='INVALID_EXPIRY';end if;
 insert into public.credit_grants(account_id,origin,external_reference,expires_at) values(account,p_origin,p_key,p_expires) returning * into g;
 insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
 values(account,g.id,p_origin,p_quantity,0,'grant/'||p_key,p_reason,p_actor);
 return g.id;
exception when unique_violation then raise sqlstate 'PT409' using message='CONFLICT';
end$$;
-- Authenticated own-user retry/recovery. Grants only post-activation auth identities, never providers/devices.
create function public.essay_claim_signup_credit() returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid();begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 if not essay_private.credit_signup_eligible(u) then raise sqlstate 'PT403' using message='SIGNUP_NOT_ELIGIBLE';end if;
 return essay_private.credit_post_grant(u,3,'signup_bonus','signup_bonus/'||u::text,'signup_bonus_v1','system/signup_bonus',null);
end$$;
-- New profile provisioning and +3 share the signup transaction. No auth schema trigger/mutation.
create function essay_private.credit_profile_signup() returns trigger language plpgsql security definer set search_path='' as $$begin
 if essay_private.credit_signup_eligible(new.id) then
 perform essay_private.credit_post_grant(new.id,3,'signup_bonus','signup_bonus/'||new.id::text,'signup_bonus_v1','system/signup_bonus',null);
 end if;return new;
end$$;
create trigger essay_signup_credit after insert on public.profiles for each row execute function essay_private.credit_profile_signup();
-- Finance-only manual operation; actor comes from signed server JWT, not payload.
create function public.essay_admin_grant(p_user uuid,p_quantity integer,p_origin text,p_key uuid,p_reason text,p_expires timestamptz default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid=essay_private.uid();begin
 if actor is null then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED';end if;
 if p_key is null or p_origin is null or not (
 (p_origin='admin_grant' and p_reason in ('test_account','manual_support')) or
 (p_origin='promotion' and p_reason='operational_promotion') or
 (p_origin='compensation' and p_reason='customer_compensation') or
 (p_origin='b2b_program' and p_reason='program_allocation')) then raise sqlstate 'PT422' using message='INVALID_GRANT_REASON';end if;
 return essay_private.credit_post_grant(p_user,p_quantity,p_origin,'manual/'||p_key::text,p_reason,'operator/'||actor::text,p_expires);
end$$;
create function essay_private.credit_request_v2(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid language plpgsql security definer set search_path='' as $$
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
  select g.id into grant_id from public.credit_grants g where g.account_id=account and (g.expires_at is null or g.expires_at>essay_private.clock())
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
end$$;

-- Server pins policy to session, independently of evaluation regime; client cannot select pricing.
create or replace function public.essay_request_evaluation(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid
language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id where a.id=p_attempt and s.billing_policy_version='v2') then
 return essay_private.credit_request_v2(p_attempt,p_key,p_regime);end if;
 if p_regime in ('essay-v1.3','essay-v1.3-next-model') then return essay_private.scaffold_request_v13(p_attempt,p_key,p_regime);end if;
 return essay_private.scaffold_legacy_essay_request_evaluation(p_attempt,p_key,p_regime);
end$$;
create or replace function essay_private.scaffold_legacy_essay_finalize_success(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r public.essay_ai_processing_runs; b public.essay_billing_decisions; t public.credit_transactions; x jsonb; v jsonb; dim uuid; issue uuid; progress uuid; h text; n integer;
begin
 e=essay_private.lock_job(p_evaluation);
 h=essay_private.hash(p_output::text);
 select * into r from public.essay_ai_processing_runs where id=p_run;
 if r.selected_result and r.lease_token=p_token and p_token is not null and r.output_sha256=h
 and ((p_rewrite is null and r.evaluation_id=e.id and e.status='completed') or (p_rewrite is not null and r.rewrite_id=p_rewrite and exists(select 1 from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=e.id and status='completed'))) then return coalesce(p_rewrite,e.id);end if;
 r=essay_private.fence(e.id,p_run,p_token,p_rewrite);
 if p_output is null or jsonb_typeof(p_output)<>'object' or p_output->>'contract_version' is distinct from e.contract_version then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
 if p_rewrite is not null then
  if nullif(btrim(p_output->>'body'),'') is null or char_length(p_output->>'body')>20000 then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
  update public.essay_generated_rewrites set status='completed',body=p_output->>'body',input_sha256=e.output_sha256,output_sha256=h,completed_at=essay_private.clock() where id=p_rewrite and status='processing';
  if not found then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
 else
  select * into b from public.essay_billing_decisions where evaluation_id=e.id;
  if e.status<>'processing' or b.status not in ('authorized','reserved') then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
  if nullif(btrim(p_output->>'summary'),'') is null or jsonb_typeof(p_output->'dimensions') is distinct from 'array'
   or jsonb_typeof(p_output->'improvements') is distinct from 'array' or jsonb_typeof(p_output->'strengths') is distinct from 'array' or jsonb_typeof(p_output->'checklist') is distinct from 'array'
  then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
  if jsonb_array_length(p_output->'dimensions')<>jsonb_array_length(e.input_snapshot->'criteria')
   or (select count(distinct elem->>'criterion_id') from jsonb_array_elements(p_output->'dimensions') elem)<>jsonb_array_length(p_output->'dimensions')
   or (select count(distinct elem->>'issue_key') from jsonb_array_elements(p_output->'improvements') elem)<>jsonb_array_length(p_output->'improvements') then raise sqlstate 'PT422' using message='DUPLICATE_OR_MISSING_OUTPUT';end if;
  for x in select * from jsonb_array_elements(p_output->'dimensions') loop
   if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'criteria') c where c->>'id'=x->>'criterion_id')
    or (x->>'level')::integer not between 1 and 5 or x->>'level' is null or nullif(btrim(x->>'explanation'),'') is null
    or jsonb_typeof(x->'evidence_ids') is distinct from 'array' or jsonb_array_length(x->'evidence_ids')=0 then raise sqlstate 'PT422' using message='INVALID_CRITERION';end if;
   insert into public.essay_evaluation_dimensions(evaluation_id,question_id,criterion_id,level_1_to_5,explanation,display_order)
   select e.id,e.question_id,c.id,(x->>'level')::integer,x->>'explanation',c.display_order from public.essay_evaluation_criteria c where c.id=(x->>'criterion_id')::uuid and c.question_id=e.question_id returning id into dim;
   if dim is null then raise sqlstate 'PT422' using message='INVALID_CRITERION';end if;
   for v in select * from jsonb_array_elements(x->'evidence_ids') loop
    if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'evidence') s where s->>'id'=v#>>'{}') then raise sqlstate 'PT422' using message='INVALID_EVIDENCE';end if;
    insert into public.essay_evaluation_evidence(evaluation_id,question_id,evidence_id,dimension_id) values(e.id,e.question_id,(v#>>'{}')::uuid,dim);
   end loop;
  end loop;
  for x in select * from jsonb_array_elements(p_output->'improvements') loop
   if nullif(btrim(x->>'issue_key'),'') is null or nullif(btrim(x->>'title'),'') is null or nullif(btrim(x->>'explanation'),'') is null or nullif(btrim(x->>'action'),'') is null or jsonb_typeof(x->'evidence_ids') is distinct from 'array' or jsonb_array_length(x->'evidence_ids')=0 then raise sqlstate 'PT422' using message='INVALID_IMPROVEMENT';end if;
   insert into public.essay_improvement_items(session_id,issue_key,category) values(e.session_id,x->>'issue_key',x->>'category') on conflict(session_id,issue_key) do nothing;
   select id into issue from public.essay_improvement_items where session_id=e.session_id and issue_key=x->>'issue_key' and category=x->>'category';
   if issue is null then raise sqlstate 'PT422' using message='ISSUE_IDENTITY_MISMATCH';end if;
   if x->>'previous_progress_id' is not null and not exists(select 1 from public.essay_improvement_progress p join public.essay_evaluations pe on pe.id=p.evaluation_id join public.essay_attempts pa on pa.id=pe.attempt_id join public.essay_attempts ca on ca.id=e.attempt_id where p.id=(x->>'previous_progress_id')::uuid and p.issue_id=issue and pe.invalidated_at is null and pe.regime_key=e.regime_key and pa.submitted_at<ca.submitted_at) then raise sqlstate 'PT422' using message='INVALID_PROGRESS_LINK';end if;
   insert into public.essay_improvement_progress(issue_id,previous_progress_id,session_id,evaluation_id,status,title,explanation,next_action,priority)
   values(issue,(x->>'previous_progress_id')::uuid,e.session_id,e.id,x->>'status',x->>'title',x->>'explanation',x->>'action',(x->>'priority')::integer) returning id into progress;
   for v in select * from jsonb_array_elements(x->'evidence_ids') loop
    if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'evidence') s where s->>'id'=v#>>'{}') then raise sqlstate 'PT422' using message='INVALID_EVIDENCE';end if;
    insert into public.essay_evaluation_evidence(evaluation_id,question_id,evidence_id,improvement_progress_id) values(e.id,e.question_id,(v#>>'{}')::uuid,progress);
   end loop;
  end loop;
  update public.essay_evaluations set status='completed',overall_summary=p_output->>'summary',strengths=array(select jsonb_array_elements_text(p_output->'strengths')),rewrite_checklist=array(select jsonb_array_elements_text(p_output->'checklist')),model_provider=r.provider,model_name=r.model_name,model_version=r.model_version,prompt_version=r.prompt_version,input_sha256=e.evidence_manifest_sha256,output_sha256=h,completed_at=essay_private.clock() where id=e.id;
  n=0;
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(b.account_id,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,b.policy_key||'_'||b.policy_version); n=n+t.reserved_delta;
  end loop;
  if n<>b.credits_required then raise sqlstate 'PT409' using message='RESERVATION_MISMATCH';end if;
  update public.essay_billing_decisions set status='settled',settled_at=essay_private.clock() where id=b.id;
 end if;
 update public.essay_ai_processing_runs set status='completed',selected_result=true,completed_at=essay_private.clock(),input_sha256=e.evidence_manifest_sha256,output_sha256=h where id=r.id;
 return coalesce(p_rewrite,e.id);
end$$;
create or replace function essay_private.scaffold_finalize_v13(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r public.essay_ai_processing_runs; b public.essay_billing_decisions; t public.credit_transactions; x jsonb; v jsonb; dim uuid; issue uuid; progress uuid; h text; n integer;
begin
 e=essay_private.lock_job(p_evaluation);
 h=essay_private.hash(p_output::text);
 select * into r from public.essay_ai_processing_runs where id=p_run;
 if r.selected_result and r.lease_token=p_token and p_token is not null and r.output_sha256=h
 and ((p_rewrite is null and r.evaluation_id=e.id and e.status='completed') or (p_rewrite is not null and r.rewrite_id=p_rewrite and exists(select 1 from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=e.id and status='completed'))) then return coalesce(p_rewrite,e.id);end if;
 r=essay_private.fence(e.id,p_run,p_token,p_rewrite);
 if p_output is null or jsonb_typeof(p_output)<>'object' or p_output->>'contract_version' is distinct from e.contract_version then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
 if p_rewrite is not null then
  if nullif(btrim(p_output->>'body'),'') is null or char_length(p_output->>'body')>20000 then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
  update public.essay_generated_rewrites set status='completed',body=p_output->>'body',input_sha256=e.output_sha256,output_sha256=h,completed_at=essay_private.clock() where id=p_rewrite and status='processing';
  if not found then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
 else
  p_output=essay_private.scaffold_validate(e.id,p_output);
  select * into b from public.essay_billing_decisions where evaluation_id=e.id;
  if e.status<>'processing' or b.status not in ('authorized','reserved') then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
  if nullif(btrim(p_output->>'summary'),'') is null or jsonb_typeof(p_output->'dimensions') is distinct from 'array'
   or jsonb_typeof(p_output->'improvements') is distinct from 'array' or jsonb_typeof(p_output->'strengths') is distinct from 'array' or jsonb_typeof(p_output->'checklist') is distinct from 'array'
  then raise sqlstate 'PT422' using message='INVALID_OUTPUT';end if;
  if jsonb_array_length(p_output->'dimensions')<>jsonb_array_length(e.input_snapshot->'criteria')
   or (select count(distinct elem->>'criterion_id') from jsonb_array_elements(p_output->'dimensions') elem)<>jsonb_array_length(p_output->'dimensions')
   or (select count(distinct elem->>'issue_key') from jsonb_array_elements(p_output->'improvements') elem)<>jsonb_array_length(p_output->'improvements') then raise sqlstate 'PT422' using message='DUPLICATE_OR_MISSING_OUTPUT';end if;
  for x in select * from jsonb_array_elements(p_output->'dimensions') loop
   if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'criteria') c where c->>'id'=x->>'criterion_id')
    or (x->>'level')::integer not between 1 and 5 or x->>'level' is null or nullif(btrim(x->>'explanation'),'') is null
    or jsonb_typeof(x->'evidence_ids') is distinct from 'array' or jsonb_array_length(x->'evidence_ids')=0 then raise sqlstate 'PT422' using message='INVALID_CRITERION';end if;
   insert into public.essay_evaluation_dimensions(evaluation_id,question_id,criterion_id,level_1_to_5,explanation,display_order)
   select e.id,e.question_id,c.id,(x->>'level')::integer,x->>'explanation',c.display_order from public.essay_evaluation_criteria c where c.id=(x->>'criterion_id')::uuid and c.question_id=e.question_id returning id into dim;
   if dim is null then raise sqlstate 'PT422' using message='INVALID_CRITERION';end if;
   for v in select * from jsonb_array_elements(x->'evidence_ids') loop
    if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'evidence') s where s->>'id'=v#>>'{}') then raise sqlstate 'PT422' using message='INVALID_EVIDENCE';end if;
    insert into public.essay_evaluation_evidence(evaluation_id,question_id,evidence_id,dimension_id) values(e.id,e.question_id,(v#>>'{}')::uuid,dim);
   end loop;
  end loop;
  for x in select * from jsonb_array_elements(p_output->'improvements') loop
   if nullif(btrim(x->>'issue_key'),'') is null or nullif(btrim(x->>'title'),'') is null or nullif(btrim(x->>'explanation'),'') is null or nullif(btrim(x->>'action'),'') is null or jsonb_typeof(x->'evidence_ids') is distinct from 'array' then raise sqlstate 'PT422' using message='INVALID_IMPROVEMENT';end if;
   insert into public.essay_improvement_items(session_id,issue_key,category) values(e.session_id,x->>'issue_key',x->>'category') on conflict(session_id,issue_key) do nothing;
   select id into issue from public.essay_improvement_items where session_id=e.session_id and issue_key=x->>'issue_key' and category=x->>'category';
   if issue is null then raise sqlstate 'PT422' using message='ISSUE_IDENTITY_MISMATCH';end if;
   if x->>'previous_progress_id' is not null and not exists(select 1 from public.essay_improvement_progress p join public.essay_evaluations pe on pe.id=p.evaluation_id join public.essay_attempts pa on pa.id=pe.attempt_id join public.essay_attempts ca on ca.id=e.attempt_id where p.id=(x->>'previous_progress_id')::uuid and p.issue_id=issue and pe.invalidated_at is null and pe.regime_key=e.regime_key and pa.submitted_at<ca.submitted_at) then raise sqlstate 'PT422' using message='INVALID_PROGRESS_LINK';end if;
   insert into public.essay_improvement_progress(issue_id,previous_progress_id,session_id,evaluation_id,status,title,explanation,next_action,priority,scaffolding_observation)
   values(issue,(x->>'previous_progress_id')::uuid,e.session_id,e.id,x->>'status',x->>'title',x->>'explanation',x->>'action',(x->>'priority')::integer,x->'scaffolding_observation') returning id into progress;
   for v in select * from jsonb_array_elements(x->'evidence_ids') loop
    if not exists(select 1 from jsonb_array_elements(e.input_snapshot->'evidence') s where s->>'id'=v#>>'{}') then raise sqlstate 'PT422' using message='INVALID_EVIDENCE';end if;
    insert into public.essay_evaluation_evidence(evaluation_id,question_id,evidence_id,improvement_progress_id) values(e.id,e.question_id,(v#>>'{}')::uuid,progress);
   end loop;
  end loop;
  update public.essay_evaluations set status='completed',uncertainty_note=p_output->>'uncertainty_note',overall_summary=p_output->>'summary',strengths=array(select jsonb_array_elements_text(p_output->'strengths')),rewrite_checklist=array(select jsonb_array_elements_text(p_output->'checklist')),model_provider=r.provider,model_name=r.model_name,model_version=r.model_version,prompt_version=r.prompt_version,input_sha256=e.evidence_manifest_sha256,output_sha256=h,completed_at=essay_private.clock() where id=e.id;
  n=0;
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(b.account_id,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,b.policy_key||'_'||b.policy_version); n=n+t.reserved_delta;
  end loop;
  if n<>b.credits_required then raise sqlstate 'PT409' using message='RESERVATION_MISMATCH';end if;
  update public.essay_billing_decisions set status='settled',settled_at=essay_private.clock() where id=b.id;
 end if;
 update public.essay_ai_processing_runs set status='completed',selected_result=true,completed_at=essay_private.clock(),input_sha256=e.evidence_manifest_sha256,output_sha256=h where id=r.id;
 return coalesce(p_rewrite,e.id);
end$$;
do $$declare f record;begin
 for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where
 (n.nspname='essay_private' and p.proname in ('credit_post_grant','credit_profile_signup','credit_request_v2')) or
 (n.nspname='public' and p.proname in ('essay_claim_signup_credit','essay_admin_grant')) loop
 execute format('alter function %s owner to essay_executor',f.signature);
 execute format('revoke all on function %s from public,anon,authenticated,service_role,essay_worker,essay_finance',f.signature);
 end loop;
end$$;
grant execute on function public.essay_claim_signup_credit() to authenticated;
grant execute on function public.essay_admin_grant(uuid,integer,text,uuid,text,timestamptz) to essay_finance;
revoke create on schema public,essay_private from essay_executor;
revoke essay_executor from current_user;
commit;
