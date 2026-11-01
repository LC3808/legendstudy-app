-- OWNER APPROVAL REQUIRED. Fill the reviewed values in this block; blank values abort.
-- Run only AFTER install/verify and the new APP/WEB + published notice are ready.
begin;
do $activate$
declare
 owner_id uuid := null; -- approved existing administrator UUID; never create a user here
 notice uuid := null; -- existing public beta notice, APP + WEB enabled
 approval text := ''; -- Owner approval record URL/reference
 starts date := null; -- explicit approved KST start date
 scope jsonb := '[]'; -- [{"exam_id":"UUID","runtime_policy":{...},"question_ids":["UUID"],"has_math":false}]
 campaign uuid; item jsonb; questions uuid[];
begin
 if owner_id is null or notice is null or starts is null or length(btrim(approval))=0 or jsonb_array_length(scope)=0 then
  raise exception 'OWNER_REVIEWED_CONFIGURATION_REQUIRED';
 end if;
 if starts>date '2026-11-10' or starts<(clock_timestamp() at time zone 'Asia/Seoul')::date then raise exception 'INVALID_START_DATE';end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_id,'role','authenticated','exp',extract(epoch from statement_timestamp()+interval '5 minutes')::bigint)::text,true);
 if public.admin_operator() is not true or account_private.allowed(owner_id) is not true then raise exception 'ACTIVE_ADMIN_REQUIRED';end if;
 if not exists(select 1 from notice_private.notices n where n.notice_id=notice and n.category='beta' and n.status='published' and n.is_public and n.show_app and n.show_web and n.published_at<=clock_timestamp() and (n.expires_at is null or n.expires_at>=timestamptz '2026-11-11 00:00:00+09')) then raise exception 'PUBLISHED_BETA_NOTICE_REQUIRED';end if;
 if exists(select 1 from essay_beta_private.campaigns) then raise exception 'CAMPAIGN_ALREADY_EXISTS_REVIEW_INSTEAD_OF_REAPPLY';end if;
 insert into essay_beta_private.campaigns(starts_on,ends_on,created_by,notice_id)
 values(starts,date '2026-11-10',owner_id,notice) returning id into campaign;
 for item in select value from jsonb_array_elements(scope) loop
  if item->>'has_math' is distinct from 'false' or item->'runtime_policy'->>'evaluation_type' is distinct from 'humanities'
   or item->'runtime_policy' is distinct from essay_exam_private.runtime_policy((item->>'exam_id')::uuid) then raise exception 'SCOPE_POLICY_MISMATCH';end if;
  select array_agg(value::uuid order by value::uuid) into questions from jsonb_array_elements_text(item->'question_ids');
  if coalesce(cardinality(questions),0)=0 or cardinality(questions)<>(select count(distinct q) from unnest(questions) q)
   or exists(select 1 from unnest(questions) q where not exists(select 1 from public.essay_questions where id=q and essay_exam_id=(item->>'exam_id')::uuid)) then raise exception 'INVALID_QUESTION_SET';end if;
  insert into essay_beta_private.exam_scope(campaign_id,exam_id,runtime_policy,question_ids,has_math,approval_reference)
  values(campaign,(item->>'exam_id')::uuid,item->'runtime_policy',questions,false,approval);
 end loop;
 update essay_beta_private.campaigns set enabled=true where id=campaign;
end $activate$;
commit;
-- Does not issue a grant or create/evaluate a run. Updated clients claim in initial submission, never on onboarding start.
