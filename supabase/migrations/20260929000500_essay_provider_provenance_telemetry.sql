-- L2-A2 authorized forward correction. NOT APPLIED. No provider/model selected or AI enabled.
-- KEEP19; reuse frozen input_snapshot for content-addressed provider policy. No history rewrite.
begin;
grant essay_executor to current_user;
grant create on schema public,essay_private to essay_executor;
alter table public.essay_ai_processing_runs add column total_tokens bigint check(total_tokens>=0);

-- Empty, deployment-owned registry. Future approved migration adds immutable entries;
-- no caller role can execute/change it, no real or synthetic model is seeded here.
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
 return coalesce(p_regime='essay-v1.3/policy/'||essay_private.hash(b::text),false);
end$$;

create function essay_private.provider_request_v13(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid language plpgsql security definer set search_path='' as $$
declare a public.essay_attempts; e public.essay_evaluations; account uuid; u uuid; snapshot jsonb; criteria jsonb; evidence jsonb; h text; parent public.essay_billing_decisions; b uuid; grant_id uuid; reason text; amount integer=1; binding jsonb;
begin
 select * into a from public.essay_attempts where id=p_attempt;
 u=essay_private.owner(a.session_id);
 binding=essay_private.provider_policy(p_regime);
 if p_key is null or not essay_private.provider_binding_valid(p_regime,binding) then raise sqlstate 'PT422' using message='MODEL_POLICY_NOT_APPROVED'; end if;
 if not exists(select 1 from public.essay_practice_sessions where id=a.session_id and billing_policy_version='v2') then raise sqlstate 'PT422' using message='PROVIDER_POLICY_REQUIRES_V2_SESSION';end if;
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
 snapshot=snapshot||jsonb_build_object('provider_binding',binding);
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

create function essay_private.provider_claim_v13(p_evaluation uuid,p_rewrite uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r public.essay_ai_processing_runs; n integer; job_status text; created timestamptz; answer text; binding jsonb;
begin
 e=essay_private.lock_job(p_evaluation);
 binding=e.input_snapshot->'provider_binding';
 if p_rewrite is not null or e.contract_version<>'1.3' or not essay_private.provider_binding_valid(e.regime_key,binding)
 or e.evidence_manifest_sha256 is distinct from essay_private.hash(e.input_snapshot::text) then raise sqlstate 'PT422' using message='INVALID_PROVIDER_BINDING';end if;
 if p_rewrite is null then job_status=e.status;created=e.requested_at;
 else select status,created_at into job_status,created from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=e.id for update; end if;
 if job_status is null or job_status not in ('requested','processing') or created+interval '15 minutes'<=essay_private.clock() then raise sqlstate 'PT409' using message='INVALID_STATE'; end if;
 if p_rewrite is null and not exists(select 1 from public.essay_billing_decisions where evaluation_id=e.id and status in ('authorized','reserved')) then raise sqlstate 'PT409' using message='BILLING_NOT_AUTHORIZED'; end if;
 select * into r from public.essay_ai_processing_runs where (p_rewrite is null and evaluation_id=e.id) or (p_rewrite is not null and rewrite_id=p_rewrite) order by run_no desc limit 1;
 if r.id is not null and r.lease_expires_at>essay_private.clock() then raise sqlstate 'PT409' using message='EVALUATION_IN_PROGRESS'; end if;
 n=coalesce(r.run_no,0)+1;
 if r.id is not null and r.status='processing' then update public.essay_ai_processing_runs set status='unknown',timed_out_at=essay_private.clock() where id=r.id; end if;
 insert into public.essay_ai_processing_runs(evaluation_id,rewrite_id,run_no,provider,model_name,model_version,prompt_version,status,lease_token,lease_expires_at)
 values(case when p_rewrite is null then e.id end,p_rewrite,n,binding->>'provider',binding->>'model',binding->>'model_version',binding->>'prompt_version','processing',gen_random_uuid(),essay_private.clock()+interval '120 seconds') returning * into r;
 if p_rewrite is null then update public.essay_evaluations set status='processing' where id=e.id;
 else update public.essay_generated_rewrites set status='processing' where id=p_rewrite;end if;
 select body into answer from public.essay_attempts where id=e.attempt_id;
 return jsonb_build_object('run_id',r.id,'lease_token',r.lease_token,'lease_expires_at',r.lease_expires_at,'generation',n,'provider_binding',binding,'answer',answer,'input',e.input_snapshot,
 'improvements',case when p_rewrite is not null then (select jsonb_agg(jsonb_build_object('title',title,'action',next_action)) from public.essay_improvement_progress where evaluation_id=e.id) end);
end$$;

create or replace function public.essay_request_evaluation(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid
language plpgsql security definer set search_path='' as $$begin
 if p_regime like 'essay-v1.3/policy/%' then return essay_private.provider_request_v13(p_attempt,p_key,p_regime);end if;
 if exists(select 1 from public.essay_attempts a join public.essay_practice_sessions s on s.id=a.session_id where a.id=p_attempt and s.billing_policy_version='v2') then
 return essay_private.credit_request_v2(p_attempt,p_key,p_regime);end if;
 if p_regime in ('essay-v1.3','essay-v1.3-next-model') then return essay_private.scaffold_request_v13(p_attempt,p_key,p_regime);end if;
 return essay_private.scaffold_legacy_essay_request_evaluation(p_attempt,p_key,p_regime);
end$$;

create or replace function public.essay_claim(p_evaluation uuid,p_rewrite uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from public.essay_evaluations where id=p_evaluation and (regime_key like 'essay-v1.3/policy/%' or input_snapshot ? 'provider_binding')) then return essay_private.provider_claim_v13(p_evaluation,p_rewrite);end if;
 if exists(select 1 from public.essay_evaluations where id=p_evaluation and contract_version='1.3') then return essay_private.scaffold_claim_v13(p_evaluation,p_rewrite);end if;
 return essay_private.scaffold_legacy_essay_claim(p_evaluation,p_rewrite);
end$$;

create or replace function public.essay_product_processing_guard() returns trigger language plpgsql set search_path = '' as $$
begin
 if old.status in ('completed','failed') then raise exception 'completed provider run is immutable'; end if;
 if old.timed_out_at is not null and new.timed_out_at is distinct from old.timed_out_at then raise exception 'timeout fact is immutable'; end if;
 if (to_jsonb(old)-array['status','selected_result','completed_at','timed_out_at','input_tokens','output_tokens','total_tokens','image_count','latency_ms','cost_amount','currency','cost_basis','input_sha256','output_sha256','error_code'])
    is distinct from
    (to_jsonb(new)-array['status','selected_result','completed_at','timed_out_at','input_tokens','output_tokens','total_tokens','image_count','latency_ms','cost_amount','currency','cost_basis','input_sha256','output_sha256','error_code']) then raise exception 'provider run identity is immutable'; end if;
 if old.latency_ms is not null and
 (old.input_tokens,old.output_tokens,old.total_tokens,old.image_count,old.latency_ms,old.cost_amount,old.currency,old.cost_basis)
 is distinct from
 (new.input_tokens,new.output_tokens,new.total_tokens,new.image_count,new.latency_ms,new.cost_amount,new.currency,new.cost_basis)
 then raise exception 'recorded provider telemetry is immutable';end if;
 return new;
end;
$$;


-- Worker only; caller supplies measured counters, never provider/model identity or arbitrary JSON.
-- Record available usage BEFORE timeout/failure. Unknown/expired/terminal runs remain fenced out.
-- Non-null latency is the write-once marker; unknown latency must not be invented to write a row.
create function public.essay_record_provider_telemetry(
 p_evaluation uuid,p_run uuid,p_token uuid,p_input_tokens bigint,p_output_tokens bigint,
 p_total_tokens bigint,p_latency_ms bigint,p_image_count integer default null,
 p_cost_amount numeric default null,p_currency text default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r public.essay_ai_processing_runs; b jsonb;
begin
 e=essay_private.lock_job(p_evaluation);
 r=essay_private.fence(p_evaluation,p_run,p_token,null);
 b=e.input_snapshot->'provider_binding';
 if not essay_private.provider_binding_valid(e.regime_key,b) or
 (r.provider,r.model_name,r.model_version,r.prompt_version) is distinct from
 (b->>'provider',b->>'model',b->>'model_version',b->>'prompt_version') then raise sqlstate 'PT422' using message='INVALID_PROVIDER_BINDING';end if;
 if p_latency_ms is null or p_latency_ms<0 or p_latency_ms>86400000
 or p_input_tokens<0 or p_output_tokens<0 or p_total_tokens<0 or p_image_count<0
 or (p_total_tokens is not null and p_input_tokens is not null and p_output_tokens is not null
     and p_total_tokens::numeric<>p_input_tokens::numeric+p_output_tokens::numeric)
 or (p_cost_amount is null and p_currency is not null)
 or (p_cost_amount is not null and (p_cost_amount::text in ('NaN','Infinity','-Infinity')
     or p_cost_amount<0 or p_cost_amount>1000000 or trunc(p_cost_amount,8)<>p_cost_amount
     or p_currency is null or p_currency !~ '^[A-Z]{3}$'))
 then raise sqlstate 'PT422' using message='INVALID_TELEMETRY';end if;
 if r.latency_ms is not null then
  if (r.input_tokens,r.output_tokens,r.total_tokens,r.latency_ms,r.image_count,r.cost_amount,r.currency)
  is distinct from (p_input_tokens,p_output_tokens,p_total_tokens,p_latency_ms,p_image_count,p_cost_amount,p_currency)
  then raise sqlstate 'PT409' using message='TELEMETRY_CONFLICT';end if;
  return r.id;
 end if;
 update public.essay_ai_processing_runs set input_tokens=p_input_tokens,output_tokens=p_output_tokens,
 total_tokens=p_total_tokens,latency_ms=p_latency_ms,image_count=p_image_count,cost_amount=p_cost_amount,
 currency=p_currency,cost_basis=case when p_cost_amount is not null then 'provider_reported' end where id=r.id;
 return r.id;
end$$;

-- Preserve existing public request/claim ACL/owners. New helpers get no caller grants.
do $$declare f record;begin
 for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where (n.nspname='essay_private' and p.proname in ('provider_policy','provider_binding_valid','provider_request_v13','provider_claim_v13'))
 or (n.nspname='public' and p.proname='essay_record_provider_telemetry') loop
  execute format('alter function %s owner to essay_executor',f.signature);
  execute format('revoke all on function %s from public,anon,authenticated,service_role,essay_worker,essay_finance',f.signature);
 end loop;
end$$;
grant execute on function public.essay_record_provider_telemetry(uuid,uuid,uuid,bigint,bigint,bigint,bigint,integer,numeric,text) to essay_worker;
revoke create on schema public,essay_private from essay_executor;
revoke essay_executor from current_user;
commit;
