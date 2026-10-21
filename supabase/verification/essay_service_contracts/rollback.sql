-- Run only before any mapping or confirmed-input journal has been used.
begin;
do $$begin
 if exists(select 1 from public.math_subproblems where essay_question_id is not null)
 or exists(select 1 from essay_exam_private.runs r,lateral jsonb_array_elements(r.snapshot->'answers') a where a ? 'input')
 then raise exception 'USED_CONTRACT_ROLLBACK_REQUIRES_REVIEW';end if;
end$$;
create or replace function public.essay_exam_submit(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_parent uuid default null)
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
 if p_parent is not null and parent.snapshot ? '_previousPaidRunId' then
  snap=snap||jsonb_build_object('_previousPaidRunId',parent.snapshot->'_previousPaidRunId');
 end if;
 -- reserve owns exact request replay, frozen rewrite set/version, 14 days and 1 Credit.
 return essay_exam_private.reserve(account,p_exam,p_key,snap,p_parent);
end$$;
create or replace function public.essay_exam_submit_cycle(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_parent uuid default null,p_previous uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare account uuid; policy jsonb; pkg jsonb; binding jsonb; snap jsonb; answers jsonb;
 e public.essay_exams; version text; q jsonb; parent essay_exam_private.runs;
begin
 if p_previous is null or p_parent is not null then raise exception 'INVALID_PAID_CYCLE';end if;
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
 if p_parent is not null and parent.snapshot ? '_previousPaidRunId' then
  snap=snap||jsonb_build_object('_previousPaidRunId',parent.snapshot->'_previousPaidRunId');
 end if;
 snap=snap||jsonb_build_object('_previousPaidRunId',p_previous);
 -- reserve owns exact request replay, frozen rewrite set/version, 14 days and 1 Credit.
 return essay_exam_private.reserve(account,p_exam,p_key,snap,p_parent);
end$$;
drop function essay_exam_private.confirmed_answers(uuid,uuid,uuid,jsonb);
drop trigger essay_leaf_identity on public.math_subproblems;
drop function math_private.essay_leaf_identity_guard();
drop index public.math_leaf_essay_question;
alter table public.math_subproblems drop column essay_question_id;
drop function public.essay_browse_catalog(text);
commit;
