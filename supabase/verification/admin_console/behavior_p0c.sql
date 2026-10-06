-- ADMIN-P0-C behavioral verification.
--
-- Runs last, after behavior.sql / behavior_p0b.sql / behavior_notifications.sql,
-- against the same isolated cluster. Covers the Essay/Math operations read model:
--   A. Authorization boundary
--   B. Answer text is never read
--   C. Essay pipeline reporting (status, outcome, timing, model, Credits,
--      re-evaluation, invalidation)
--   D. Human review state
--   E. Math degradation
--   F. Summary and bounds
\set ON_ERROR_STOP on
create or replace function pg_temp.check(p_name text, p_ok boolean) returns void
language plpgsql as $$
begin
 insert into admin_verify(name,ok) values(p_name,coalesce(p_ok,false));
 if not coalesce(p_ok,false) then raise warning 'CHECK FAILED: %', p_name; end if;
end$$;
create or replace function pg_temp.as_admin() returns void language plpgsql as $$
begin perform set_config('request.jwt.claims',
 json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
end$$;
create or replace function pg_temp.as_anon() returns void language plpgsql as $$
begin perform set_config('request.jwt.claims','',true); end$$;
create or replace function pg_temp.err(p_sql text) returns text language plpgsql as $$
begin execute p_sql; return 'NONE'; exception when others then return sqlstate; end$$;

-- ---------------------------------------------------------------------------
-- Fixture: one essay chain for the existing member, with the five evaluation
-- shapes an operator actually has to tell apart, plus a credit account and a
-- settled billing decision.
-- ---------------------------------------------------------------------------
insert into public.universities(id,slug,name) values ('a0000000-0000-4000-8000-0000000000aa','p0c-ops','P0C 운영 점검 대학')
on conflict do nothing;
insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind)
values ('b0000000-0000-4000-8000-0000000000bb','a0000000-0000-4000-8000-0000000000aa',2026,
        'p0c-ops-mock','P0C 운영 점검 모의','mock')
on conflict do nothing;
insert into public.essay_questions(id,essay_exam_id,question_key,label,display_order,metadata_version)
values ('c0000000-0000-4000-8000-0000000000cc','b0000000-0000-4000-8000-0000000000bb',
        'p0c-ops-q1','P0C 운영 점검 문항',1,'v1')
on conflict do nothing;
insert into public.essay_practice_sessions(id,user_id,question_id)
values ('d0000000-0000-4000-8000-0000000000d1','22222222-2222-4222-8222-222222222222',
        'c0000000-0000-4000-8000-0000000000cc')
on conflict do nothing;
insert into public.essay_attempts(id,session_id,attempt_no,body,body_sha256,input_method,device_class,
       mode,started_at,character_count,count_rule_version,question_metadata_version,conditions_snapshot,submission_key)
values ('e0000000-0000-4000-8000-0000000000e1','d0000000-0000-4000-8000-0000000000d1',1,
        'P0C-SECRET-ANSWER-TEXT', repeat('a',64), 'typed', 'web_desktop', 'practice', now(), 22, 'v1', 'v1', '{}'::jsonb,
        'e1000000-0000-4000-8000-0000000000e1')
on conflict do nothing;

do $$
declare sid uuid := 'd0000000-0000-4000-8000-0000000000d1';
        qid uuid := 'c0000000-0000-4000-8000-0000000000cc';
        aid uuid := 'e0000000-0000-4000-8000-0000000000e1';
        t0 timestamptz := essay_private.clock() - interval '2 hours';
begin
  -- 1. requested, still pending
  insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,
         request_hash,status,evaluation_version,contract_version,regime_key,
         evidence_manifest_sha256,evidence_completeness,requested_at)
  values ('f0000000-0000-4000-8000-0000000000f1',aid,sid,qid,'f1000000-0000-4000-8000-0000000000f1',
          repeat('b',64),'requested','v1','v1','p0c-a',repeat('b',64),'complete', t0)
  on conflict do nothing;

  -- 2. completed, the success shape (the table's own constraint requires the
  --    model, prompt, hashes and summary to be real before this is allowed)
  insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,
         request_hash,status,evaluation_version,contract_version,regime_key,
         evidence_manifest_sha256,evidence_completeness,model_provider,model_name,prompt_version,
         overall_summary,input_sha256,output_sha256,requested_at,completed_at,terminated_at)
  values ('f0000000-0000-4000-8000-0000000000f2',aid,sid,qid,'f1000000-0000-4000-8000-0000000000f2',
          repeat('b',64),'completed','v1','v1','p0c-b',repeat('b',64),'complete','openai','gpt-5','essay-prompt-v3',
          '점검용 요약',repeat('c',64),repeat('d',64),t0,t0+interval '40 seconds',t0+interval '40 seconds')
  on conflict do nothing;

  -- 3. failed
  insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,
         request_hash,status,evaluation_version,contract_version,regime_key,
         evidence_manifest_sha256,evidence_completeness,error_code,requested_at,terminated_at)
  values ('f0000000-0000-4000-8000-0000000000f3',aid,sid,qid,'f1000000-0000-4000-8000-0000000000f3',
          repeat('b',64),'failed','v1','v1','p0c-c',repeat('b',64),'complete','PROCESSING_FAILED',t0,t0+interval '12 seconds')
  on conflict do nothing;

  -- 4. completed, then invalidated
  insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,
         request_hash,status,evaluation_version,contract_version,regime_key,
         evidence_manifest_sha256,evidence_completeness,model_provider,model_name,prompt_version,
         overall_summary,input_sha256,output_sha256,requested_at,completed_at,terminated_at,
         invalidated_at,invalidation_reason)
  values ('f0000000-0000-4000-8000-0000000000f4',aid,sid,qid,'f1000000-0000-4000-8000-0000000000f4',
          repeat('b',64),'completed','v1','v1','p0c-d',repeat('b',64),'complete','openai','gpt-5','essay-prompt-v3',
          '점검용 요약',repeat('c',64),repeat('e',64),t0,t0+interval '30 seconds',t0+interval '30 seconds',
          t0+interval '50 seconds','원문 불일치')
  on conflict do nothing;

  -- 5. a re-evaluation that supersedes #2
  insert into public.essay_evaluations(id,attempt_id,session_id,question_id,idempotency_key,
         request_hash,status,evaluation_version,contract_version,regime_key,
         evidence_manifest_sha256,evidence_completeness,model_provider,model_name,prompt_version,
         overall_summary,input_sha256,output_sha256,requested_at,completed_at,terminated_at,
         supersedes_evaluation_id,correction_reason)
  values ('f0000000-0000-4000-8000-0000000000f5',aid,sid,qid,'f1000000-0000-4000-8000-0000000000f5',
          repeat('b',64),'completed','v1','v1','p0c-e',repeat('b',64),'complete','openai','gpt-5','essay-prompt-v3',
          '재평가 요약',repeat('c',64),repeat('f',64),t0,t0+interval '60 seconds',t0+interval '60 seconds',
          'f0000000-0000-4000-8000-0000000000f2','운영 재검토')
  on conflict do nothing;
end$$;

insert into public.credit_accounts(user_id) values ('22222222-2222-4222-8222-222222222222')
on conflict(user_id) do nothing;
insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,
       policy_version,reason,credits_required,status,settled_at)
select a.id,'f0000000-0000-4000-8000-0000000000f2','f2000000-0000-4000-8000-0000000000f2',
       'essay.credit.v2','v2','paid_cycle',1,'settled',essay_private.clock()
  from public.credit_accounts a where a.user_id='22222222-2222-4222-8222-222222222222'
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- A. Authorization boundary
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
  perform pg_temp.as_anon();
  perform pg_temp.check('C1 an anonymous caller is refused FORBIDDEN',
    pg_temp.err($q$select public.admin_essay_operations(25,null,null)$q$) = 'PT403');
  perform pg_temp.check('C1b the Math read is refused the same way',
    pg_temp.err($q$select public.admin_math_operations(25,null)$q$) = 'PT403');
  perform pg_temp.check('C1c the operations summary is refused the same way',
    pg_temp.err($q$select public.admin_operations_summary()$q$) = 'PT403');

  perform pg_temp.as_admin();
  r := public.admin_essay_operations(25, null, null);
  perform pg_temp.check('C2 the operator gate opens the read', (r->>'available')::boolean);
  perform pg_temp.check('C2b the payload is versioned and typed',
    r->>'dto_version' = 'admin-ops-v1' and r->>'type' = 'humanities');
end$$;

-- ---------------------------------------------------------------------------
-- B. The answer text is not reachable through this read
-- ---------------------------------------------------------------------------
do $$
declare r jsonb; flat text;
begin
  perform pg_temp.as_admin();
  r := public.admin_essay_operations(25, null, null);
  flat := r::text;
  perform pg_temp.check('C3 the answer body never appears in the payload',
    position('P0C-SECRET-ANSWER-TEXT' in flat) = 0);
  perform pg_temp.check('C3b no item carries a body or draft field',
    not exists (select 1 from jsonb_array_elements(r->'items') i
                 where (i) ? 'body' or (i) ? 'draft' or (i) ? 'typed_answer'));
end$$;

-- ---------------------------------------------------------------------------
-- C. Essay pipeline reporting
-- ---------------------------------------------------------------------------
do $$
declare r jsonb; items jsonb;
begin
  perform pg_temp.as_admin();
  r := public.admin_essay_operations(25, null, null);
  items := r->'items';
  perform pg_temp.check('C4 every fixture evaluation is listed', jsonb_array_length(items) = 5);

  perform pg_temp.check('C5 a completed evaluation reports success',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'outcome') = 'success' and (i->>'status') = 'completed'));
  perform pg_temp.check('C5b the completed row carries the processing time',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'processing_ms')::bigint = 40000));
  perform pg_temp.check('C5c the completed row carries the provider, model and prompt',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'model_provider') = 'openai'
               and (i->>'model_name') = 'gpt-5'
               and (i->>'prompt_version') = 'essay-prompt-v3'));

  perform pg_temp.check('C6 a failed evaluation reports failure and its error code',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f3'
               and (i->>'outcome') = 'failure'
               and (i->>'error_code') = 'PROCESSING_FAILED'));
  perform pg_temp.check('C6b a failed evaluation still reports its elapsed time',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f3'
               and (i->>'processing_ms')::bigint = 12000));

  perform pg_temp.check('C7 a pending request reports pending, not failure',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f1'
               and (i->>'outcome') = 'pending'));

  perform pg_temp.check('C8 an invalidated evaluation is flagged with its reason',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f4'
               and (i->>'invalidated')::boolean
               and (i->>'invalidation_reason') = '원문 불일치'));

  perform pg_temp.check('C9 a re-evaluation is flagged and the original is not',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f5'
               and (i->>'is_reevaluation')::boolean)
    and exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and not (i->>'is_reevaluation')::boolean));

  perform pg_temp.check('C10 Credits come from the billing decision, not the evaluation',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'credits_charged')::integer = 1
               and (i->>'billing_status') = 'settled'
               and (i->>'billing_reason') = 'paid_cycle'));
  perform pg_temp.check('C10b an evaluation with no decision reports no Credits rather than zero',
    exists (select 1 from jsonb_array_elements(items) i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f3'
               and (i->'credits_charged') = 'null'::jsonb));

  perform pg_temp.check('C10c the summary counts each status',
    (r->'summary'->>'total')::integer = 5
    and (r->'summary'->>'completed')::integer = 3
    and (r->'summary'->>'failed')::integer = 1
    and (r->'summary'->>'requested')::integer = 1
    and (r->'summary'->>'reevaluations')::integer = 1);

  perform pg_temp.check('C11 the status filter narrows the list',
    jsonb_array_length(public.admin_essay_operations(25,'completed',null)->'items') = 3);
  perform pg_temp.check('C11b an unknown status is refused',
    pg_temp.err($q$select public.admin_essay_operations(25,'bogus',null)$q$) = 'PT422');
end$$;

-- ---------------------------------------------------------------------------
-- D. Human review state
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
  perform pg_temp.as_admin();
  r := public.admin_essay_operations(25, null, null);
  perform pg_temp.check('C12 human review is reported as tracked',
    (r->>'human_review_tracked')::boolean);
  perform pg_temp.check('C12b an unreviewed evaluation says so',
    exists (select 1 from jsonb_array_elements(r->'items') i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'human_review_state') = 'NOT_REVIEWED'
               and (i->'human_review_disposition') = 'null'::jsonb));
end$$;

-- A judgment makes the same row read as reviewed. The judgment is written
-- directly because the quality write path is gated by the quality role, which
-- this console deliberately does not hold.
insert into public.human_quality_judgments(evaluation_id,reviewed_output_sha256,reviewer_user_id,
       rubric_version,overall_disposition,rubric_result,selection_reason,recommended_action,
       client_submission_id,submission_payload_sha256)
values ('f0000000-0000-4000-8000-0000000000f2', repeat('d',64),
        '11111111-1111-4111-8111-111111111111','hq-rubric-v1','PASS_WITH_NOTES',
        jsonb_build_object('diagnosis','OK','core_priority','OK','actionability','CONCERN',
                           'evidence_adherence','OK','stance_preservation','OK',
                           'hallucination_absence','OK',
                           'sentence_feedback','NA','progression','NA','generated_rewrite','NA'),
        'OPERATOR_REQUEST','MONITOR',
        'f3000000-0000-4000-8000-0000000000f3', repeat('9',64))
on conflict do nothing;

do $$
declare r jsonb; s jsonb;
begin
  perform pg_temp.as_admin();
  r := public.admin_essay_operations(25, null, null);
  perform pg_temp.check('C13 a reviewed evaluation reports the state and the disposition',
    exists (select 1 from jsonb_array_elements(r->'items') i
             where (i->>'evaluation_id') = 'f0000000-0000-4000-8000-0000000000f2'
               and (i->>'human_review_state') = 'REVIEWED'
               and (i->>'human_review_disposition') = 'PASS_WITH_NOTES'
               and (i->>'human_reviewed_at') is not null));
  perform pg_temp.check('C13b the other evaluations remain unreviewed',
    (select count(*) from jsonb_array_elements(r->'items') i
      where (i->>'human_review_state') = 'NOT_REVIEWED') = 4);

  s := public.admin_operations_summary();
  perform pg_temp.check('C14 the summary reports the reviewed case count',
    (s->>'human_review_tracked')::boolean and (s->>'human_reviewed_cases')::integer = 1);
  perform pg_temp.check('C14b the summary carries the essay availability and activity',
    (s->'essay'->>'available')::boolean
    and (s->'essay'->'summary'->>'total')::integer = 5
    and (s->'essay'->'summary'->>'succeeded')::integer = 3);
end$$;

-- ---------------------------------------------------------------------------
-- E. Math degradation — the Math runtime is not installed in this chain, and
--    that must read as absent, never as zero activity.
-- ---------------------------------------------------------------------------
do $$
declare r jsonb; s jsonb;
begin
  perform pg_temp.as_admin();
  r := public.admin_math_operations(25, null);
  -- This chain carries the Math tables in their partial form, so the honest
  -- answer is "the runtime is not fully deployed", not "no Math activity".
  perform pg_temp.check('C15 partially deployed Math is reported unavailable',
    not (r->>'available')::boolean and r->>'reason' = 'SCHEMA_INCOMPLETE');
  perform pg_temp.check('C15b unavailable Math reports no summary instead of a zero summary',
    (r->'summary') = 'null'::jsonb and r->'items' = '[]'::jsonb);
  perform pg_temp.check('C15c unavailable Math is typed, so the console can label it',
    r->>'type' = 'math');
  perform pg_temp.check('C15d a partial table is never read as an installed runtime',
    case when (select count(*) from information_schema.columns
                where table_schema='public' and table_name='math_evaluations') < 8
         then (r->>'reason') = 'SCHEMA_INCOMPLETE'
         else true end);

  s := public.admin_operations_summary();
  perform pg_temp.check('C16 the summary distinguishes undeployed Math from idle Math',
    not (s->'math'->>'available')::boolean and (s->'math'->>'reason') = 'SCHEMA_INCOMPLETE'
    and (s->'math'->'summary') = 'null'::jsonb);
  perform pg_temp.check('C16b the summary names its own as-of time',
    (s->>'as_of') is not null);
end$$;

-- ---------------------------------------------------------------------------
-- F. Bounds and ACL
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
  perform pg_temp.as_admin();
  r := public.admin_essay_operations(100000, null, null);
  perform pg_temp.check('C17 an oversized limit is clamped, not honoured',
    jsonb_array_length(r->'items') <= 100);
  perform pg_temp.check('C17b a null limit falls back to the default',
    jsonb_array_length(public.admin_essay_operations(null,null,null)->'items') = 5);
  perform pg_temp.check('C17c a zero limit still returns a bounded list',
    jsonb_array_length(public.admin_essay_operations(0,null,null)->'items') = 1);
  perform pg_temp.check('C17d a cursor returns only older rows',
    jsonb_array_length(public.admin_essay_operations(25,null,essay_private.clock())->'items') = 5);
end$$;

do $$
begin
  perform pg_temp.check('C18 anon cannot execute the operations reads',
    not has_function_privilege('anon','public.admin_essay_operations(integer,text,timestamptz)','execute')
    and not has_function_privilege('anon','public.admin_math_operations(integer,timestamptz)','execute')
    and not has_function_privilege('anon','public.admin_operations_summary()','execute'));
  perform pg_temp.check('C18b but an authenticated operator can',
    has_function_privilege('authenticated','public.admin_essay_operations(integer,text,timestamptz)','execute')
    and has_function_privilege('authenticated','public.admin_math_operations(integer,timestamptz)','execute')
    and has_function_privilege('authenticated','public.admin_operations_summary()','execute'));
  perform pg_temp.check('C18c service_role is not granted the operator reads',
    not has_function_privilege('service_role','public.admin_essay_operations(integer,text,timestamptz)','execute')
    and not has_function_privilege('service_role','public.admin_operations_summary()','execute'));
  perform pg_temp.check('C18d the functions are SECURITY DEFINER with an empty search path',
    (select count(*) from pg_proc p
      where p.proname in ('admin_essay_operations','admin_math_operations','admin_operations_summary')
        and p.prosecdef
        and p.proconfig is not distinct from array['search_path=""']) = 3);
  perform pg_temp.check('C18e the shape probe is not reachable from the API surface',
    not has_function_privilege('authenticated','essay_private.admin_relation_ready(text,text[])','execute')
    and not has_function_privilege('anon','essay_private.admin_relation_ready(text,text[])','execute'));
end$$;

-- ---------------------------------------------------------------------------
-- G. Result
-- ---------------------------------------------------------------------------
do $$
declare total integer; failed integer;
begin
 select count(*), count(*) filter (where not ok) into total, failed from admin_verify where name like 'C%';
 raise notice 'ADMIN_P0C_CHECKS total=% failed=%', total, failed;
 if failed > 0 then raise warning 'ADMIN P0C FAILED: % checks', failed; end if;
end$$;