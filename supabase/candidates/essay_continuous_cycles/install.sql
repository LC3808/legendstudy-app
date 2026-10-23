-- CANDIDATE ONLY: no Production application authorized.
begin;
do $$begin
 if exists(select 1 from information_schema.columns where table_schema='essay_exam_private' and table_name='runs' and column_name='previous_paid_run_id') then raise exception 'CYCLES_ALREADY_INSTALLED';end if;
end$$;
alter table essay_exam_private.runs add column previous_paid_run_id uuid references essay_exam_private.runs(id),
 add column submission_index integer check(submission_index>0);
create unique index exam_paid_successor_once on essay_exam_private.runs(previous_paid_run_id)
 where previous_paid_run_id is not null and parent_id is null and state<>'failed';
-- Existing reserve holds account FOR UPDATE. Trigger also takes that lock so a
-- future insertion path cannot bypass serialization. Ledger bodies are unchanged.
create function essay_exam_private.assign_cycle() returns trigger
language plpgsql set search_path='' as $$
declare previous essay_exam_private.runs; parent essay_exam_private.runs; keys jsonb; n integer;
begin
 perform 1 from public.credit_accounts where id=new.account_id for update;
 select jsonb_agg(x->>'questionId' order by x->>'questionId') into keys from jsonb_array_elements(new.snapshot->'answers') x;
 if new.parent_id is not null then
  select * into parent from essay_exam_private.runs where id=new.parent_id and account_id=new.account_id;
  new.previous_paid_run_id=parent.previous_paid_run_id;
 elsif new.snapshot ? '_previousPaidRunId' then
  select * into previous from essay_exam_private.runs where id=(new.snapshot->>'_previousPaidRunId')::uuid and account_id=new.account_id;
  if previous.id is null or previous.parent_id is not null or previous.state<>'completed' or previous.exam_id<>new.exam_id
   or keys is distinct from (select jsonb_agg(x->>'questionId' order by x->>'questionId') from jsonb_array_elements(previous.snapshot->'answers') x)
   or exists(select 1 from essay_exam_private.runs where parent_id=previous.id and state='reserved')
   or exists(select 1 from public.credit_transactions where decision_id=previous.decision_id and transaction_type='refund')
  then raise exception 'INVALID_PAID_CYCLE';end if;
  if exists(select 1 from essay_exam_private.runs where previous_paid_run_id=previous.id and parent_id is null and state<>'failed') then raise exception 'PAID_CYCLE_ALREADY_STARTED';end if;
  new.previous_paid_run_id=previous.id;
 end if;
 -- Legacy rows are untouched. Count actual submissions, including failed requests;
 -- replay uses the same row. This number is independent of paid/free cycle count.
 select greatest(count(*),coalesce(max(submission_index),0))+1 into n from essay_exam_private.runs r
 where r.account_id=new.account_id and r.exam_id=new.exam_id and keys=(select jsonb_agg(x->>'questionId' order by x->>'questionId') from jsonb_array_elements(r.snapshot->'answers') x);
 new.submission_index=n;
 return new;
end$$;
revoke all on function essay_exam_private.assign_cycle() from public,anon,authenticated,service_role,essay_worker;
create trigger exam_cycle_insert before insert on essay_exam_private.runs for each row execute function essay_exam_private.assign_cycle();
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
  -- A free rewrite retains the original approved model/prompt. Current exam
  -- approval and package remain mandatory; never rewrite the parent's snapshot.
  if parent.id is null or parent.exam_id<>p_exam then raise exception 'REEVALUATION_NOT_INCLUDED';end if;
  if parent.snapshot->'runtime'->>'package_digest' is distinct from policy->>'package_digest' then
   raise exception 'FROZEN_QUESTION_SET';end if;
  binding=essay_private.provider_policy(parent.snapshot->'runtime'->>'regime');
  if binding is distinct from parent.snapshot->'runtime'->'binding' or
   not essay_private.provider_binding_valid(parent.snapshot->'runtime'->>'regime',binding) then
   raise sqlstate 'PT422' using message='MODEL_POLICY_NOT_APPROVED';end if;
  policy=jsonb_set(policy,'{regime}',parent.snapshot->'runtime'->'regime');
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

create function public.essay_exam_submit_cycle(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_parent uuid default null,p_previous uuid default null)
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

create or replace function public.essay_exam_history(p_run uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); account uuid; result jsonb;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u;
 select coalesce(jsonb_agg(x.row order by x.created_at desc,x.id desc),'[]'::jsonb) into result from (
 select r.id,r.created_at,jsonb_build_object('id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,
 'university',v.name,'year',e.admission_year,'title',e.exam_name,'state',r.state,
 'created_at',r.created_at,'completed_at',r.completed_at,
 'previous_paid_run_id',r.previous_paid_run_id,'submission_index',r.submission_index,
 'continuous_cycles_supported',true,
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

revoke all on function public.essay_exam_submit_cycle(uuid,uuid,uuid,jsonb,uuid,uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_submit_cycle(uuid,uuid,uuid,jsonb,uuid,uuid) to essay_worker;
create function public.essay_exam_quote(p_subject uuid,p_exam uuid,p_questions uuid[],p_parent uuid default null,p_previous uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare account uuid; r essay_exam_private.runs; keys uuid[];
begin
 perform math_private.require_active(array[p_subject]);
 perform public.essay_exam_preflight(p_subject,p_exam);
 select id into account from public.credit_accounts where user_id=p_subject;
 if account is null then raise exception 'ACCOUNT_UNAVAILABLE';end if;
 select array_agg(q order by q) into keys from unnest(p_questions) q;
 if coalesce(cardinality(keys),0)=0 or cardinality(keys)<>(select count(distinct q) from unnest(keys) q)
 or exists(select 1 from unnest(keys) q where not exists(select 1 from public.essay_questions where id=q and essay_exam_id=p_exam)) then raise exception 'INVALID_QUESTION_SET';end if;
 if p_parent is not null and p_previous is not null then raise exception 'INVALID_PAID_CYCLE';end if;
 if coalesce(p_parent,p_previous) is not null then
  select * into r from essay_exam_private.runs where id=coalesce(p_parent,p_previous) and account_id=account;
  if r.id is null or r.exam_id<>p_exam or r.parent_id is not null or r.state<>'completed'
  or keys is distinct from (select array_agg((x->>'questionId')::uuid order by (x->>'questionId')::uuid) from jsonb_array_elements(r.snapshot->'answers') x)
  or exists(select 1 from public.credit_transactions where decision_id=r.decision_id and transaction_type='refund') then raise exception 'INVALID_CYCLE_SOURCE';end if;
  if p_parent is not null and (clock_timestamp()>r.completed_at+interval '14 days' or exists(select 1 from essay_exam_private.runs where parent_id=r.id and state<>'failed')) then raise exception 'REEVALUATION_NOT_INCLUDED';end if;
  if p_previous is not null and exists(select 1 from essay_exam_private.runs where (previous_paid_run_id=r.id and parent_id is null or parent_id=r.id) and state='reserved' or previous_paid_run_id=r.id and parent_id is null and state='completed') then raise exception 'PAID_CYCLE_ALREADY_STARTED';end if;
 end if;
 return jsonb_build_object('version','essay-exam-quote-v1','credits',case when p_parent is null then 1 else 0 end,
 'kind',case when p_parent is not null then 'included' when p_previous is not null then 'additional' else 'initial' end,'question_ids',to_jsonb(keys));
end$$;
revoke all on function public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_quote(uuid,uuid,uuid[],uuid,uuid) to essay_worker;
commit;
