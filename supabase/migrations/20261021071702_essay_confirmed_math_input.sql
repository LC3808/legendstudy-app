-- Local candidate; no mapping backfill, activation, Storage or Credit changes.
begin;
alter table public.math_subproblems add column essay_question_id uuid references public.essay_questions(id);
create unique index math_leaf_essay_question on public.math_subproblems(essay_question_id) where essay_question_id is not null;
create function math_private.essay_leaf_identity_guard() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='UPDATE' and (new.essay_question_id is distinct from old.essay_question_id or new.problem_id<>old.problem_id)
 and exists(select 1 from public.math_attempts where leaf_id=old.id) then raise exception 'MATH_USED_IDENTITY_IMMUTABLE';end if;
 if new.essay_question_id is not null and not exists(
 select 1 from public.essay_questions q join public.math_problems p on p.id=new.problem_id
 join public.math_problem_sets s on s.id=p.problem_set_id where q.id=new.essay_question_id and q.essay_exam_id=s.essay_exam_id)
 then raise exception 'MATH_ESSAY_EXAM_MISMATCH';end if;
 return new;
end$$;
revoke all on function math_private.essay_leaf_identity_guard() from public,anon,authenticated,service_role;
create trigger essay_leaf_identity before insert or update on public.math_subproblems for each row execute function math_private.essay_leaf_identity_guard();
create function essay_exam_private.confirmed_answers(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb)
returns jsonb language plpgsql set search_path='' as $$
declare q jsonb; out_answers jsonb='[]'; a public.math_attempts; confirmed public.math_extraction_runs;
 prior jsonb; body text; input jsonb; artifacts jsonb; n integer; max_position integer;
begin
 if jsonb_typeof(p_answers) is distinct from 'array' or jsonb_array_length(p_answers) not between 1 and 100 then raise exception 'INVALID_ANSWERS';end if;
 for q in select value from jsonb_array_elements(p_answers) loop
  if jsonb_typeof(q) is distinct from 'object' then raise exception 'INVALID_ANSWERS';end if;
  if not q ? 'mathInput' then
   if q-array['questionId','body','revision']<>'{}'::jsonb then raise exception 'INVALID_ANSWERS';end if;
   out_answers=out_answers||jsonb_build_array(q);continue;
  end if;
  if q-array['questionId','revision','mathInput']<>'{}'::jsonb or jsonb_typeof(q->'mathInput') is distinct from 'object'
   or (q->'mathInput')-array['attemptId','confirmedRunId']<>'{}'::jsonb
   or not (q->'mathInput') ?& array['attemptId','confirmedRunId'] then raise exception 'INVALID_MATH_INPUT';end if;
  -- Exact retries use the immutable journal even if extraction was later retried.
  select x into prior from essay_exam_private.runs r join public.credit_accounts c on c.id=r.account_id,
   lateral jsonb_array_elements(r.snapshot->'answers') x
   where c.user_id=p_subject and r.request_key=p_key and r.exam_id=p_exam and x->>'questionId'=q->>'questionId';
  if prior is not null then
   if prior->'input'->'reference' is distinct from q->'mathInput' then raise exception 'IDEMPOTENCY_CONFLICT';end if;
   out_answers=out_answers||jsonb_build_array(q-'mathInput'||jsonb_build_object('body',prior->>'body','input',prior->'input'));continue;
  end if;
  select * into a from public.math_attempts where id=(q->'mathInput'->>'attemptId')::uuid and student_id=p_subject for update;
  if a.id is null or a.input_kind not in ('EVIDENCE','MIXED') or not exists(select 1 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id
   join public.math_problem_sets s on s.id=p.problem_set_id join public.essay_questions eq on eq.id=l.essay_question_id
   where l.id=a.leaf_id and eq.id=(q->>'questionId')::uuid and eq.essay_exam_id=p_exam and s.essay_exam_id=p_exam)
  then raise exception 'MATH_INPUT_NOT_OWNED_OR_MAPPED';end if;
  select * into confirmed from public.math_extraction_runs where id=(q->'mathInput'->>'confirmedRunId')::uuid
   and attempt_id=a.id and kind='CONFIRMED' and state='COMPLETED' and confirmed_at is not null;
  if confirmed.id is null or confirmed.predecessor_id is distinct from
   (select id from public.math_extraction_runs where attempt_id=a.id and kind='CANDIDATE' order by created_at desc,id desc limit 1)
   or not exists(select 1 from public.math_extraction_runs where id=confirmed.predecessor_id and state='COMPLETED')
  then raise exception 'MATH_CONFIRMATION_REQUIRED';end if;
  select count(*),max(position),jsonb_agg(jsonb_build_object('id',id,'position',position,'sha256',content_sha256) order by position)
   into n,max_position,artifacts from public.math_attempt_artifacts where attempt_id=a.id;
  if n not between 1 and 6 or max_position<>n or exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id and
   (storage_state<>'PRESENT' or media_type not in ('image/png','image/jpeg','image/webp') or content_sha256 is null))
  then raise exception 'MATH_IMAGES_NOT_READY';end if;
  select string_agg(coalesce(nullif(normalized_math,''),raw_text),E'\n' order by reading_order) into body
   from public.math_extraction_regions where run_id=confirmed.id;
  if a.input_kind='MIXED' then body=concat_ws(E'\n',nullif(a.typed_answer,''),body);end if;
  if nullif(btrim(body),'') is null or length(body)>30000 then raise exception 'MATH_CONFIRMED_TEXT_INVALID';end if;
  input=jsonb_build_object('kind','confirmed-math-v1','reference',q->'mathInput','leafId',a.leaf_id,'artifacts',artifacts);
  out_answers=out_answers||jsonb_build_array(q-'mathInput'||jsonb_build_object('body',body,'input',input));
 end loop;
 return out_answers;
end$$;
revoke all on function essay_exam_private.confirmed_answers(uuid,uuid,uuid,jsonb) from public,anon,authenticated,service_role,essay_worker;
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
 p_answers=essay_exam_private.confirmed_answers(p_subject,p_exam,p_key,p_answers);
 for q in select value from jsonb_array_elements(p_answers) loop
  if jsonb_typeof(q) is distinct from 'object' or q-array['questionId','body','revision','input']<>'{}'::jsonb or
    not exists(select 1 from jsonb_array_elements(pkg->'questions') x where x->>'question_id'=q->>'questionId')
  then raise sqlstate 'PT422' using message='QUESTION_NOT_IN_PACKAGE';end if;
 end loop;
 if p_parent is not null then
  select * into parent from essay_exam_private.runs where id=p_parent and account_id=account;
  -- Cross-platform local Draft counters are not revision authority. Pin a
  -- rewrite revision to its immutable stored parent, independently of the client.
  select jsonb_agg(x||jsonb_build_object('revision',coalesce((select (a->>'revision')::bigint + case when (a->>'body' is distinct from x->>'body' or a->'input' is distinct from x->'input') then 1 else 0 end from jsonb_array_elements(parent.snapshot->'answers') a where a->>'questionId'=x->>'questionId'),0)))
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
 p_answers=essay_exam_private.confirmed_answers(p_subject,p_exam,p_key,p_answers);
 for q in select value from jsonb_array_elements(p_answers) loop
  if jsonb_typeof(q) is distinct from 'object' or q-array['questionId','body','revision','input']<>'{}'::jsonb or
    not exists(select 1 from jsonb_array_elements(pkg->'questions') x where x->>'question_id'=q->>'questionId')
  then raise sqlstate 'PT422' using message='QUESTION_NOT_IN_PACKAGE';end if;
 end loop;
 if p_parent is not null then
  select * into parent from essay_exam_private.runs where id=p_parent and account_id=account;
  -- Cross-platform local Draft counters are not revision authority. Pin a
  -- rewrite revision to its immutable stored parent, independently of the client.
  select jsonb_agg(x||jsonb_build_object('revision',coalesce((select (a->>'revision')::bigint + case when (a->>'body' is distinct from x->>'body' or a->'input' is distinct from x->'input') then 1 else 0 end from jsonb_array_elements(parent.snapshot->'answers') a where a->>'questionId'=x->>'questionId'),0)))
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
commit;
