-- PROMOTED by Owner approval / NOT APPLIED. Production apply requires separate authorization.
begin;
alter table public.essay_attempts add column submission_request_hash text check(submission_request_hash ~ '^[0-9a-f]{64}$');
alter table public.essay_evaluations add column input_snapshot jsonb check(jsonb_typeof(input_snapshot)='object');
alter table public.essay_ai_processing_runs add column lease_token uuid, add column lease_expires_at timestamptz,
 add check((lease_token is null)=(lease_expires_at is null)), add check(lease_expires_at is null or lease_expires_at>started_at);
create schema essay_private;
revoke all on schema essay_private from public,anon,authenticated,service_role;
-- NOLOGIN executor is never issued a credential/JWT or granted to a worker. Function ownership only.
do $$begin
 if not exists(select 1 from pg_roles where rolname='essay_executor') then create role essay_executor nologin bypassrls;end if;
 if not exists(select 1 from pg_roles where rolname='essay_worker') then create role essay_worker nologin nobypassrls;end if;
 if not exists(select 1 from pg_roles where rolname='essay_finance') then create role essay_finance nologin nobypassrls;end if;
 if exists(select 1 from pg_roles where rolname in ('essay_executor','essay_worker','essay_finance') and (rolcanlogin or rolsuper)) or exists(select 1 from pg_roles where rolname in ('essay_worker','essay_finance') and rolbypassrls) then raise exception 'unsafe existing Essay role';end if;
end$$;
grant essay_executor to current_user; -- bootstrap ownership transfer only; revoked below
grant usage on schema public,essay_private to essay_executor;
grant create on schema public,essay_private to essay_executor;
grant usage on schema public to essay_worker,essay_finance;
-- Supabase auth schema is owned by supabase_admin; do not assume grant option.
grant select on public.profiles,public.essay_questions,public.essay_exams,public.essay_exam_resources,public.essay_question_evidence,public.essay_evaluation_criteria to essay_executor;
grant select,insert,update,delete on public.essay_practice_sessions,public.essay_drafts,public.essay_attempts,public.essay_evaluations,public.essay_evaluation_dimensions,public.essay_improvement_items,public.essay_improvement_progress,public.essay_evaluation_evidence,public.essay_generated_rewrites,public.essay_learning_events,public.essay_ai_processing_runs to essay_executor;
grant select,insert,update on public.credit_accounts,public.essay_billing_decisions to essay_executor;
grant select,update on public.credit_grants to essay_executor; -- FOR UPDATE lock; immutable-term trigger still denies changes
grant select,insert on public.credit_transactions to essay_executor;

create function essay_private.uid() returns uuid language sql security definer set search_path='' as $$select auth.uid()$$;
create function essay_private.clock() returns timestamptz language sql volatile set search_path='' as $$select pg_catalog.clock_timestamp()$$;
create function essay_private.hash(p_text text) returns text language sql immutable set search_path='' as $$select pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(p_text,'UTF8')),'hex')$$;
create function essay_private.owner(p_session uuid) returns uuid language plpgsql set search_path='' as $$
declare u uuid;
begin
 u=essay_private.uid(); if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
 if not exists(select 1 from public.essay_practice_sessions where id=p_session and user_id=u) then raise sqlstate 'PT403' using message='FORBIDDEN'; end if;
 return u;
end$$;
create function essay_private.lock_job(p_evaluation uuid) returns public.essay_evaluations language plpgsql set search_path='' as $$
declare e public.essay_evaluations; b public.essay_billing_decisions;
begin
 select * into e from public.essay_evaluations where id=p_evaluation;
 select * into b from public.essay_billing_decisions where evaluation_id=p_evaluation;
 if e.id is null or b.id is null then raise sqlstate 'PT404' using message='NOT_FOUND'; end if;
 perform 1 from public.credit_accounts where id=b.account_id for update;
 perform 1 from public.essay_practice_sessions where id=e.session_id for update;
 perform 1 from public.credit_grants where account_id=b.account_id order by id for update;
 select * into e from public.essay_evaluations where id=p_evaluation for update;
 if e.id is null then raise sqlstate 'PT404' using message='NOT_FOUND'; end if;
 return e;
end$$;
create function essay_private.release(p_evaluation uuid) returns void language plpgsql set search_path='' as $$
declare b public.essay_billing_decisions; t public.credit_transactions;
begin
 select * into b from public.essay_billing_decisions where evaluation_id=p_evaluation;
 if b.status not in ('authorized','reserved') then raise sqlstate 'PT409' using message='INVALID_STATE'; end if;
 for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' loop
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(b.account_id,t.grant_id,b.id,'release',0,-t.reserved_delta,'release/'||b.id::text||'/'||t.grant_id::text,'technical_failure');
 end loop;
 update public.essay_billing_decisions set status='released',released_at=essay_private.clock() where id=b.id;
end$$;

-- Caller: authenticated; fixed auth.uid; one atomic session/draft creation; stable caller key=id.
create function public.essay_open_session(p_id uuid,p_question uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid(); existing public.essay_practice_sessions;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
 if p_id is null or not exists(select 1 from public.essay_questions where id=p_question and is_published) then raise sqlstate 'PT422' using message='INVALID_QUESTION'; end if;
 insert into public.essay_practice_sessions(id,user_id,question_id) values(p_id,u,p_question) on conflict(id) do nothing;
 select * into existing from public.essay_practice_sessions where id=p_id for update;
 if existing.user_id<>u or existing.question_id<>p_question then raise sqlstate 'PT409' using message='CONFLICT'; end if;
 insert into public.essay_drafts(session_id,device_class) values(p_id,'web_desktop') on conflict do nothing;
 return p_id;
end$$;
-- Draft save is CAS; stale saves never overwrite another device.
create function public.essay_save_draft(p_session uuid,p_revision bigint,p_body text,p_device text default 'web_desktop',p_mode text default 'practice',p_active_seconds integer default null) returns bigint language plpgsql security definer set search_path='' as $$
declare rev bigint;
begin
 perform essay_private.owner(p_session);
 if p_body is null or char_length(p_body)>20000 or p_active_seconds<0 then raise sqlstate 'PT422' using message='INVALID_INPUT'; end if;
 update public.essay_drafts set body=p_body,revision=revision+1,device_class=p_device,mode=p_mode,active_writing_seconds=p_active_seconds where session_id=p_session and revision=p_revision returning revision into rev;
 if rev is null then raise sqlstate 'PT409' using message='STALE_DRAFT'; end if;
 return rev;
end$$;
-- Caller supplies expected body hash as conflict detector; hash/count are computed by server.
create function public.essay_submit_attempt(p_session uuid,p_revision bigint,p_key uuid,p_body_hash text) returns uuid language plpgsql security definer set search_path='' as $$
declare d public.essay_drafts; a public.essay_attempts; q public.essay_questions; h text; n integer;
begin
 perform essay_private.owner(p_session);
 if p_key is null or p_body_hash is null or p_revision is null then raise sqlstate 'PT422' using message='INVALID_INPUT'; end if;
 perform 1 from public.essay_practice_sessions where id=p_session for update;
 h=essay_private.hash(jsonb_build_array(p_session,p_revision,p_body_hash)::text);
 select * into a from public.essay_attempts where submission_key=p_key;
 if a.id is not null then
  if a.session_id<>p_session or a.submission_request_hash is distinct from h then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return a.id;
 end if;
 select * into d from public.essay_drafts where session_id=p_session for update;
 if d.revision is distinct from p_revision then raise sqlstate 'PT409' using message='STALE_DRAFT'; end if;
 if nullif(btrim(d.body),'') is null or essay_private.hash(d.body)<>p_body_hash then raise sqlstate 'PT409' using message='PAYLOAD_MISMATCH'; end if;
 select x.* into q from public.essay_questions x join public.essay_practice_sessions s on s.question_id=x.id where s.id=p_session;
 select coalesce(max(attempt_no),0)+1 into n from public.essay_attempts where session_id=p_session;
 insert into public.essay_attempts(session_id,attempt_no,body,body_sha256,input_method,device_class,mode,started_at,active_writing_seconds,character_count,count_rule_version,question_metadata_version,conditions_snapshot,submission_key,submission_request_hash)
 values(p_session,n,d.body,p_body_hash,'typed',d.device_class,d.mode,d.started_at,least(d.active_writing_seconds,greatest(0,extract(epoch from now()-d.started_at)::int)),char_length(d.body),'unicode-codepoints-including-whitespace-v1',q.metadata_version,jsonb_strip_nulls(jsonb_build_object('length_min',q.length_min,'length_max',q.length_max,'length_count_rule',q.length_count_rule,'time_limit_seconds',q.time_limit_seconds)),p_key,h) returning * into a;
 return a.id;
end$$;

-- Server-owned policy registry in review SQL, NOT a caller-supplied contract/model/policy.
-- Two model-policy regimes exercise coexistence; no provider/model deployment is selected here.
create function public.essay_request_evaluation(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid language plpgsql security definer set search_path='' as $$
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
  select g.id into grant_id from public.credit_grants g where g.account_id=account and (g.expires_at is null or g.expires_at>essay_private.clock())
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
end$$;

create function public.essay_request_rewrite(p_evaluation uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r uuid;
begin
 select * into e from public.essay_evaluations where id=p_evaluation;
 perform essay_private.owner(e.session_id); e=essay_private.lock_job(p_evaluation);
 if e.status<>'completed' or e.invalidated_at is not null or not exists(select 1 from public.essay_billing_decisions where evaluation_id=e.id and status='settled') then raise sqlstate 'PT409' using message='INVALID_STATE'; end if;
 insert into public.essay_generated_rewrites(evaluation_id,generation_version,contract_version) values(e.id,'minimal-edit-v1','1.2') on conflict(evaluation_id) do nothing;
 select id into r from public.essay_generated_rewrites where evaluation_id=e.id;
 return r;
end$$;
-- Worker claim: bounded 120-second immutable lease per provider run; run_no is fencing generation.
create function public.essay_claim(p_evaluation uuid,p_rewrite uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; r public.essay_ai_processing_runs; n integer; job_status text; created timestamptz; answer text;
begin
 e=essay_private.lock_job(p_evaluation);
 if p_rewrite is null then job_status=e.status;created=e.requested_at;
 else select status,created_at into job_status,created from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=e.id for update; end if;
 if job_status is null or job_status not in ('requested','processing') or created+interval '15 minutes'<=essay_private.clock() then raise sqlstate 'PT409' using message='INVALID_STATE'; end if;
 if p_rewrite is null and not exists(select 1 from public.essay_billing_decisions where evaluation_id=e.id and status in ('authorized','reserved')) then raise sqlstate 'PT409' using message='BILLING_NOT_AUTHORIZED'; end if;
 select * into r from public.essay_ai_processing_runs where (p_rewrite is null and evaluation_id=e.id) or (p_rewrite is not null and rewrite_id=p_rewrite) order by run_no desc limit 1;
 if r.id is not null and r.lease_expires_at>essay_private.clock() then raise sqlstate 'PT409' using message='EVALUATION_IN_PROGRESS'; end if;
 n=coalesce(r.run_no,0)+1;
 if r.id is not null and r.status='processing' then update public.essay_ai_processing_runs set status='unknown',timed_out_at=essay_private.clock() where id=r.id; end if;
 insert into public.essay_ai_processing_runs(evaluation_id,rewrite_id,run_no,provider,model_name,prompt_version,status,lease_token,lease_expires_at)
 values(case when p_rewrite is null then e.id end,p_rewrite,n,'unconfigured',e.regime_key,'1.2','processing',gen_random_uuid(),essay_private.clock()+interval '120 seconds') returning * into r;
 if p_rewrite is null then update public.essay_evaluations set status='processing' where id=e.id;
 else update public.essay_generated_rewrites set status='processing' where id=p_rewrite;end if;
 select body into answer from public.essay_attempts where id=e.attempt_id;
 return jsonb_build_object('run_id',r.id,'lease_token',r.lease_token,'lease_expires_at',r.lease_expires_at,'generation',n,'answer',answer,'input',e.input_snapshot,
 'improvements',case when p_rewrite is not null then (select jsonb_agg(jsonb_build_object('title',title,'action',next_action)) from public.essay_improvement_progress where evaluation_id=e.id) end);
end$$;
create function essay_private.fence(p_evaluation uuid,p_run uuid,p_token uuid,p_rewrite uuid) returns public.essay_ai_processing_runs language plpgsql set search_path='' as $$
declare r public.essay_ai_processing_runs;
begin
 select * into r from public.essay_ai_processing_runs where id=p_run;
 if r.id is null or r.lease_token is distinct from p_token or p_token is null
 or (p_rewrite is null and (r.evaluation_id is distinct from p_evaluation or r.rewrite_id is not null))
 or (p_rewrite is not null and (r.rewrite_id is distinct from p_rewrite or not exists(select 1 from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=p_evaluation)))
 then raise sqlstate 'PT409' using message='STALE_WORKER'; end if;
 if r.status<>'processing' or r.lease_expires_at<=essay_private.clock() or exists(select 1 from public.essay_ai_processing_runs x where ((p_rewrite is null and x.evaluation_id=p_evaluation) or (p_rewrite is not null and x.rewrite_id=p_rewrite)) and x.run_no>r.run_no) then raise sqlstate 'PT409' using message='STALE_WORKER'; end if;
 return r;
end$$;
-- Unknown timeout keeps reservation; no publishing by this run after timeout marker.
create function public.essay_timeout(p_evaluation uuid,p_run uuid,p_token uuid,p_rewrite uuid default null) returns void language plpgsql security definer set search_path='' as $$
begin
 perform essay_private.lock_job(p_evaluation);perform essay_private.fence(p_evaluation,p_run,p_token,p_rewrite);
 update public.essay_ai_processing_runs set status='unknown',timed_out_at=essay_private.clock() where id=p_run;
end$$;
-- Completed output is immutable. Same selected run + same canonical payload is idempotent.
create function public.essay_finalize_success(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
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
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(b.account_id,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,'essay_cycle_v1'); n=n+t.reserved_delta;
  end loop;
  if n<>b.credits_required then raise sqlstate 'PT409' using message='RESERVATION_MISMATCH';end if;
  update public.essay_billing_decisions set status='settled',settled_at=essay_private.clock() where id=b.id;
 end if;
 update public.essay_ai_processing_runs set status='completed',selected_result=true,completed_at=essay_private.clock(),input_sha256=e.evidence_manifest_sha256,output_sha256=h where id=r.id;
 return coalesce(p_rewrite,e.id);
end$$;
create function public.essay_finalize_failure(p_evaluation uuid,p_run uuid,p_token uuid,p_rewrite uuid default null) returns void language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations;r public.essay_ai_processing_runs;
begin
 e=essay_private.lock_job(p_evaluation); r=essay_private.fence(e.id,p_run,p_token,p_rewrite);
 update public.essay_ai_processing_runs set status='failed',completed_at=essay_private.clock(),error_code='PROVIDER_FAILURE' where id=r.id;
 if p_rewrite is null then
  if e.status<>'processing' then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
  update public.essay_evaluations set status='failed',error_code='PROVIDER_FAILURE' where id=e.id;
  perform essay_private.release(e.id);
 else update public.essay_generated_rewrites set status='failed',error_code='PROVIDER_FAILURE' where id=p_rewrite and status='processing';
  if not found then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
 end if;
end$$;
-- Reconciler revokes all stale runs before releasing. A late response must use a NEW request.
create function public.essay_reconcile(p_evaluation uuid,p_rewrite uuid default null) returns void language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations;
begin
 e=essay_private.lock_job(p_evaluation);
 if p_rewrite is not null then
  if not exists(select 1 from public.essay_generated_rewrites where id=p_rewrite and evaluation_id=e.id and status in ('requested','processing'))
   or exists(select 1 from public.essay_ai_processing_runs where rewrite_id=p_rewrite and lease_expires_at>essay_private.clock())
   or (not exists(select 1 from public.essay_ai_processing_runs where rewrite_id=p_rewrite) and exists(select 1 from public.essay_generated_rewrites where id=p_rewrite and created_at+interval '15 minutes'>essay_private.clock())) then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
  update public.essay_ai_processing_runs set status='unknown',timed_out_at=coalesce(timed_out_at,essay_private.clock()) where rewrite_id=p_rewrite and status='processing';
  update public.essay_generated_rewrites set status='cancelled',error_code='LEASE_EXPIRED' where id=p_rewrite;
  return;
 end if;
 if e.status not in ('requested','processing') or exists(select 1 from public.essay_ai_processing_runs where evaluation_id=e.id and lease_expires_at>essay_private.clock()) or (not exists(select 1 from public.essay_ai_processing_runs where evaluation_id=e.id) and e.requested_at+interval '15 minutes'>essay_private.clock()) then raise sqlstate 'PT409' using message='INVALID_STATE';end if;
 update public.essay_ai_processing_runs set status='unknown',timed_out_at=coalesce(timed_out_at,essay_private.clock()) where evaluation_id=e.id and status='processing';
 update public.essay_evaluations set status='cancelled',error_code='LEASE_EXPIRED' where id=e.id;
 perform essay_private.release(e.id);
end$$;
-- Finance role only. Account serialization + append-only bounded reversal; policy-neutral amount.
create function public.essay_refund(p_consume uuid,p_key text,p_amount integer) returns uuid language plpgsql security definer set search_path='' as $$
declare t public.credit_transactions; old public.credit_transactions; used integer; result uuid;
begin
 select * into t from public.credit_transactions where id=p_consume and transaction_type='consume';
 if t.id is null or p_amount is null or p_amount<=0 or nullif(btrim(p_key),'') is null then raise sqlstate 'PT422' using message='INVALID_REFUND';end if;
 perform 1 from public.credit_accounts where id=t.account_id for update;
 select * into old from public.credit_transactions where idempotency_key=p_key;
 if old.id is not null then
  if old.reversal_of is distinct from t.id or old.balance_delta<>p_amount or old.transaction_type<>'refund' then raise sqlstate 'PT409' using message='CONFLICT';end if; return old.id;
 end if;
 select coalesce(sum(balance_delta),0) into used from public.credit_transactions where reversal_of=t.id and transaction_type='refund';
 if used+p_amount> -t.balance_delta then raise sqlstate 'PT409' using message='EXCESS_REFUND';end if;
 insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,reversal_of) values(t.account_id,t.grant_id,t.decision_id,'refund',p_amount,0,p_key,'approved_refund',t.id) returning id into result;
 return result;
end$$;
-- Owner-only erasure, serialized with claim/finalize. No financial cascade; outstanding reservations released.
create function public.essay_erase(p_session uuid) returns void language plpgsql security definer set search_path='' as $$
declare u uuid; account uuid;e public.essay_evaluations;
begin
 u=essay_private.owner(p_session);
 select id into account from public.credit_accounts where user_id=u for update;
 perform 1 from public.essay_practice_sessions where id=p_session for update;
 perform 1 from public.credit_grants where account_id=account order by id for update;
 for e in select * from public.essay_evaluations where session_id=p_session order by id for update loop
  if exists(select 1 from public.essay_billing_decisions where evaluation_id=e.id and status in ('authorized','reserved')) then perform essay_private.release(e.id);end if;
 end loop;
 delete from public.essay_practice_sessions where id=p_session and user_id=u;
end$$;

-- Explicit ownership/EXECUTE lists; never grant worker membership in executor/service_role.
do $$declare f record; begin
 for f in select p.oid::regprocedure signature,n.nspname,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='essay_private' or (n.nspname='public' and p.proname in ('essay_open_session','essay_save_draft','essay_submit_attempt','essay_request_evaluation','essay_request_rewrite','essay_claim','essay_timeout','essay_finalize_success','essay_finalize_failure','essay_reconcile','essay_refund','essay_erase')) loop
  if not (f.nspname='essay_private' and f.proname='uid') then execute format('alter function %s owner to essay_executor',f.signature);end if;
  execute format('revoke all on function %s from public,anon,authenticated,service_role,essay_worker,essay_finance',f.signature);
  if f.nspname='essay_private' and f.proname='uid' then execute format('grant execute on function %s to essay_executor',f.signature);end if;
  if f.nspname='public' then
   if f.proname in ('essay_open_session','essay_save_draft','essay_submit_attempt','essay_request_evaluation','essay_request_rewrite','essay_erase') then execute format('grant execute on function %s to authenticated',f.signature);
   elsif f.proname='essay_refund' then execute format('grant execute on function %s to essay_finance',f.signature);
   else execute format('grant execute on function %s to essay_worker',f.signature);end if;
  end if;
 end loop;
end$$;
revoke create on schema public,essay_private from essay_executor;
revoke essay_executor from current_user;
commit;
