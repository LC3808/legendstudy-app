-- =====================================================================
-- RECOVERY: install Math runtime-activation authority + #40-42  — TEST ONLY: kpqbedylxlyntrrfybpn
-- Root cause: #40 gates on math_private.runtime_control, which is created by the SEPARATE
-- canonical Math activation migration 20261004000200_math_storage_erasure_activation.sql
-- (branch codex/math-production-activation-1; production has it). It was not in this branch's
-- 42-file chain, so TEST lacked it and #40 raised MATH_ACTIVATION_AUTHORITY_REQUIRED.
-- This installs that canonical authority (verbatim), then #40,#41,#42. DO NOT run on production.
-- =====================================================================

do $preflight$
begin
  if (select count(*) from supabase_migrations.schema_migrations) <> 39 then
    raise exception 'ABORT: expected exactly 39 migrations (found %)', (select count(*) from supabase_migrations.schema_migrations); end if;
  if not exists (select 1 from supabase_migrations.schema_migrations where version='20261001000300')
     or not exists (select 1 from supabase_migrations.schema_migrations where version='20261002000300') then
    raise exception 'ABORT: prerequisite migrations (#26/#29) missing'; end if;
  if exists (select 1 from supabase_migrations.schema_migrations where version in ('20261004000200','20261008001000','20261009000100','20261009000200')) then
    raise exception 'ABORT: activation or #40-42 already recorded (duplicate prevention)'; end if;
  if to_regclass('math_private.runtime_control') is not null then raise exception 'ABORT: runtime_control already exists'; end if;
  if exists (select 1 from storage.buckets where id='math-private') then raise exception 'ABORT: math-private bucket already exists'; end if;
end
$preflight$;


-- ========== 20261004000200  math_storage_erasure_activation  (predecessor 26_prereq) ==========
do $pre_20261004000200$
begin
  if not exists (select 1 from supabase_migrations.schema_migrations where version='20261001000300') then raise exception 'ABORT: #26 not recorded'; end if;
  if exists (select 1 from supabase_migrations.schema_migrations where version='20261004000200') then raise exception 'ABORT 20261004000200: already applied'; end if;
end
$pre_20261004000200$;
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
insert into supabase_migrations.schema_migrations(version,name,statements) values('20261004000200','math_storage_erasure_activation', array['-- recovery apply of canonical act_20261004000200 sha256=fa5718c586a6affb5ffabbedbccf4f1a6d43c21c7fc91dec1c5e1c4daa654489 (recorded atomically with DDL)']);
commit;


-- ========== 20261008001000  essay_web_runtime_status  (predecessor 20261004000200) ==========
do $pre_20261008001000$
begin
  if not exists (select 1 from supabase_migrations.schema_migrations where version='20261004000200') then raise exception 'ABORT 20261008001000: predecessor 20261004000200 not recorded'; end if;
  if exists (select 1 from supabase_migrations.schema_migrations where version='20261008001000') then raise exception 'ABORT 20261008001000: already applied'; end if;
end
$pre_20261008001000$;
-- Additive read projection only; does not activate providers, change Credit, or open the Math kill switch.
begin;
set local lock_timeout='5s';
set local statement_timeout='15s';
do $$begin
 if current_user<>'postgres' then raise exception 'OWNER_REQUIRED';end if;
 if to_regprocedure('public.essay_web_runtime_status()') is not null then raise exception 'ESSAY_WEB_RUNTIME_COLLISION';end if;
 if to_regclass('math_private.runtime_control') is null or to_regprocedure('math_private.require_active(uuid[])') is null then raise exception 'MATH_ACTIVATION_AUTHORITY_REQUIRED';end if;
end$$;
create function public.essay_web_runtime_status() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 perform math_private.require_active(array[auth.uid()]);
 return jsonb_build_object('version','essay-web-runtime-v1','math_evaluations_enabled',
   coalesce((select evaluations_enabled from math_private.runtime_control where singleton),false));
end$$;
alter function public.essay_web_runtime_status() owner to postgres;
revoke all on function public.essay_web_runtime_status() from public,anon,service_role;
grant execute on function public.essay_web_runtime_status() to authenticated;
comment on function public.essay_web_runtime_status() is 'Authenticated active-account read of existing runtime kill switch; no content, credentials or student records.';
notify pgrst,'reload schema';
insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008001000','essay_web_runtime_status', array['-- recovery apply of canonical 20261008001000_essay_web_runtime_status sha256=cc911a6d7ad90c768b388e52520a7e72c40ebb885b4d862c0e07231b34e49734 (recorded atomically with DDL)']);
commit;


-- ========== 20261009000100  admin_manual_credit_grant  (predecessor 20261008001000) ==========
do $pre_20261009000100$
begin
  if not exists (select 1 from supabase_migrations.schema_migrations where version='20261008001000') then raise exception 'ABORT 20261009000100: predecessor 20261008001000 not recorded'; end if;
  if exists (select 1 from supabase_migrations.schema_migrations where version='20261009000100') then raise exception 'ABORT 20261009000100: already applied'; end if;
end
$pre_20261009000100$;
-- Owner-approved operator grant. Reuses the canonical ledger; no finance JWT,
-- wallet, payment change or direct-table access is introduced.
begin;
create function public.admin_manual_credit_grant(
 p_user uuid, p_email text, p_quantity integer, p_reason text, p_key uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid := auth.uid(); target_email text; reason text := btrim(p_reason);
begin
 if not public.admin_operator() or not account_private.allowed(actor) then
  raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
 end if;
 if p_user is null or p_key is null or p_quantity is null or p_quantity not between 1 and 100
 or reason is null or reason !~ '[^[:space:]]' or char_length(reason) not between 1 and 500
 or p_email is null or char_length(btrim(p_email)) not between 1 and 320 then
  raise sqlstate 'PT422' using message='INVALID_GRANT';
 end if;
 select email into target_email from auth.users where id=p_user;
 if target_email is null or lower(btrim(target_email)) <> lower(btrim(p_email)) then
  raise sqlstate 'PT409' using message='TARGET_CONFIRMATION_CHANGED';
 end if;
 -- Fixed non-purchase type, existing nullable expiry contract. Quantity, reason,
 -- operator, target, timestamp and idempotency all live in the canonical ledger.
 return essay_private.credit_post_grant(p_user,p_quantity,'admin_grant',
  'admin_manual/'||p_key::text,'manual_support: '||reason,'operator/'||actor::text,null);
end $$;
alter function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) owner to postgres;
revoke all on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) from public,anon,service_role;
grant execute on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) to authenticated;
comment on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) is
 'Admin-only 1..100 manual support credit; canonical atomic ledger and idempotency; null expiry.';
insert into supabase_migrations.schema_migrations(version,name,statements) values('20261009000100','admin_manual_credit_grant', array['-- recovery apply of canonical 20261009000100_admin_manual_credit_grant sha256=6f25a4a97ca0c94e92ee9874fec749df8a43d87dd48f1a5ba2ff41db8cd8b388 (recorded atomically with DDL)']);
commit;


-- ========== 20261009000200  iap_verified_credit  (predecessor 20261009000100) ==========
do $pre_20261009000200$
begin
  if not exists (select 1 from supabase_migrations.schema_migrations where version='20261009000100') then raise exception 'ABORT 20261009000200: predecessor 20261009000100 not recorded'; end if;
  if exists (select 1 from supabase_migrations.schema_migrations where version='20261009000200') then raise exception 'ABORT 20261009000200: already applied'; end if;
end
$pre_20261009000200$;
-- Server verified Production Store purchases only. No wallet/table or payment mutation.
begin;
create function public.iap_post_verified_purchase(p_user uuid,p_platform text,p_product text,p_transaction text,p_purchased_at timestamptz)
returns text language plpgsql security definer set search_path='' as $$
declare quantity integer; reference text; account uuid; existing public.credit_grants; expiry timestamptz;
begin
 if auth.role() is distinct from 'service_role' then raise sqlstate 'PT403' using message='VERIFIER_REQUIRED'; end if;
 quantity=case p_product when 'com.legendstudy.essay.credit1' then 1 when 'com.legendstudy.essay.credit3' then 3 when 'com.legendstudy.essay.credit5' then 5 when 'com.legendstudy.essay.credit10' then 10 else null end;
 if p_user is null or quantity is null or p_platform is null or p_platform not in ('apple','google') or p_transaction is null or char_length(p_transaction) not between 1 and 256 or p_transaction !~ '^[A-Za-z0-9._-]+$' or p_purchased_at is null or not isfinite(p_purchased_at) or p_purchased_at>clock_timestamp()+interval '1 minute' then raise sqlstate 'PT422' using message='INVALID_PURCHASE';end if;
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 reference='iap/'||p_platform||'/'||encode(pg_catalog.sha256(pg_catalog.convert_to(p_transaction,'UTF8')),'hex');
 -- Global receipt lock serializes simultaneous claims from different accounts.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(reference,0));
 expiry=(p_purchased_at at time zone 'UTC'+interval '3 months') at time zone 'UTC';
 select id into account from public.credit_accounts where user_id=p_user;
 select * into existing from public.credit_grants where external_reference=reference;
 if found then
  if existing.account_id is distinct from account or existing.origin<>'purchase' or existing.expires_at is distinct from expiry
   or not exists(select 1 from public.credit_transactions where grant_id=existing.id and transaction_type='purchase' and balance_delta=quantity and reason_code='iap_'||p_platform||'_v1') then
   raise sqlstate 'PT409' using message='RECEIPT_CONFLICT';end if;
  return 'already_processed';
 end if;
 if expiry<=clock_timestamp() then raise sqlstate 'PT422' using message='PURCHASE_EXPIRED';end if;
 perform essay_private.credit_post_grant(p_user,quantity,'purchase',reference,'iap_'||p_platform||'_v1','system/iap',expiry);
 return 'granted';
end$$;
alter function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) owner to postgres;
revoke all on function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) from public,anon,authenticated;
grant execute on function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) to service_role;
insert into supabase_migrations.schema_migrations(version,name,statements) values('20261009000200','iap_verified_credit', array['-- recovery apply of canonical 20261009000200_iap_verified_credit sha256=ff03ee2f928d9bad7b37c388657dc03d95dfb9b3e172b4f1973febdd13a9f849 (recorded atomically with DDL)']);
commit;


-- ---- POST-FLIGHT: full set = 42 canonical + 20261004000200 activation = 43 ----
do $postflight$
declare expected text[] := array['20260912000100','20260913000100','20260913000200','20260914000100','20260914000200','20260917000100','20260917000200','20260923000100','20260923000200','20260925000100','20260926000100','20260927000100','20260927000200','20260928000100','20260928000200','20260928000300','20260928000400','20260929000100','20260929000200','20260929000300','20260929000400','20260929000500','20260930000100','20261001000100','20261001000200','20261001000300','20261002000100','20261002000200','20261002000300','20261003000100','20261004000100','20261004000200','20261005000100','20261006000100','20261006000200','20261008000500','20261008000600','20261008000700','20261008000800','20261008000900','20261008001000','20261009000100','20261009000200']; declare got text[];
begin
 select array_agg(version order by version) into got from supabase_migrations.schema_migrations;
  if (select count(*) from supabase_migrations.schema_migrations) <> 43 then raise exception 'POST: expected 43, found %',(select count(*) from supabase_migrations.schema_migrations); end if;
  if exists (select unnest(expected) except select unnest(got)) then raise exception 'POST: missing versions'; end if;
  if exists (select unnest(got) except select unnest(expected)) then raise exception 'POST: unexpected versions'; end if;
end
$postflight$;
select 'OK: Math activation + #40-42 applied; 43 migrations recorded' as result;
