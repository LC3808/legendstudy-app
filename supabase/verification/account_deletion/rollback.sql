-- ADR-2 pre-activation rollback ONLY. Not a data-restoration procedure.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
do $$begin
 if exists(select 1 from public.account_deletion_requests) or exists(select 1 from account_private.benefit_claims)
 or exists(select 1 from account_private.benefit_delivery) or exists(select 1 from account_private.reauth_tickets)
 or exists(select 1 from public.credit_grants where external_reference like 'signup/%' or external_reference like 'erased/%')
 then raise exception 'ADR2 data exists: rollback refused';end if;
end$$;
do $$declare t text;begin
 foreach t in array array['profiles','feedback_submissions','bookmarks','recent_views','day_targets','study_sessions','mock_exam_attempts','mock_exam_answers','student_target_universities','essay_practice_sessions','essay_drafts','essay_attempts','essay_evaluations','essay_evaluation_dimensions','essay_improvement_items','essay_improvement_progress','essay_evaluation_evidence','essay_generated_rewrites','essay_learning_events','essay_ai_processing_runs','credit_accounts','credit_grants','credit_transactions','essay_billing_decisions'] loop
 if to_regclass('public.'||t) is not null then
 execute format('drop policy if exists account_lifecycle_restriction on public.%I',t);
 execute format('drop trigger if exists account_lifecycle_statement on public.%I',t);
 execute format('drop trigger if exists account_lifecycle_write on public.%I',t);
 end if;end loop;
 if to_regclass('storage.objects') is not null then execute 'drop policy if exists account_lifecycle_restriction on storage.objects';end if;
end$$;
drop trigger credit_ledger_no_update on public.credit_transactions;
drop trigger credit_grant_terms_frozen on public.credit_grants;
create trigger credit_ledger_no_update before update on public.credit_transactions for each row execute function public.essay_product_reject_update();
create trigger credit_grant_terms_frozen before update on public.credit_grants for each row execute function public.essay_product_reject_update();
CREATE OR REPLACE FUNCTION public.is_quality_operator()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare claims jsonb; expiry numeric;
begin
 -- Identity is always auth.uid(); API JWT signature validation remains at the gateway.
 -- Require an unexpired verified request context, also denying missing/malformed context.
 claims := nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if auth.uid() is null or claims->>'sub' is distinct from auth.uid()::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' then return false; end if;
 expiry := (claims->>'exp')::numeric;
 if expiry <= extract(epoch from statement_timestamp()) then return false; end if;
 return exists(select 1 from public.quality_operators q where q.user_id=auth.uid());
exception when invalid_text_representation or numeric_value_out_of_range then return false;
end$function$;
CREATE OR REPLACE FUNCTION essay_private.uid()
 RETURNS uuid
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$select auth.uid()$function$;
CREATE OR REPLACE FUNCTION essay_private.owner(p_session uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare u uuid;
begin
 u=essay_private.uid(); if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
 if not exists(select 1 from public.essay_practice_sessions where id=p_session and user_id=u) then raise sqlstate 'PT403' using message='FORBIDDEN'; end if;
 return u;
end$function$;
CREATE OR REPLACE FUNCTION essay_private.lock_job(p_evaluation uuid)
 RETURNS essay_evaluations
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
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
end$function$;
CREATE OR REPLACE FUNCTION essay_private.credit_profile_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if essay_private.credit_signup_eligible(new.id) then
 perform essay_private.credit_post_grant(new.id,3,'signup_bonus','signup_bonus/'||new.id::text,'signup_bonus_v1','system/signup_bonus',null);
 end if;return new;
end$function$;
CREATE OR REPLACE FUNCTION public.essay_claim_signup_credit()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare u uuid=essay_private.uid();begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 if not essay_private.credit_signup_eligible(u) then raise sqlstate 'PT403' using message='SIGNUP_NOT_ELIGIBLE';end if;
 return essay_private.credit_post_grant(u,3,'signup_bonus','signup_bonus/'||u::text,'signup_bonus_v1','system/signup_bonus',null);
end$function$;
CREATE OR REPLACE FUNCTION essay_private.credit_post_grant(p_user uuid, p_quantity integer, p_origin text, p_key text, p_reason text, p_actor text, p_expires timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end$function$;
create or replace function public.fetch_own_mock_attempt(p_attempt_id uuid)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare a public.mock_exam_attempts; result jsonb;
begin
  if auth.uid() is null then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;
  select * into a from public.mock_exam_attempts where id=p_attempt_id and user_id=auth.uid();
  if not found then return null; end if;
  select (to_jsonb(a)-'request_payload') || jsonb_build_object(
    'answers',(select jsonb_agg(to_jsonb(v) order by question_number) from public.mock_exam_answers v where attempt_id=a.id),
    'key_source',jsonb_build_object('version',k.version,'status',k.status,
      'source_name',k.source_name,'source_url',k.source_url,'verified_at',k.verified_at),
    'cutoff_source',case when g.id is null then null else jsonb_build_object('version',g.version,
      'status',g.status,'basis',g.basis,'certainty',g.certainty,'source_name',g.source_name,
      'source_url',g.source_url,'verified_at',g.verified_at) end)
    into result from public.answer_key_versions k left join public.grade_cutoff_versions g on g.id=a.grade_cutoff_version_id
    where k.id=a.answer_key_version_id;
  return result;
end;
$$;
create or replace function public.submit_mock_attempt(p_attempt_id uuid, p_study_session_id uuid,
  p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb)
returns jsonb language plpgsql volatile security definer set search_path = ''
as $$
declare owner_id uuid := auth.uid(); k public.answer_key_versions; g public.grade_cutoff_versions;
  prior public.mock_exam_attempts; normalized jsonb; request jsonb; questions jsonb; result jsonb;
begin
  if owner_id is null then raise exception 'LOGIN_REQUIRED' using errcode='42501'; end if;
  if p_attempt_id is null or p_answer_key_version_id is null or p_scoring_version is distinct from 'mcq5-v1' then
    raise exception 'INVALID_REQUEST' using errcode='22023'; end if;
  -- UUID-scoped lock makes identical concurrent retry atomic; collision only serializes.
  perform pg_advisory_xact_lock(hashtextextended(p_attempt_id::text,0));
  select * into prior from public.mock_exam_attempts where id=p_attempt_id;
  if found then
    if prior.user_id <> owner_id then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    normalized := public.scoring_normalize_answers(p_answers,prior.question_count);
  else
    -- New submissions require the current published key; the lock serializes demotion.
    select * into k from public.answer_key_versions
      where id=p_answer_key_version_id and status='published' and is_current for share;
    if not found then raise exception 'KEY_UNAVAILABLE' using errcode='23514'; end if;
    normalized := public.scoring_normalize_answers(p_answers,k.question_count);
  end if;
  request := jsonb_build_object('study_session_id',p_study_session_id,'key',p_answer_key_version_id,
    'cutoff',p_grade_cutoff_version_id,'engine',p_scoring_version,'answers',normalized);
  -- Existing identical retries keep their original key/cutoff, even after a current switch.
  if prior.id is not null then
    if prior.request_payload <> request then raise exception 'ATTEMPT_CONFLICT' using errcode='23505'; end if;
    return public.fetch_own_mock_attempt(prior.id);
  end if;
  if p_grade_cutoff_version_id is not null then
    select * into g from public.grade_cutoff_versions where id=p_grade_cutoff_version_id and status='published' and is_current
      and exam_subject_id=k.exam_subject_id and paper_variant=k.paper_variant and max_score=k.max_score for share;
    if not found then raise exception 'CUTOFF_UNAVAILABLE' using errcode='23514'; end if;
  end if;
  select jsonb_agg(jsonb_build_array(question_number,correct_answer,points) order by question_number)
    into questions from public.exam_questions where answer_key_version_id=k.id;
  result := public.scoring_mcq5(questions,normalized,g.minimum_scores,coalesce(g.certainty,'unavailable'));
  insert into public.mock_exam_attempts(id,user_id,study_session_id,exam_subject_id,paper_variant,
    answer_key_version_id,grade_cutoff_version_id,scoring_version,raw_score,max_score,
    question_count,correct_count,unanswered_count,grade,grade_status,request_payload)
  values(p_attempt_id,owner_id,p_study_session_id,k.exam_subject_id,k.paper_variant,k.id,g.id,p_scoring_version,
    (result->>'raw_score')::integer,(result->>'max_score')::integer,k.question_count,
    (result->>'correct_count')::smallint,(result->>'unanswered_count')::smallint,
    (result->>'grade')::smallint,result->>'grade_status',request);
  insert into public.mock_exam_answers(attempt_id,question_number,answer_key_version_id,
    submitted_answer,correct_answer_snapshot,points_snapshot)
  select p_attempt_id,question_number,k.id,(normalized->>(question_number-1))::smallint,correct_answer,points
    from public.exam_questions where answer_key_version_id=k.id;
  return public.fetch_own_mock_attempt(p_attempt_id);
end;
$$;

drop function public.account_service_allowed();
drop function public.account_deletion_status();
drop function public.account_deletion_request();
drop function public.account_deletion_cancel();
drop function public.account_reauth_attest(uuid,uuid);
drop function public.account_benefit_candidates(integer);
drop function public.account_benefit_claim(uuid,jsonb);
drop function public.account_deletion_claim(integer);
drop function public.account_deletion_personal(uuid,uuid);
drop function public.account_deletion_advance(uuid,uuid,text);
drop function public.account_deletion_retry(uuid,uuid,text);
drop function public.account_deletion_finish(uuid,uuid);
drop function public.account_deletion_maintenance();
drop function public.account_deletion_provider_result(uuid,uuid,boolean);
drop function public.account_deletion_bind(uuid,jsonb,text,text);
drop function public.account_identity_blocked(jsonb);
drop function public.account_deletion_unbound(integer);
drop function public.account_deletion_notifications(integer);
drop function public.account_deletion_notification_ack(uuid);
drop function public.account_deletion_restore_manifest();
drop function public.account_benefit_record_existing(uuid,jsonb);
drop function public.account_deletion_postconditions(uuid,uuid);
drop function public.account_deletion_health();
drop trigger account_deletion_immutable on public.account_deletion_requests;
drop trigger account_activation_one_way on account_private.dispatch_health;
drop function account_private.activation_guard();
drop function account_private.enabled();
drop function account_private.lock_subject(uuid);
drop function account_private.allowed(uuid);
drop function account_private.guard_request();
drop function account_private.personal_write_gate();
drop function account_private.fenced(uuid,uuid);
drop function account_private.finance_privacy_guard();
drop function account_private.detach_finance(uuid);
drop function account_private.caller_write_gate();
drop table account_private.benefit_delivery;
drop table account_private.benefit_claims;
drop table account_private.reauth_tickets;
drop table account_private.lifecycle_identity_blocks;
drop table account_private.restore_tags;
drop table account_private.dispatch_health;
drop table public.account_deletion_requests;
revoke all on public.credit_accounts,public.credit_grants,public.credit_transactions from account_erasure_executor;
revoke all on schema account_private from account_erasure_executor,essay_executor;
revoke all on schema public from account_erasure_executor,account_lifecycle_worker;
drop schema account_private;
drop role account_erasure_executor;
drop role account_lifecycle_worker;
commit;
