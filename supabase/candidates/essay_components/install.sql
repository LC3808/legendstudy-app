-- LOCAL CANDIDATE ONLY. Not migration-ledger registered; no broad db push.
-- Requires reviewed content, actual catalog binding and privileged ownership transfer.
-- Existing parent request/claim/finalize/credit/lifecycle functions remain untouched.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
do $$begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user) then raise exception 'NON_SUPERUSER_POSTGRES_REQUIRED';end if;
 if has_schema_privilege('essay_executor','public','CREATE') or exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'UNEXPECTED_TOPOLOGY';end if;
 if (select md5(prosrc) from pg_proc where oid='public.essay_finalize_success(uuid,uuid,uuid,jsonb,uuid)'::regprocedure) is distinct from 'df3a2449fa06b6ca9332f568970e8e3c'
 or (select md5(prosrc) from pg_proc where oid='public.essay_claim(uuid,uuid)'::regprocedure) is distinct from '8c54266840d0c0615b2e9f956baf84ca'
 then raise exception 'CANONICAL_FUNCTION_DRIFT';end if;
 if to_regclass('public.essay_evaluation_components') is not null
 or to_regprocedure('public.essay_finalize_components(uuid,uuid,uuid,jsonb,jsonb,jsonb)') is not null
 then raise exception 'COMPONENT_COLLISION';end if;
 if to_regprocedure('public.essay_finalize_success(uuid,uuid,uuid,jsonb,uuid)') is null
 or to_regprocedure('account_private.allowed(uuid)') is null then raise exception 'CANONICAL_AUTHORITY_REQUIRED';end if;
end$$;
create table public.essay_evaluation_components (
 evaluation_id uuid primary key references public.essay_evaluations(id) on delete cascade,
 manifest jsonb not null check(jsonb_typeof(manifest)='object'),
 result jsonb not null check(jsonb_typeof(result)='object'),
 payload_sha256 text not null check(payload_sha256 ~ '^[0-9a-f]{64}$'),
 recorded_at timestamptz not null default clock_timestamp()
);
alter table public.essay_evaluation_components enable row level security;
revoke all on public.essay_evaluation_components from public,anon,authenticated,service_role,essay_worker;
grant select,insert on public.essay_evaluation_components to essay_executor;
-- Executor already BYPASSRLS in canonical runtime; no new role/JWT.
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to essay_executor;
create function public.essay_claim_components(p_evaluation uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; input_hash text;
begin
 result=public.essay_claim(p_evaluation,null);
 select essay_private.hash(e.input_snapshot::text) into input_hash from public.essay_evaluations e where e.id=p_evaluation;
 return result||jsonb_build_object('input_sha256',input_hash);
end$$;
alter function public.essay_claim_components(uuid) owner to essay_executor;
set local role essay_executor;
revoke all on function public.essay_claim_components(uuid) from public,anon,authenticated,service_role,essay_finance;
grant execute on function public.essay_claim_components(uuid) to essay_worker;
reset role;
create function public.essay_finalize_components(p_evaluation uuid,p_run uuid,p_token uuid,
 p_output jsonb,p_manifest jsonb,p_result jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; existing public.essay_evaluation_components;
 h text; item jsonb; section jsonb; i integer; caps text[]; required text[]; result_id uuid;
begin
 e=essay_private.lock_job(p_evaluation);
 if e.contract_version<>'1.3' or e.invalidated_at is not null then raise sqlstate 'PT409' using message='PARENT_UNAVAILABLE';end if;
 if jsonb_typeof(p_manifest) is distinct from 'object' or jsonb_typeof(p_result) is distinct from 'object'
 or octet_length(p_manifest::text)>32768 or octet_length(p_result::text)>524288 then raise sqlstate 'PT422' using message='INVALID_COMPONENTS';end if;
 if p_manifest-array['version','classification_version','exam_type','input_sha256','requirements','components']<>'{}'::jsonb
 or p_manifest->>'version' is distinct from 'essay-components-v1'
 or nullif(btrim(p_manifest->>'classification_version'),'') is null
 or p_manifest->>'input_sha256' is distinct from essay_private.hash(e.input_snapshot::text)
 or p_manifest->>'exam_type' is null or p_manifest->>'exam_type' not in ('business_economics','science')
 or jsonb_typeof(p_manifest->'components') is distinct from 'array'
 or jsonb_typeof(p_manifest->'requirements') is distinct from 'array'
 then raise sqlstate 'PT422' using message='INVALID_MANIFEST';end if;
 if jsonb_array_length(p_manifest->'components') not between 1 and 8
 or jsonb_array_length(p_manifest->'requirements') not between 1 and 2
 then raise sqlstate 'PT422' using message='INVALID_COMPONENT_COUNT';end if;
 if p_result-array['version','evaluationId','attemptId','sections','requiresReview']<>'{}'::jsonb
 or p_result->>'version' is distinct from 'essay-composition-v1'
 or p_result->>'evaluationId' is distinct from e.id::text
 or p_result->>'attemptId' is distinct from e.attempt_id::text
 or jsonb_typeof(p_result->'requiresReview') is distinct from 'boolean'
 or jsonb_typeof(p_result->'sections') is distinct from 'array'
 then raise sqlstate 'PT422' using message='INVALID_RESULT_IDENTITY';end if;
 if jsonb_array_length(p_result->'sections')<>jsonb_array_length(p_manifest->'components') then raise sqlstate 'PT422' using message='MISSING_COMPONENT';end if;
 if (select count(distinct x->>'question_key') from jsonb_array_elements(p_manifest->'components') x)<>jsonb_array_length(p_manifest->'components') then raise sqlstate 'PT422' using message='DUPLICATE_COMPONENT';end if;
 for i in 0..jsonb_array_length(p_manifest->'components')-1 loop
  item=p_manifest->'components'->i;section=p_result->'sections'->i;
  if jsonb_typeof(item) is distinct from 'object' or jsonb_typeof(section) is distinct from 'object'
  or item-array['question_key','title','capability','rubric_version','source_sha256']<>'{}'::jsonb
  or nullif(btrim(item->>'question_key'),'') is null or char_length(item->>'question_key')>120
  or nullif(btrim(item->>'title'),'') is null or char_length(item->>'title')>160
  or nullif(btrim(item->>'rubric_version'),'') is null
  or coalesce(item->>'source_sha256','') !~ '^[0-9a-f]{64}$'
  or item->>'capability' is null
  or (p_manifest->>'exam_type'='business_economics' and item->>'capability' not in ('TEXT_REASONING','QUANTITATIVE'))
  or (p_manifest->>'exam_type'='science' and item->>'capability'<>'SCIENCE_REASONING')
  or section-array['questionKey','title','feedback','requiresReview']<>'{}'::jsonb
  or section->>'questionKey' is distinct from item->>'question_key'
  or section->>'title' is distinct from item->>'title'
  or jsonb_typeof(section->'requiresReview') is distinct from 'boolean'
  or jsonb_typeof(section->'feedback') is distinct from 'object'
  then raise sqlstate 'PT422' using message='INVALID_COMPONENT';end if;
 end loop;
 select array_agg(distinct x->>'capability' order by x->>'capability') into caps from jsonb_array_elements(p_manifest->'components') x;
 select array_agg(x order by x) into required from jsonb_array_elements_text(p_manifest->'requirements') x;
 if caps is distinct from required then raise sqlstate 'PT422' using message='CAPABILITY_COVERAGE';end if;
 if (p_result->>'requiresReview')::boolean is distinct from
 (select bool_or((x->>'requiresReview')::boolean) from jsonb_array_elements(p_result->'sections') x)
 then raise sqlstate 'PT422' using message='REVIEW_MISMATCH';end if;
 h=essay_private.hash(jsonb_build_array(p_output,p_manifest,p_result)::text);
 select * into existing from public.essay_evaluation_components where evaluation_id=e.id;
 if found then
  if existing.payload_sha256<>h then raise sqlstate 'PT409' using message='COMPONENT_REPLAY_CONFLICT';end if;
 else
  -- Never append facts to a legacy completed/charged evaluation retroactively.
  if e.status<>'processing' then raise sqlstate 'PT409' using message='PARENT_NOT_PROCESSING';end if;
 end if;
 -- Sole financial path; canonical output validation, lease fence and consume unchanged.
 result_id=public.essay_finalize_success(p_evaluation,p_run,p_token,p_output,null);
 insert into public.essay_evaluation_components(evaluation_id,manifest,result,payload_sha256)
 values(e.id,p_manifest,p_result,h) on conflict(evaluation_id) do nothing;
 return result_id;
end$$;
alter function public.essay_finalize_components(uuid,uuid,uuid,jsonb,jsonb,jsonb) owner to essay_executor;
set local role essay_executor;
revoke all on function public.essay_finalize_components(uuid,uuid,uuid,jsonb,jsonb,jsonb) from public,anon,authenticated,service_role,essay_finance;
grant execute on function public.essay_finalize_components(uuid,uuid,uuid,jsonb,jsonb,jsonb) to essay_worker;
reset role;

create function public.essay_component_result(p_evaluation uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare e public.essay_evaluations; u uuid; result jsonb;
begin
 select * into e from public.essay_evaluations where id=p_evaluation;
 if e.id is null then raise sqlstate 'PT404' using message='NOT_FOUND';end if;
 u=essay_private.owner(e.session_id);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_UNAVAILABLE';end if;
 if e.status<>'completed' or e.invalidated_at is not null then raise sqlstate 'PT409' using message='RESULT_UNAVAILABLE';end if;
 select c.result into result from public.essay_evaluation_components c where c.evaluation_id=e.id;
 return result; -- NULL means legacy completed evaluation with no component extension.
end$$;
alter function public.essay_component_result(uuid) owner to essay_executor;
set local role essay_executor;
revoke all on function public.essay_component_result(uuid) from public,anon,service_role,essay_worker,essay_finance;
grant execute on function public.essay_component_result(uuid) to authenticated;
reset role;
revoke create on schema public from essay_executor;
revoke essay_executor from postgres granted by postgres;
comment on table public.essay_evaluation_components is 'Immutable component extension of canonical parent evaluation; no separate attempt, billing, wallet or history authority. Deletion follows existing evaluation cascade.';
commit;
