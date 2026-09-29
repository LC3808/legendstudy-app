-- Scaffolding persistence / Owner approved implementation; NOT APPLIED to Production.
-- Forward-only: KEEP19, exactly one nullable column; no student seed or provider call.
begin;
grant essay_executor to current_user;
grant create on schema public,essay_private to essay_executor;


-- Strict shape validation is row-local; cross-row/source checks run in finalize.
create function essay_private.scaffold_envelope_valid(v jsonb) returns boolean
language plpgsql immutable set search_path='' as $$
declare s jsonb; k text; ids text[]='{}'; spans text[]='{}'; span text;
begin
 if v is null then return true; end if;
 if jsonb_typeof(v)<>'object' or v-array['version','core_focus','sentences']<>'{}'::jsonb
 or v->>'version' is distinct from '1' or jsonb_typeof(v->'version') is distinct from 'number'
 or jsonb_typeof(v->'core_focus') is distinct from 'boolean'
 or jsonb_typeof(v->'sentences') is distinct from 'array' then return false; end if;
 if jsonb_array_length(v->'sentences')>5 then return false; end if;
 for s in select * from jsonb_array_elements(v->'sentences') loop
  if jsonb_typeof(s)<>'object' or s-array['observation_key','category','priority','start','end','quote','diagnosis','direction','example']<>'{}'::jsonb then return false; end if;
  foreach k in array array['observation_key','category','priority','quote','diagnosis','direction'] loop
   if jsonb_typeof(s->k) is distinct from 'string' or (s->>k)!~'[^[:space:]]' then return false; end if;
  end loop;
  if s->>'category' not in ('grammar','expression','structure','logic') or s->>'priority' not in ('contradiction','unclear_meaning','grammar_agreement','wording') then return false; end if;
  if s ? 'example' and (jsonb_typeof(s->'example') is distinct from 'string' or (s->>'example')!~'[^[:space:]]') then return false; end if;
  foreach k in array array['start','end'] loop
   if jsonb_typeof(s->k) is distinct from 'number' or (s->>k)!~'^[0-9]{1,5}$' then return false; end if;
  end loop;
  if (s->>'start')::integer >= (s->>'end')::integer or (s->>'end')::integer>20000 then return false; end if;
  span=(s->>'start')||':'||(s->>'end');
  if s->>'observation_key'=any(ids) or span=any(spans) then return false; end if;
  ids=array_append(ids,s->>'observation_key');spans=array_append(spans,span);
 end loop;
 return true;
exception when others then return false;
end$$;
alter table public.essay_improvement_progress add column scaffolding_observation jsonb null
 constraint essay_scaffold_shape check(essay_private.scaffold_envelope_valid(scaffolding_observation));
comment on column public.essay_improvement_progress.scaffolding_observation is
 '1.3 immutable observation: version=1, core_focus boolean, sentences array. SQL NULL=legacy/not provided; []=supported no observations. Parent issue/evaluation binds source.';

-- Called under existing account/session locks. Snapshot never follows a moving latest at finalize.
create function essay_private.scaffold_context(p_attempt uuid,p_regime text,p_criteria jsonb,p_evidence jsonb) returns jsonb
language plpgsql set search_path='' as $$
declare a public.essay_attempts; selected uuid; items jsonb; context jsonb;
begin
 select * into a from public.essay_attempts where id=p_attempt;
 select e.id into selected from public.essay_evaluations e join public.essay_attempts pa on pa.id=e.attempt_id
 where e.session_id=a.session_id and pa.attempt_no<a.attempt_no and e.status='completed' and e.invalidated_at is null
 and e.contract_version='1.3' and e.regime_key=p_regime and e.input_snapshot->'criteria'=p_criteria
 and e.input_snapshot->'evidence'=p_evidence order by pa.attempt_no desc,e.requested_at desc,e.id desc limit 1;
 -- Latest observation per root carries unassessed earlier focus forward without inventing status.
 select coalesce(jsonb_agg(q.item order by q.issue_id),'[]'::jsonb) into items from (
  select distinct on(p.issue_id) p.issue_id,jsonb_build_object('progress_id',p.id,'issue_id',p.issue_id,'issue_key',i.issue_key,
   'evaluation_id',e.id,'attempt_id',pa.id,'answer_hash',pa.body_sha256,'status',p.status,'title',p.title,
   'explanation',p.explanation,'action',p.next_action,'observation',p.scaffolding_observation,
   'official_evidence_ids',(select coalesce(jsonb_agg(ev.evidence_id order by ev.evidence_id),'[]'::jsonb) from public.essay_evaluation_evidence ev where ev.improvement_progress_id=p.id)) item
  from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
  join public.essay_evaluations e on e.id=p.evaluation_id join public.essay_attempts pa on pa.id=e.attempt_id
  where e.session_id=a.session_id and pa.attempt_no<a.attempt_no and e.status='completed' and e.invalidated_at is null
  and e.contract_version='1.3' and e.regime_key=p_regime and e.input_snapshot->'criteria'=p_criteria
  and e.input_snapshot->'evidence'=p_evidence and p.scaffolding_observation is not null
  order by p.issue_id,pa.attempt_no desc,e.requested_at desc,e.id desc
 ) q;
 context=jsonb_build_object('version',1,'selected_previous_evaluation_id',selected,'comparison_regime',p_regime,
  'availability',case when selected is null then 'no_compatible_history' else 'compatible' end,'items',items,
  'previous_core_progress_ids',(select coalesce(jsonb_agg(x->'progress_id'),'[]'::jsonb) from jsonb_array_elements(items) x where x->'observation'->'core_focus'='true'::jsonb and x->>'status'<>'resolved'),
  'previous_resolved_progress_ids',(select coalesce(jsonb_agg(x->'progress_id'),'[]'::jsonb) from jsonb_array_elements(items) x where x->>'status'='resolved'));
 return context||jsonb_build_object('history_manifest_sha256',essay_private.hash(context::text));
end$$;

-- Trusted worker payload, not raw provider JSON. local_reviews is supplied only by the
-- independent server adapter review input; it is not inferred from provider claim_scope.
create function essay_private.scaffold_validate(p_evaluation uuid,o jsonb) returns jsonb
language plpgsql set search_path='' as $$
declare e public.essay_evaluations; a public.essay_attempts; x jsonb; s jsonb; prior jsonb; review jsonb; approval jsonb;
 env jsonb; normalized jsonb='[]'; quoted jsonb; history jsonb; k text; key text; seen_ids text[]='{}'; spans text[]='{}'; span text;
 cores text[]; reviews text[]='{}'; linked text[]='{}'; uncertainty text=''; scope text;
begin
 select * into e from public.essay_evaluations where id=p_evaluation;
 select * into a from public.essay_attempts where id=e.attempt_id;
 if e.contract_version<>'1.3' or e.input_snapshot->>'answer_hash' is distinct from a.body_sha256
 or essay_private.hash(a.body) is distinct from a.body_sha256 or e.evidence_manifest_sha256 is distinct from essay_private.hash(e.input_snapshot::text)
 or o->>'answer_hash' is distinct from a.body_sha256 or o->>'attempt_id' is distinct from a.id::text then raise sqlstate 'PT422' using message='INVALID_SOURCE_BINDING';end if;
 history=e.input_snapshot->'scaffolding_context';
 if history->>'history_manifest_sha256' is distinct from essay_private.hash((history-'history_manifest_sha256')::text) then raise sqlstate 'PT422' using message='INVALID_HISTORY_MANIFEST';end if;
 if jsonb_typeof(o)<>'object' or o-array['contract_version','summary','strengths','checklist','dimensions','improvements','attempt_id','answer_hash','core_improvement_keys','previous_improvement_reviews','sentence_feedback','local_reviews']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_SCAFFOLD_OUTPUT';end if;
 foreach k in array array['core_improvement_keys','previous_improvement_reviews','sentence_feedback','improvements','local_reviews'] loop
  if jsonb_typeof(o->k) is distinct from 'array' then raise sqlstate 'PT422' using message='INVALID_SCAFFOLD_OUTPUT';end if;
 end loop;
 if jsonb_array_length(o->'sentence_feedback')>5 or jsonb_array_length(o->'core_improvement_keys')>3 then raise sqlstate 'PT422' using message='SCAFFOLD_LIMIT';end if;
 select coalesce(array_agg(v#>>'{}'),'{}') into cores from jsonb_array_elements(o->'core_improvement_keys') v;
 if exists(select 1 from jsonb_array_elements(o->'core_improvement_keys') v where jsonb_typeof(v)<>'string' or nullif(btrim(v#>>'{}'),'') is null)
 or cardinality(cores)<>(select count(distinct v) from unnest(cores) v) then raise sqlstate 'PT422' using message='INVALID_CORE';end if;
 if (select count(distinct v->>'issue_key') from jsonb_array_elements(o->'improvements') v)<>jsonb_array_length(o->'improvements') then raise sqlstate 'PT422' using message='DUPLICATE_ROOT';end if;
 if exists(select 1 from unnest(cores) v where not exists(select 1 from jsonb_array_elements(o->'improvements') i where i->>'issue_key'=v and i->>'status'<>'resolved')) then raise sqlstate 'PT422' using message='INVALID_CORE';end if;
 -- Review coverage/identity is checked before any current task or result is written.
 for review in select * from jsonb_array_elements(o->'previous_improvement_reviews') loop
  if jsonb_typeof(review)<>'object' or review-array['previous_progress_id','outcome','reason']<>'{}'::jsonb
   or jsonb_typeof(review->'reason') is distinct from 'string' or nullif(btrim(review->>'reason'),'') is null
   or review->>'outcome' is null or review->>'outcome' not in ('open','unchanged','improved','resolved','recurred','not_assessable') then raise sqlstate 'PT422' using message='INVALID_PREVIOUS_REVIEW';end if;
  select v into prior from jsonb_array_elements(history->'items') v where v->>'progress_id'=review->>'previous_progress_id';
  if prior is null or review->>'previous_progress_id'=any(reviews) then raise sqlstate 'PT422' using message='INVALID_PREVIOUS_REVIEW';end if;
  if not exists(select 1 from public.essay_improvement_progress p join public.essay_evaluations pe on pe.id=p.evaluation_id where p.id=(prior->>'progress_id')::uuid and pe.invalidated_at is null and pe.status='completed' and pe.session_id=e.session_id and pe.regime_key=e.regime_key) then raise sqlstate 'PT422' using message='INVALID_PREVIOUS_REVIEW';end if;
  reviews=array_append(reviews,review->>'previous_progress_id');
  if review->>'outcome'='not_assessable' then
   if exists(select 1 from jsonb_array_elements(o->'improvements') v where v->>'previous_progress_id'=review->>'previous_progress_id' or v->>'issue_key'=prior->>'issue_key') then raise sqlstate 'PT422' using message='UNKNOWN_NOT_A_STATUS';end if;
   uncertainty=uncertainty||case when uncertainty='' then '' else E'\n' end||(prior->>'title')||': '||(review->>'reason');
  else
   select v into x from jsonb_array_elements(o->'improvements') v where v->>'previous_progress_id'=review->>'previous_progress_id';
   if x is null or x->>'issue_key' is distinct from prior->>'issue_key' or x->>'status' is distinct from review->>'outcome' then raise sqlstate 'PT422' using message='INVALID_PROGRESS_LINK';end if;
   if (review->>'outcome'='recurred' and prior->>'status'<>'resolved') or (prior->>'status'='resolved' and review->>'outcome' not in ('resolved','recurred')) then raise sqlstate 'PT422' using message='INVALID_RECURRENCE';end if;
  end if;
 end loop;
 if exists(select 1 from jsonb_array_elements_text(history->'previous_core_progress_ids') v where not(v=any(reviews))) then raise sqlstate 'PT422' using message='MISSING_PREVIOUS_CORE_REVIEW';end if;
 for s in select * from jsonb_array_elements(o->'sentence_feedback') loop
  key=s->>'linked_issue_key';
  if jsonb_typeof(s->'linked_issue_key') is distinct from 'string' or key is null or not exists(select 1 from jsonb_array_elements(o->'improvements') i where i->>'issue_key'=key and i->>'status'<>'resolved') then raise sqlstate 'PT422' using message='INVALID_SENTENCE_LINK';end if;
  if not essay_private.scaffold_envelope_valid(jsonb_build_object('version',1,'core_focus',false,'sentences',jsonb_build_array(s-'linked_issue_key'))) then raise sqlstate 'PT422' using message='INVALID_SENTENCE_SHAPE';end if;
  if (s->>'end')::int>char_length(a.body) or substring(a.body from (s->>'start')::int+1 for (s->>'end')::int-(s->>'start')::int) is distinct from s->>'quote' then raise sqlstate 'PT422' using message='INVALID_QUOTE';end if;
  span=(s->>'start')||':'||(s->>'end');
  if s->>'observation_key'=any(seen_ids) or span=any(spans) then raise sqlstate 'PT422' using message='DUPLICATE_SENTENCE';end if;
  seen_ids=array_append(seen_ids,s->>'observation_key');spans=array_append(spans,span);
 end loop;
 if (select count(distinct v->'issue'->>'issue_key') from jsonb_array_elements(o->'local_reviews') v)<>jsonb_array_length(o->'local_reviews') then raise sqlstate 'PT422' using message='DUPLICATE_LOCAL_REVIEW';end if;
 for x in select * from jsonb_array_elements(o->'improvements') loop
  key=x->>'issue_key'; scope=x->>'claim_scope';
  if jsonb_typeof(x)<>'object' or x-array['issue_key','category','status','previous_progress_id','title','explanation','action','priority','evidence_ids','claim_scope']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_IMPROVEMENT';end if;
  foreach k in array array['issue_key','category','status','title','explanation','action','claim_scope'] loop
   if jsonb_typeof(x->k) is distinct from 'string' or (x->>k)!~'[^[:space:]]' then raise sqlstate 'PT422' using message='INVALID_IMPROVEMENT';end if;
  end loop;
  if scope not in ('official_criterion','local_sentence') or jsonb_typeof(x->'evidence_ids') is distinct from 'array' or jsonb_typeof(x->'priority') is distinct from 'number' or (x->>'priority')!~'^[1-9][0-9]{0,3}$' then raise sqlstate 'PT422' using message='INVALID_IMPROVEMENT';end if;
  if key=any(cores) and (x->>'priority')::int<>array_position(cores,key) then raise sqlstate 'PT422' using message='INVALID_CORE_ORDER';end if;
  select v into prior from jsonb_array_elements(history->'items') v where v->>'issue_key'=key;
  if prior is not null and x->>'previous_progress_id' is distinct from prior->>'progress_id' then raise sqlstate 'PT422' using message='MISSING_PROGRESS_LINK';end if;
  if x->>'previous_progress_id' is not null then
   if not(x->>'previous_progress_id'=any(reviews)) or x->>'previous_progress_id'=any(linked) then raise sqlstate 'PT422' using message='INVALID_PROGRESS_LINK';end if;
   linked=array_append(linked,x->>'previous_progress_id');
  elsif x->>'status'<>'open' then raise sqlstate 'PT422' using message='INVALID_NEW_ROOT';end if;
  select coalesce(jsonb_agg(v),'[]'::jsonb) into quoted from jsonb_array_elements(o->'sentence_feedback') v where v->>'linked_issue_key'=key;
  if scope='official_criterion' then
   if jsonb_array_length(x->'evidence_ids')=0 then raise sqlstate 'PT422' using message='OFFICIAL_EVIDENCE_REQUIRED';end if;
  else
   -- Reviewed assertion must match the exact root and its sentence payload; no free scope flag.
   select v into approval from jsonb_array_elements(o->'local_reviews') v where v->'issue'=x and v->'sentences'=quoted;
   if approval is null or approval-array['issue','sentences','reviewer','decision']<>'{}'::jsonb or approval->>'decision' is distinct from 'local_only'
    or jsonb_typeof(approval->'reviewer') is distinct from 'string' or nullif(btrim(approval->>'reviewer'),'') is null then raise sqlstate 'PT422' using message='LOCAL_REVIEW_REQUIRED';end if;
   if jsonb_array_length(x->'evidence_ids')<>0 then raise sqlstate 'PT422' using message='LOCAL_OFFICIAL_PROVENANCE_MIX';end if;
   if jsonb_array_length(quoted)=0 and not(x->>'status'='resolved' and prior is not null
     and jsonb_array_length(prior->'observation'->'sentences')>0 and jsonb_array_length(prior->'official_evidence_ids')=0) then raise sqlstate 'PT422' using message='LOCAL_QUOTE_REQUIRED';end if;
  end if;
  env=jsonb_build_object('version',1,'core_focus',key=any(cores),'sentences',(select coalesce(jsonb_agg(v-'linked_issue_key'),'[]'::jsonb) from jsonb_array_elements(quoted) v));
  normalized=normalized||jsonb_build_array(x||jsonb_build_object('scaffolding_observation',env));
 end loop;
 if exists(select 1 from jsonb_array_elements(o->'local_reviews') v where not exists(select 1 from jsonb_array_elements(o->'improvements') i where i=v->'issue' and i->>'claim_scope'='local_sentence')) then raise sqlstate 'PT422' using message='UNUSED_LOCAL_REVIEW';end if;
 return o||jsonb_build_object('improvements',normalized,'uncertainty_note',nullif(uncertainty,''));
end$$;


-- Frozen v1.2 implementation, callable only inside executor boundary.
create function essay_private.scaffold_legacy_essay_request_evaluation(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid language plpgsql security definer set search_path='' as $$
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

-- Frozen v1.2 implementation, callable only inside executor boundary.
create function essay_private.scaffold_legacy_essay_claim(p_evaluation uuid,p_rewrite uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
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

-- Frozen v1.2 implementation, callable only inside executor boundary.
create function essay_private.scaffold_legacy_essay_finalize_success(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
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

create function essay_private.scaffold_request_v13(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid language plpgsql security definer set search_path='' as $$
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
  select g.id into grant_id from public.credit_grants g where g.account_id=account and (g.expires_at is null or g.expires_at>essay_private.clock())
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
end$$;

create function essay_private.scaffold_claim_v13(p_evaluation uuid,p_rewrite uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
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
 values(case when p_rewrite is null then e.id end,p_rewrite,n,'unconfigured',e.regime_key,'scaffolding-1.3-v1','processing',gen_random_uuid(),essay_private.clock()+interval '120 seconds') returning * into r;
 if p_rewrite is null then update public.essay_evaluations set status='processing' where id=e.id;
 else update public.essay_generated_rewrites set status='processing' where id=p_rewrite;end if;
 select body into answer from public.essay_attempts where id=e.attempt_id;
 return jsonb_build_object('run_id',r.id,'lease_token',r.lease_token,'lease_expires_at',r.lease_expires_at,'generation',n,'answer',answer,'input',e.input_snapshot,
 'improvements',case when p_rewrite is not null then (select jsonb_agg(jsonb_build_object('title',title,'action',next_action)) from public.essay_improvement_progress where evaluation_id=e.id) end);
end$$;

create function essay_private.scaffold_finalize_v13(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
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
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(b.account_id,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,'essay_cycle_v1'); n=n+t.reserved_delta;
  end loop;
  if n<>b.credits_required then raise sqlstate 'PT409' using message='RESERVATION_MISMATCH';end if;
  update public.essay_billing_decisions set status='settled',settled_at=essay_private.clock() where id=b.id;
 end if;
 update public.essay_ai_processing_runs set status='completed',selected_result=true,completed_at=essay_private.clock(),input_sha256=e.evidence_manifest_sha256,output_sha256=h where id=r.id;
 return coalesce(p_rewrite,e.id);
end$$;

-- Same public signatures and allowlists; new regime is explicit, never auto-upgrade an old request.
create or replace function public.essay_request_evaluation(p_attempt uuid,p_key uuid,p_regime text default 'essay-v1.2') returns uuid
language plpgsql security definer set search_path='' as $$begin
 if p_regime in ('essay-v1.3','essay-v1.3-next-model') then return essay_private.scaffold_request_v13(p_attempt,p_key,p_regime);end if;
 return essay_private.scaffold_legacy_essay_request_evaluation(p_attempt,p_key,p_regime);
end$$;
create or replace function public.essay_claim(p_evaluation uuid,p_rewrite uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from public.essay_evaluations where id=p_evaluation and contract_version='1.3') then return essay_private.scaffold_claim_v13(p_evaluation,p_rewrite);end if;
 return essay_private.scaffold_legacy_essay_claim(p_evaluation,p_rewrite);
end$$;
create or replace function public.essay_finalize_success(p_evaluation uuid,p_run uuid,p_token uuid,p_output jsonb,p_rewrite uuid default null) returns uuid
language plpgsql security definer set search_path='' as $$begin
 if exists(select 1 from public.essay_evaluations where id=p_evaluation and contract_version='1.3') then return essay_private.scaffold_finalize_v13(p_evaluation,p_run,p_token,p_output,p_rewrite);end if;
 return essay_private.scaffold_legacy_essay_finalize_success(p_evaluation,p_run,p_token,p_output,p_rewrite);
end$$;
-- Explicit ACL including Supabase service_role default grants. Helpers are not public RPCs.
do $$declare f record;begin
 for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='essay_private' and p.proname like 'scaffold_%' loop
  execute format('alter function %s owner to essay_executor',f.signature);
  execute format('revoke all on function %s from public,anon,authenticated,service_role,essay_worker,essay_finance',f.signature);
 end loop;
end$$;
revoke all on function public.essay_request_evaluation(uuid,uuid,text),public.essay_claim(uuid,uuid),public.essay_finalize_success(uuid,uuid,uuid,jsonb,uuid) from public,anon,authenticated,service_role,essay_worker,essay_finance;
grant execute on function public.essay_request_evaluation(uuid,uuid,text) to authenticated;
grant execute on function public.essay_claim(uuid,uuid),public.essay_finalize_success(uuid,uuid,uuid,jsonb,uuid) to essay_worker;
revoke create on schema public,essay_private from essay_executor;
revoke essay_executor from current_user;
commit;
