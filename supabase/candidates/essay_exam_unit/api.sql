-- LOCAL integration candidate. Requires install.sql and Provider005.
-- No production apply/activation authorization. Deployment-owned runtime policy
-- remains empty until exact exam/package/model/rights are separately approved.
begin;
create function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb
language sql stable set search_path='' as $$select null::jsonb$$;
revoke all on function essay_exam_private.runtime_policy(uuid) from public,anon,authenticated,service_role,essay_worker;
alter table essay_exam_private.runs add column dispatch_key uuid,
 add column lease_token uuid, add column lease_until timestamptz;
create or replace function essay_exam_private.guard() returns trigger language plpgsql set search_path='' as $$
begin
 if old.state<>'reserved' or new.state not in ('reserved','completed','failed') or
 (to_jsonb(old)-array['state','result','completed_at','dispatch_key','lease_token','lease_until']) is distinct from
 (to_jsonb(new)-array['state','result','completed_at','dispatch_key','lease_token','lease_until']) or
 (old.dispatch_key is not null and (old.dispatch_key,old.lease_token,old.lease_until) is distinct from
 (new.dispatch_key,new.lease_token,new.lease_until)) then raise exception 'EXAM_RUN_IMMUTABLE';end if;
 return new;
end$$;

create function public.essay_exam_preflight(p_subject uuid,p_exam uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare policy jsonb; binding jsonb; pkg jsonb;
begin
 perform math_private.require_active(array[p_subject]);
 policy=essay_exam_private.runtime_policy(p_exam);
 if policy is null or coalesce(policy->>'evaluation_type','') not in ('humanities','business') then raise sqlstate 'PT403' using message='EXAM_NOT_ACTIVATED';end if;
 binding=essay_private.provider_policy(policy->>'regime');
 if not essay_private.provider_binding_valid(policy->>'regime',binding) then raise sqlstate 'PT422' using message='MODEL_POLICY_NOT_APPROVED';end if;
 pkg=public.essay_material_runtime_package(p_exam,policy->>'package_digest');
 return policy||jsonb_build_object('binding',binding);
end$$;
revoke all on function public.essay_exam_preflight(uuid,uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_preflight(uuid,uuid) to essay_worker;

-- Caller is the private gateway, after online Auth + existing allowlist verification.
-- Client supplies answers/key only, never a model, criterion version or credit cost.
create function public.essay_exam_submit(p_subject uuid,p_exam uuid,p_key uuid,p_answers jsonb,p_parent uuid default null)
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
 -- reserve owns exact request replay, frozen rewrite set/version, 14 days and 1 Credit.
 return essay_exam_private.reserve(account,p_exam,p_key,snap,p_parent);
end$$;

create function public.essay_exam_claim(p_subject uuid,p_run uuid,p_dispatch uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; account uuid;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_dispatch is null then raise sqlstate 'PT403';end if;
 if r.state<>'reserved' then return jsonb_build_object('state',r.state,'run_id',r.id);end if;
 if r.dispatch_key is null then
  update essay_exam_private.runs set dispatch_key=p_dispatch,lease_token=gen_random_uuid(),lease_until=clock_timestamp()+interval '15 minutes'
  where id=r.id returning * into r;
 elsif r.dispatch_key<>p_dispatch then
  raise sqlstate 'PT409' using message='RECONCILIATION_REQUIRED';
 end if;
 return jsonb_build_object('state','reserved','dispatch_allowed',r.lease_until>clock_timestamp(),'run_id',r.id,'subject_id',p_subject,'exam_id',r.exam_id,
 'snapshot',r.snapshot,'parent_id',r.parent_id,'parent_result',(select p.result from essay_exam_private.runs p where p.id=r.parent_id and p.account_id=r.account_id),'lease_token',r.lease_token,'lease_until',r.lease_until);
end$$;

create function public.essay_exam_finish(p_subject uuid,p_run uuid,p_token uuid,p_result jsonb,p_failed boolean default false)
returns text language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; account uuid;
begin
 perform math_private.require_active(array[p_subject]);
 select id into account from public.credit_accounts where user_id=p_subject for update;
 select * into r from essay_exam_private.runs where id=p_run and account_id=account for update;
 if r.id is null or p_token is null or r.lease_token is distinct from p_token then raise sqlstate 'PT403';end if;
 -- Lease is immutable and can never be reassigned. A reviewed checkpoint may
 -- settle after dispatch expiry using its exact original token, without redispatch.
 return essay_exam_private.finish(p_run,p_result,p_failed);
end$$;

-- Both platforms read this owner-scoped projection of existing exam runs.
-- No lease, internal reviewer receipts, model input or private source PDF is exposed.
create function public.essay_exam_history(p_run uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); account uuid; result jsonb;
begin
 perform math_private.require_active(array[u]);
 select id into account from public.credit_accounts where user_id=u;
 select coalesce(jsonb_agg(x.row order by x.created_at desc,x.id desc),'[]'::jsonb) into result from (
 select r.id,r.created_at,jsonb_build_object('id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,
 'university',v.name,'year',e.admission_year,'title',e.exam_name,'state',r.state,
 'created_at',r.created_at,'completed_at',r.completed_at,
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

-- No student write/claim/finance grant. The verified gateway forwards caller identity.
revoke all on function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid),
 public.essay_exam_claim(uuid,uuid,uuid),public.essay_exam_finish(uuid,uuid,uuid,jsonb,boolean),
 public.essay_exam_history(uuid) from public,anon,authenticated,service_role,essay_worker;
grant execute on function public.essay_exam_submit(uuid,uuid,uuid,jsonb,uuid),
 public.essay_exam_claim(uuid,uuid,uuid),public.essay_exam_finish(uuid,uuid,uuid,jsonb,boolean) to essay_worker;
grant execute on function public.essay_exam_history(uuid) to authenticated;
-- Follow the existing credit-account anonymization lifecycle; retain Ledger facts.
create function essay_exam_private.erase_account_runs() returns trigger
language plpgsql security definer set search_path='' as $$
declare r record;
begin
 if old.user_id is not null and new.user_id is null then
  for r in select id from essay_exam_private.runs where account_id=old.id and state='reserved' order by id for update loop
   perform essay_exam_private.finish(r.id,null,true);
  end loop;
  delete from essay_exam_private.runs where account_id=old.id;
 end if;
 return new;
end$$;
revoke all on function essay_exam_private.erase_account_runs() from public,anon,authenticated,service_role,essay_worker;
create trigger essay_exam_account_erasure before update of user_id on public.credit_accounts
 for each row execute function essay_exam_private.erase_account_runs();
commit;
