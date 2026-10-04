-- Additive activation boundary. C/D/E and ADR-2D bytes remain unchanged.
-- Apply only after separately approved ADR-2D + MATH-2C/D/E. No gateway enrollment.
begin;
set local lock_timeout='5s';
set local statement_timeout='60s';
do $$begin
 if current_user<>'postgres' or to_regprocedure('public.math_learning(jsonb)') is null
 or to_regprocedure('account_private.fenced(uuid,uuid)') is null
 or to_regclass('storage.objects') is null or to_regclass('storage.buckets') is null then
 raise exception 'MATH_ACTIVATION_PREREQUISITE';end if;
 if exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='postgres'::regrole) then raise exception 'TEMPORARY_ROLE_COLLISION';end if;
 if exists(select 1 from storage.buckets where id='math-private') then raise exception 'MATH_BUCKET_COLLISION';end if;
end$$;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('math-private','math-private',false,20971520,array['image/png','image/jpeg','image/webp','application/pdf']);

-- Storage calls use authenticated owner's JWT, never an arbitrary browser path authority.
create function public.math_storage_owner(p_bucket text,p_name text,p_write boolean) returns boolean
language plpgsql volatile security definer set search_path='' as $$
declare u uuid=auth.uid();a public.math_attempt_artifacts;t public.math_attempts;
begin
 if p_bucket<>'math-private' or u is null then return false;end if;
 perform math_private.require_active(array[u]);
 select ar.* into a from public.math_attempt_artifacts ar join public.math_attempts x on x.id=ar.attempt_id
 where ar.bucket=p_bucket and ar.object_key=p_name and x.student_id=u;
 if a.id is null then return false;end if;
 select * into t from public.math_attempts where id=a.attempt_id for update;
 if p_write then return a.storage_state='REGISTERED'
  and not exists(select 1 from public.math_extraction_runs where attempt_id=t.id)
  and not exists(select 1 from public.math_evaluations where attempt_id=t.id);end if;
 return a.storage_state='PRESENT';
end$$;
revoke all on function public.math_storage_owner(text,text,boolean) from public,anon,service_role;
grant execute on function public.math_storage_owner(text,text,boolean) to authenticated;
create policy math_owner_insert on storage.objects for insert to authenticated
 with check(public.math_storage_owner(bucket_id,name,true));
create policy math_owner_read on storage.objects for select to authenticated
 using(public.math_storage_owner(bucket_id,name,false));
-- No owner UPDATE/upsert/DELETE policy: immutable evidence; erasure uses the fenced worker.
-- Restrictive policies prevent an unrelated permissive policy admitting Math operations.
create policy math_restrict_insert on storage.objects as restrictive for insert to authenticated
 with check(bucket_id<>'math-private' or public.math_storage_owner(bucket_id,name,true));
create policy math_restrict_select on storage.objects as restrictive for select to authenticated
 using(bucket_id<>'math-private' or public.math_storage_owner(bucket_id,name,false));
create policy math_restrict_update on storage.objects as restrictive for update to authenticated
 using(bucket_id<>'math-private') with check(bucket_id<>'math-private');
create policy math_restrict_delete on storage.objects as restrictive for delete to authenticated
 using(bucket_id<>'math-private');

-- Deny anonymous access even in the presence of unrelated broad Storage policies.
create policy math_restrict_anon on storage.objects as restrictive for all to anon
 using(bucket_id<>'math-private') with check(bucket_id<>'math-private');

-- Worker can read only registered Math evidence while its owner is active.
grant usage on schema storage to math_extraction_worker;
grant select on storage.objects to math_extraction_worker;
create function public.math_storage_worker_read(p_bucket text,p_name text) returns boolean
language plpgsql security definer set search_path='' as $$
declare u uuid;begin
 if p_bucket<>'math-private' then return false;end if;
 select a.student_id into u from public.math_attempt_artifacts ar join public.math_attempts a on a.id=ar.attempt_id
 where ar.bucket=p_bucket and ar.object_key=p_name and ar.storage_state in ('REGISTERED','PRESENT');
 if u is null then return false;end if;
 perform math_private.require_active(array[u]);return true;
end$$;
revoke all on function public.math_storage_worker_read(text,text) from public,anon,authenticated,service_role;
grant execute on function public.math_storage_worker_read(text,text) to math_extraction_worker;
create policy math_worker_read on storage.objects for select to math_extraction_worker
 using(public.math_storage_worker_read(bucket_id,name));

-- Existing extraction worker gets only the exact admission capability. Caller must verify
-- downloaded bytes, size, MIME and optional registered digest before calling admit.
create function public.math_artifact_storage(p_subject uuid,p_artifact uuid,p_action text,p_size bigint default null,p_sha256 text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.math_attempt_artifacts;t public.math_attempts;
begin
 perform math_private.require_active(array[p_subject]);
 select ar.* into a from public.math_attempt_artifacts ar join public.math_attempts x on x.id=ar.attempt_id
 where ar.id=p_artifact and x.student_id=p_subject;
 if a.id is null then raise insufficient_privilege;end if;
 select * into t from public.math_attempts where id=a.attempt_id for update;
 select * into a from public.math_attempt_artifacts where id=p_artifact for update;
 if p_action='admit' then
  if a.storage_state not in ('REGISTERED','PRESENT') or p_size is distinct from a.byte_size
   or p_sha256 is null or p_sha256 !~ '^[0-9a-f]{64}$'
   or (a.content_sha256 is not null and p_sha256<>a.content_sha256)
   or not exists(select 1 from storage.objects where bucket_id=a.bucket and name=a.object_key)
  then raise check_violation using message='INVALID_STORAGE_RECEIPT';end if;
  update public.math_attempt_artifacts set storage_state='PRESENT' where id=a.id;
 elsif p_action<>'describe' then raise invalid_parameter_value;end if;
 return jsonb_build_object('artifact_id',a.id,'attempt_id',a.attempt_id,'bucket',a.bucket,'object_key',a.object_key,
 'media_type',a.media_type,'byte_size',a.byte_size,'content_sha256',a.content_sha256,'storage_state',case when p_action='admit' then 'PRESENT' else a.storage_state end);
end$$;
revoke all on function public.math_artifact_storage(uuid,uuid,text,bigint,text) from public,anon,authenticated,service_role;
grant execute on function public.math_artifact_storage(uuid,uuid,text,bigint,text) to math_extraction_worker;

-- Grant a Math-only financial release helper to its postgres-owned erasure wrapper.
-- This delegates the existing reservation release; no Ledger body/economics are changed.
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
set local role essay_executor;
grant execute on function math_private.release_billing(uuid) to postgres;
reset role;
revoke essay_executor from postgres granted by postgres;

create function public.math_account_erasure(p_id uuid,p_token uuid,p_action text) returns boolean
language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;e uuid;
begin
 r=account_private.fenced(p_id,p_token);
 if r.phase<>'STORAGE' or r.subject_id is null then raise insufficient_privilege;end if;
 if p_action='prepare' then
  update public.math_attempt_artifacts set storage_state='ERASURE_PENDING',absence_verified_at=null
  where attempt_id in(select id from public.math_attempts where student_id=r.subject_id);
  return true;
 elsif p_action<>'complete' then raise invalid_parameter_value;end if;
 -- Only call after Storage API recursive listing confirms the entire owned prefix absent.
 -- A remaining Storage catalog row (including orphan metadata) always denies completion.
 if exists(select 1 from storage.objects where bucket_id='math-private' and split_part(name,'/',1)=r.subject_id::text)
 then raise check_violation using message='MATH_BYTES_REMAIN';end if;
 update public.math_attempt_artifacts set storage_state='ABSENT_VERIFIED',absence_verified_at=clock_timestamp()
 where attempt_id in(select id from public.math_attempts where student_id=r.subject_id);
 for e in select ev.id from public.math_evaluations ev join public.math_attempts a on a.id=ev.attempt_id
 where a.student_id=r.subject_id order by ev.id loop
  perform math_private.release_billing(e);
 end loop;
 -- CASCADE preserves canonical E1; reviewer anonymization remains canonical E2.
 delete from public.math_attempts where student_id=r.subject_id;
 return not exists(select 1 from public.math_attempts where student_id=r.subject_id);
end$$;
revoke all on function public.math_account_erasure(uuid,uuid,text) from public,anon,authenticated,service_role;
grant execute on function public.math_account_erasure(uuid,uuid,text) to account_lifecycle_worker;
-- Recovery capability for abandoned work, including while admission is paused.
-- Exact worker role only; no completed result is invalidated and no new debit occurs.
create function public.math_recover_evaluation(p_id uuid) returns boolean
language plpgsql security definer set search_path='' as $$
declare e public.math_evaluations;a public.math_attempts;
begin
 select ar.* into a from public.math_attempts ar join public.math_evaluations ev on ev.attempt_id=ar.id where ev.id=p_id;
 if a.id is null then raise no_data_found;end if;
 perform math_private.require_active(array[a.student_id]);
 perform 1 from public.math_attempts where id=a.id for update;
 select * into e from public.math_evaluations where id=p_id for update;
 if not ((e.state='PROCESSING' and e.lease_until<clock_timestamp()) or
 (e.state='REQUESTED' and e.requested_at<clock_timestamp()-interval '5 minutes')) then return false;end if;
 perform math_private.release_billing(e.id);
 update public.math_evaluations set state='FAILED',error_code='TIMEOUT' where id=e.id;
 return true;
end$$;
revoke all on function public.math_recover_evaluation(uuid) from public,anon,authenticated,service_role;
grant execute on function public.math_recover_evaluation(uuid) to math_evaluation_worker;

-- Server kill switch: blocks new evaluations before any billing reservation, while reads
-- and completion/recovery of already accepted jobs remain available.
create table math_private.runtime_control(singleton boolean primary key default true check(singleton),evaluations_enabled boolean not null default false);
insert into math_private.runtime_control values(true,false);
alter table math_private.runtime_control enable row level security;
revoke all on math_private.runtime_control from public,anon,authenticated,service_role;
create function math_private.evaluation_admission() returns trigger language plpgsql security definer set search_path='' as $$begin
 if not (select evaluations_enabled from math_private.runtime_control where singleton) then
 raise exception 'MATH_EVALUATIONS_PAUSED' using errcode='55000';end if;return new;
end$$;
revoke all on function math_private.evaluation_admission() from public,anon,authenticated,service_role;
create trigger math_runtime_admission before insert on public.math_evaluations for each row execute function math_private.evaluation_admission();
create function public.math_catalog(p_limit integer default 20) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;begin
 perform math_private.require_active(array[auth.uid()]);
 if p_limit not between 1 and 50 then raise invalid_parameter_value;end if;
 select coalesce(jsonb_agg(x),'[]') into result from (
 select l.id as leaf_id,l.statement,p.statement as problem_statement,s.label,l.response_format
 from public.math_subproblems l join public.math_problems p on p.id=l.problem_id join public.math_problem_sets s on s.id=p.problem_set_id
 where p.state='ACTIVE' and s.state='ACTIVE' order by s.id,p.display_order,l.display_order limit p_limit) x;
 return result;
end$$;
revoke all on function public.math_catalog(integer) from public,anon,service_role;
grant execute on function public.math_catalog(integer) to authenticated;
commit;
