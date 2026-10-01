-- ADR-2 candidate. NOT APPLIED. Activation gates in verification/account_deletion/README.md.
begin;
set local lock_timeout='5s';
do $$begin if exists(select 1 from pg_proc where pronamespace='public'::regnamespace and proname like 'account_%') then raise exception 'account RPC namespace collision';end if;end$$;
create schema account_private;
revoke all on schema account_private from public,anon,authenticated,service_role;
create role account_erasure_executor nologin bypassrls;
create role account_lifecycle_worker nologin nobypassrls;
grant usage on schema public to account_lifecycle_worker;
create table public.account_deletion_requests(
 id uuid primary key default gen_random_uuid(),
 subject_id uuid references auth.users(id) on delete set null,
 requested_at timestamptz not null default clock_timestamp(),
 scheduled_deletion_at timestamptz not null,
 state text not null default 'DELETION_PENDING' check(state in ('DELETION_PENDING','ERASING','ERASED','CANCELLED')),
 cancelled_at timestamptz,completed_at timestamptz,expires_at timestamptz,
 phase text not null default 'PERSONAL' check(phase in ('PERSONAL','STORAGE','PROVIDER','FINANCE','AUTH','VERIFY','DONE')),
 lease_token uuid,lease_until timestamptz,
 retry_count integer not null default 0 check(retry_count>=0),
 next_attempt_at timestamptz not null default clock_timestamp(),
 error_code text check(error_code in ('STORAGE_UNAVAILABLE','PROVIDER_EXTERNAL_GATE','FINANCE_EXTERNAL_GATE','AUTH_UNAVAILABLE','POSTCONDITION_FAILED','TRANSPORT_UNAVAILABLE','RESTORE_CHECKPOINT_UNAVAILABLE')),
 notification_pending boolean not null default true,
 provider_verified boolean not null default false,
 check(scheduled_deletion_at=requested_at+interval '336 hours'),
 check((state='ERASED')=(completed_at is not null)),
 check(state<>'ERASED' or(subject_id is null and phase='DONE' and expires_at=completed_at+interval '720 hours')),
 check((state='CANCELLED')=(cancelled_at is not null)),
 check((lease_token is null)=(lease_until is null))
);
create unique index account_deletion_one_active on public.account_deletion_requests(subject_id) where state in ('DELETION_PENDING','ERASING');
create index account_deletion_due on public.account_deletion_requests(next_attempt_at,scheduled_deletion_at) where state in ('DELETION_PENDING','ERASING');
create index account_deletion_expiry on public.account_deletion_requests(expires_at) where expires_at is not null;
-- Verified inputs are transient server data. Markers never returned to client RPCs.
create table account_private.benefit_claims(
 benefit_type text not null check(benefit_type='essay_signup_3_v1'),
 key_version text not null check(key_version ~ '^[a-zA-Z0-9_-]{1,32}$'),
 marker text not null check(marker ~ '^[a-f0-9]{64}$'),
 claimed_at timestamptz not null default clock_timestamp(),
 primary key(benefit_type,key_version,marker)
);
-- Short-lived while account exists; removed at erasure, not an identity registry.
create table account_private.benefit_delivery(
 subject_id uuid primary key references auth.users(id) on delete cascade,
 grant_id uuid references public.credit_grants(id) on delete restrict
);
create table account_private.reauth_tickets(
 subject_id uuid primary key references auth.users(id) on delete cascade,
 session_id uuid not null,verified_at timestamptz not null,expires_at timestamptz not null,
 check(expires_at<=verified_at+interval '5 minutes')
);
create table account_private.lifecycle_identity_blocks(
 request_id uuid references public.account_deletion_requests(id) on delete cascade,
 key_version text not null,marker text not null check(marker ~ '^[a-f0-9]{64}$'),
 primary key(request_id,key_version,marker)
);
-- No identity is stored in the erased receipt. Restore-only tags have separate purpose.
create table account_private.restore_tags(
 request_id uuid primary key references public.account_deletion_requests(id) on delete cascade,
 key_version text not null,marker text not null check(marker ~ '^[a-f0-9]{64}$')
);
create table account_private.dispatch_health(
 singleton boolean primary key default true check(singleton),last_seen timestamptz not null,enabled boolean not null default false
);
insert into account_private.dispatch_health(singleton,last_seen) values(true,'epoch');
create function account_private.enabled() returns boolean language sql stable security definer set search_path='' as $$select coalesce((select enabled from account_private.dispatch_health where singleton),false)$$;
create function account_private.lock_subject(u uuid) returns void language sql volatile security definer set search_path='' as $$select pg_advisory_xact_lock(hashtextextended(u::text,84612))$$;
create function account_private.allowed(u uuid) returns boolean language sql stable security definer set search_path='' as $$
 select u is not null and exists(select 1 from auth.users where id=u) and not exists(select 1 from public.account_deletion_requests where subject_id=u and state in ('DELETION_PENDING','ERASING'))
$$;
create function public.account_service_allowed() returns boolean language sql stable security definer set search_path='' as $$select account_private.allowed(auth.uid())$$;
create function account_private.guard_request() returns trigger language plpgsql set search_path='' as $$begin
 if new.requested_at<>old.requested_at or new.scheduled_deletion_at<>old.scheduled_deletion_at or new.id<>old.id then raise exception 'immutable deadline' using errcode='23514';end if;
 if old.subject_id is not null and new.subject_id is null and not exists(select 1 from auth.users where id=old.subject_id) and (to_jsonb(old)-'subject_id')=(to_jsonb(new)-'subject_id') then return new;end if;
 if old.state in ('ERASED','CANCELLED') then raise exception 'terminal request' using errcode='23514';end if;
 if old.subject_id is distinct from new.subject_id and not(new.subject_id is null and not exists(select 1 from auth.users where id=old.subject_id)) then raise exception 'invalid subject detach' using errcode='23514';end if;
 return new;
end$$;
create trigger account_deletion_immutable before update on public.account_deletion_requests for each row execute function account_private.guard_request();
create function public.account_deletion_status() returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;begin
 if auth.uid() is null or not exists(select 1 from auth.users where id=auth.uid()) then raise insufficient_privilege;end if;
 select * into r from public.account_deletion_requests where subject_id=auth.uid() order by requested_at desc,id desc limit 1;
 return jsonb_build_object('state',coalesce(r.state,'NORMAL'),'request_id',r.id,'scheduled_deletion_at',r.scheduled_deletion_at,'cancelled_at',r.cancelled_at);
end$$;
create function public.account_deletion_request() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); t timestamptz=clock_timestamp();begin
 if not account_private.enabled() then raise insufficient_privilege using message='LIFECYCLE_NOT_ACTIVE';end if;
 if u is null or not exists(select 1 from auth.users where id=u) then raise insufficient_privilege;end if;
 perform account_private.lock_subject(u);
 if not exists(select 1 from public.account_deletion_requests where subject_id=u and state in ('DELETION_PENDING','ERASING')) then
 insert into public.account_deletion_requests(subject_id,requested_at,scheduled_deletion_at) values(u,t,t+interval '336 hours');end if;
 return public.account_deletion_status();
end$$;
create function public.account_deletion_cancel() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid();r public.account_deletion_requests;sid uuid;begin
 if u is null then raise insufficient_privilege;end if;
 perform account_private.lock_subject(u);
 select * into r from public.account_deletion_requests where subject_id=u and state='DELETION_PENDING' for update;
 if r.id is null or clock_timestamp()>=r.scheduled_deletion_at then raise exception 'cancellation closed' using errcode='22023';end if;
 sid=(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'session_id')::uuid;
 if not exists(select 1 from account_private.reauth_tickets where subject_id=u and session_id=sid and expires_at>clock_timestamp()) then raise insufficient_privilege using message='RECENT_REAUTH_REQUIRED';end if;
 update public.account_deletion_requests set state='CANCELLED',cancelled_at=clock_timestamp(),expires_at=clock_timestamp()+interval '720 hours',notification_pending=false where id=r.id;
 delete from account_private.reauth_tickets where subject_id=u;
 delete from account_private.lifecycle_identity_blocks where request_id=r.id;
 return public.account_deletion_status();
end$$;
-- Only the trusted server reauthentication adapter can attest a fresh challenge.
create function public.account_reauth_attest(p_subject uuid,p_session uuid) returns void language plpgsql security definer set search_path='' as $$begin
 if p_subject is null or p_session is null then raise invalid_parameter_value;end if;
 insert into account_private.reauth_tickets values(p_subject,p_session,clock_timestamp(),clock_timestamp()+interval '5 minutes') on conflict(subject_id) do update set session_id=excluded.session_id,verified_at=excluded.verified_at,expires_at=excluded.expires_at;
end$$;
-- Current Quality RPC bodies/DTOs stay untouched; helper takes lifecycle precedence.
do $$declare body text;begin
 select pg_get_functiondef('public.is_quality_operator()'::regprocedure) into body;
 if strpos(body,'return exists(select 1 from public.quality_operators')=0 then raise exception 'Quality helper drift';end if;
 body=replace(body,' STABLE ',' VOLATILE ');
 execute replace(body,'return exists(select 1 from public.quality_operators','perform account_private.lock_subject(auth.uid()); return account_private.allowed(auth.uid()) and exists(select 1 from public.quality_operators');
end$$;
-- Keep ql-read/HQP DTO functions unchanged. All owner Essay entrypoints use uid().
create or replace function essay_private.uid() returns uuid language plpgsql security definer set search_path='' as $$declare u uuid=auth.uid();begin
 if u is not null and not account_private.allowed(u) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;return u;
end$$;
do $$declare body text;begin
 select pg_get_functiondef('essay_private.owner(uuid)'::regprocedure) into body;
 execute replace(body,'u=essay_private.uid();',E'u=essay_private.uid(); perform account_private.lock_subject(u); if not account_private.allowed(u) then raise insufficient_privilege;end if;');
end$$;
do $$declare body text;begin
 select pg_get_functiondef('essay_private.lock_job(uuid)'::regprocedure) into body;
 execute replace(body,'perform 1 from public.credit_accounts',E'perform account_private.lock_subject((select user_id from public.essay_practice_sessions where id=e.session_id));\n if not account_private.allowed((select user_id from public.essay_practice_sessions where id=e.session_id)) then raise insufficient_privilege using message=\'ACCOUNT_RESTRICTED\';end if;\n perform 1 from public.credit_accounts');
end$$;
grant usage on schema account_private to essay_executor;
grant execute on function account_private.allowed(uuid),account_private.lock_subject(uuid) to essay_executor;
do $$declare body text;begin
 select pg_get_functiondef('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure) into body;
 if strpos(body,'insert into public.credit_accounts(user_id)')=0 then raise exception 'credit helper drift';end if;
 execute replace(body,'insert into public.credit_accounts(user_id)',E'perform account_private.lock_subject(p_user);\n if not account_private.allowed(p_user) then raise insufficient_privilege using message=\'ACCOUNT_RESTRICTED\';end if;\n insert into public.credit_accounts(user_id)');
end$$;
-- Mock definer reads/retries also need an explicit lifecycle gate (RLS is bypassed).
do $$declare body text;begin
 select pg_get_functiondef('public.fetch_own_mock_attempt(uuid)'::regprocedure) into body;
 if strpos(body,'if auth.uid() is null')=0 then raise exception 'mock fetch drift';end if;
 execute replace(body,'if auth.uid() is null','if not account_private.allowed(auth.uid())');
 select pg_get_functiondef('public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb)'::regprocedure) into body;
 if strpos(body,'if owner_id is null')=0 then raise exception 'mock submit drift';end if;
 execute replace(body,'if owner_id is null','perform account_private.lock_subject(owner_id); if not account_private.allowed(owner_id)');
end$$;
-- Restrictive owner RLS supplements (never replaces) current permissive policies.
do $$declare t text;begin
 foreach t in array array['profiles','feedback_submissions','bookmarks','recent_views','day_targets','study_sessions','mock_exam_attempts','mock_exam_answers','student_target_universities','essay_practice_sessions','essay_drafts','essay_attempts','essay_evaluations','essay_evaluation_dimensions','essay_improvement_items','essay_improvement_progress','essay_evaluation_evidence','essay_generated_rewrites','essay_learning_events','essay_ai_processing_runs','credit_accounts','credit_grants','credit_transactions','essay_billing_decisions'] loop
 if to_regclass('public.'||t) is not null then execute format('create policy account_lifecycle_restriction on public.%I as restrictive for all to authenticated using (public.account_service_allowed()) with check (public.account_service_allowed())',t);end if;
 end loop;
end$$;
do $$begin if to_regclass('storage.objects') is not null then execute 'create policy account_lifecycle_restriction on storage.objects as restrictive for all to authenticated using (bucket_id<>''profile-avatars'' or public.account_service_allowed()) with check (bucket_id<>''profile-avatars'' or public.account_service_allowed())';end if;end$$;
-- Prevent stale owner writes, including profile creation; erasure deletes use postgres.
create function account_private.personal_write_gate() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid;rowdata jsonb=to_jsonb(new);begin
 u=case when tg_table_name='profiles' then (rowdata->>'id')::uuid else coalesce(rowdata->>'user_id',rowdata->>'owner_id')::uuid end;
 if u is not null then perform account_private.lock_subject(u);if not account_private.allowed(u) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;end if;
 return new;
end$$;
do $$declare t text;begin
 foreach t in array array['profiles','feedback_submissions','bookmarks','recent_views','day_targets','study_sessions','mock_exam_attempts','student_target_universities','essay_practice_sessions'] loop
 if to_regclass('public.'||t) is not null then execute format('create trigger account_lifecycle_write before insert or update on public.%I for each row execute function account_private.personal_write_gate()',t);end if;
 end loop;
end$$;
-- Decouple profile creation from promotional availability. No secret means no new grant.
create or replace function essay_private.credit_profile_signup() returns trigger language plpgsql security definer set search_path='' as $$begin
 if not account_private.enabled() and essay_private.credit_signup_eligible(new.id) then perform essay_private.credit_post_grant(new.id,3,'signup_bonus','signup_bonus/'||new.id::text,'signup_bonus_v1','system/signup_bonus',null);end if;
 return new;end$$;
create or replace function public.essay_claim_signup_credit() returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid();g uuid;begin
 if u is null then raise insufficient_privilege;end if;
 if not account_private.enabled() then
 if not essay_private.credit_signup_eligible(u) then raise sqlstate 'PT403' using message='SIGNUP_NOT_ELIGIBLE';end if;
 return essay_private.credit_post_grant(u,3,'signup_bonus','signup_bonus/'||u::text,'signup_bonus_v1','system/signup_bonus',null);end if;
 select grant_id into g from account_private.benefit_delivery where subject_id=u;
 return g; -- null = eligibility not established, never a second grant
end$$;
create function public.account_benefit_claim(p_subject uuid,p_markers jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare m jsonb;known boolean=false;g uuid;begin
 perform account_private.lock_subject(p_subject);
 if not account_private.allowed(p_subject) or not exists(select 1 from auth.users where id=p_subject) then raise insufficient_privilege;end if;
 if jsonb_typeof(p_markers) is distinct from 'array' or jsonb_array_length(p_markers) not between 1 and 16 then raise invalid_parameter_value;end if;
 for m in select value from jsonb_array_elements(p_markers) order by value->>'version',value->>'marker' loop
 if m-array['version','marker']<>'{}' or m->>'version' !~ '^[a-zA-Z0-9_-]{1,32}$' or m->>'marker' !~ '^[a-f0-9]{64}$' or not(m ?& array['version','marker']) then raise invalid_parameter_value;end if;
 perform pg_advisory_xact_lock(hashtextextended(m->>'version'||'/'||(m->>'marker'),91571));
 known=known or exists(select 1 from account_private.benefit_claims where benefit_type='essay_signup_3_v1' and key_version=m->>'version' and marker=m->>'marker');
 end loop;
 select grant_id into g from account_private.benefit_delivery where subject_id=p_subject;
 -- Existing live-account grant seeds coverage; never re-grant on migration.
 if g is null then select cg.id into g from public.credit_grants cg join public.credit_accounts ca on ca.id=cg.account_id where ca.user_id=p_subject and cg.origin='signup_bonus';end if;
 if not known and g is null then
 if not essay_private.credit_signup_eligible(p_subject) then return jsonb_build_object('state','NOT_ELIGIBLE');end if;
 g=essay_private.credit_post_grant(p_subject,3,'signup_bonus','signup/'||gen_random_uuid()::text,'signup_bonus_v1','system/signup_bonus',null);
 end if;
 for m in select value from jsonb_array_elements(p_markers) loop
 insert into account_private.benefit_claims(benefit_type,key_version,marker) values('essay_signup_3_v1',m->>'version',m->>'marker') on conflict do nothing;
 end loop;
 insert into account_private.benefit_delivery values(p_subject,g) on conflict(subject_id) do nothing;
 return jsonb_build_object('state',case when g is null then 'PREVIOUSLY_CLAIMED' else 'GRANTED' end);
end$$;
-- Bounded recovery also provisions first-time grants without coupling Auth creation to HMAC availability.
create function public.account_benefit_candidates(p_limit integer default 20) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(p.id),'[]') from
 (select p.id from public.profiles p join auth.users u on u.id=p.id
 where account_private.enabled() and u.email_confirmed_at is not null
 and essay_private.credit_signup_eligible(p.id) and account_private.allowed(p.id)
 and not exists(select 1 from account_private.benefit_delivery d where d.subject_id=p.id)
 order by u.created_at,p.id limit least(100,greatest(1,coalesce(p_limit,20)))) p
$$;
create function public.account_deletion_claim(p_limit integer default 5) returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests; result jsonb='[]';token uuid;begin
 if p_limit is null or p_limit not between 1 and 20 then raise invalid_parameter_value;end if;
 insert into account_private.dispatch_health(singleton,last_seen) values(true,clock_timestamp()) on conflict(singleton) do update set last_seen=excluded.last_seen;
 for r in select * from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING') and scheduled_deletion_at<=clock_timestamp() and next_attempt_at<=clock_timestamp() and (lease_until is null or lease_until<=clock_timestamp()) order by scheduled_deletion_at,id limit p_limit loop
 if r.subject_id is not null and not pg_try_advisory_xact_lock(hashtextextended(r.subject_id::text,84612)) then continue;end if;
 select * into r from public.account_deletion_requests where id=r.id for update skip locked;
 if r.id is null or r.state not in ('DELETION_PENDING','ERASING') or r.lease_until>clock_timestamp() then continue;end if;
 token=gen_random_uuid();
 update public.account_deletion_requests set state='ERASING',lease_token=token,lease_until=clock_timestamp()+interval '2 minutes' where id=r.id;
 result=result||jsonb_build_array(jsonb_build_object('request_id',r.id,'subject_id',r.subject_id,'phase',r.phase,'lease_token',token));
 end loop;return result;
end$$;
create function account_private.fenced(p_id uuid,p_token uuid) returns public.account_deletion_requests language plpgsql set search_path='' as $$
declare r public.account_deletion_requests;begin
 select * into r from public.account_deletion_requests where id=p_id;
 if r.subject_id is not null then perform account_private.lock_subject(r.subject_id);end if;
 select * into r from public.account_deletion_requests where id=p_id for update;
 if r.id is null or r.state<>'ERASING' or r.lease_token is distinct from p_token or r.lease_until<=clock_timestamp() then raise insufficient_privilege using message='STALE_LEASE';end if;
 return r;
end$$;
create function public.account_deletion_personal(p_id uuid,p_token uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;s uuid;e uuid;t text;remaining boolean;begin
 r=account_private.fenced(p_id,p_token);if r.phase<>'PERSONAL' then return true;end if;
 perform 1 from public.credit_accounts where user_id=r.subject_id for update;
 for s in select id from public.essay_practice_sessions where user_id=r.subject_id order by id limit 20 for update loop
 perform 1 from public.credit_grants where account_id in(select id from public.credit_accounts where user_id=r.subject_id) order by id for update;
 for e in select id from public.essay_evaluations where session_id=s order by id for update loop
 if exists(select 1 from public.essay_billing_decisions where evaluation_id=e and status in ('authorized','reserved')) then perform essay_private.release(e);end if;
 end loop;
 delete from public.essay_practice_sessions where id=s;
 end loop;
 if exists(select 1 from public.essay_practice_sessions where user_id=r.subject_id) then return false;end if;
 delete from public.feedback_submissions where id in(select id from public.feedback_submissions where user_id=r.subject_id order by id limit 1000);
 if exists(select 1 from public.feedback_submissions where user_id=r.subject_id) then return false;end if;
 foreach t in array array['student_target_universities','day_targets','study_sessions','mock_exam_attempts','bookmarks','recent_views'] loop
 if to_regclass('public.'||t) is not null then execute format('delete from public.%I where ctid in(select ctid from public.%I where %I=$1 limit 1000)',t,t,case when t='day_targets' then 'owner_id' else 'user_id' end) using r.subject_id;
 execute format('select exists(select 1 from public.%I where %I=$1)',t,case when t='day_targets' then 'owner_id' else 'user_id' end) into remaining using r.subject_id;if remaining then return false;end if;end if;
 end loop;
 update public.account_deletion_requests set phase='STORAGE' where id=r.id;return true;
end$$;
-- Economic terms stay immutable; only server-owned privacy operation detaches keys.
create function account_private.finance_privacy_guard() returns trigger language plpgsql set search_path='' as $$begin
 if current_user='account_erasure_executor' then
 if tg_table_name='credit_grants' and (to_jsonb(new)-'external_reference')=(to_jsonb(old)-'external_reference') and to_jsonb(new)->>'external_reference'='erased/grant/'||old.id::text then return new;end if;
 if tg_table_name='credit_transactions' and (to_jsonb(new)-array['idempotency_key','actor_reference'])=(to_jsonb(old)-array['idempotency_key','actor_reference']) and (to_jsonb(new)->>'idempotency_key'=to_jsonb(old)->>'idempotency_key' or to_jsonb(new)->>'idempotency_key'='erased/transaction/'||old.id::text) and (to_jsonb(new)->>'actor_reference' is not distinct from to_jsonb(old)->>'actor_reference' or to_jsonb(new)->>'actor_reference'='erased') then return new;end if;
 end if;
 raise exception 'immutable finance row' using errcode='23514';
end$$;
drop trigger credit_ledger_no_update on public.credit_transactions;
drop trigger credit_grant_terms_frozen on public.credit_grants;
create trigger credit_ledger_no_update before update on public.credit_transactions for each row execute function account_private.finance_privacy_guard();
create trigger credit_grant_terms_frozen before update on public.credit_grants for each row execute function account_private.finance_privacy_guard();
grant usage on schema public,account_private to account_erasure_executor;
grant select on public.credit_accounts to account_erasure_executor;
grant select,update on public.credit_grants,public.credit_transactions to account_erasure_executor;
create function account_private.detach_finance(u uuid) returns void language plpgsql security definer set search_path='' as $$begin
 -- Opaque finance processor references are intentionally not scrubbed here: activation review required.
 update public.credit_grants set external_reference='erased/grant/'||id::text where origin in ('signup_bonus','admin_grant','promotion','compensation','b2b_program') and external_reference in ('signup_bonus/'||u::text,'manual/'||u::text);
 update public.credit_transactions set idempotency_key='erased/transaction/'||id::text
 where idempotency_key in ('grant/signup_bonus/'||u::text,'grant/manual/'||u::text);
 update public.credit_transactions set actor_reference='erased' where actor_reference='operator/'||u::text;
end$$;
alter function account_private.detach_finance(uuid) owner to account_erasure_executor;
create function public.account_deletion_advance(p_id uuid,p_token uuid,p_phase text) returns void language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;begin
 r=account_private.fenced(p_id,p_token);
 if p_phase is distinct from r.phase or p_phase not in ('STORAGE','PROVIDER','FINANCE','AUTH') then raise invalid_parameter_value;end if;
 if p_phase='FINANCE' then perform account_private.detach_finance(r.subject_id);end if;
 if p_phase='AUTH' and exists(select 1 from auth.users where id=r.subject_id) then raise exception 'auth remains' using errcode='23514';end if;
 update public.account_deletion_requests set phase=case p_phase when 'STORAGE' then 'PROVIDER' when 'PROVIDER' then 'FINANCE' when 'FINANCE' then 'AUTH' when 'AUTH' then 'VERIFY' end where id=r.id;
end$$;
create function public.account_deletion_retry(p_id uuid,p_token uuid,p_error text) returns void language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;begin
 r=account_private.fenced(p_id,p_token);
 update public.account_deletion_requests set retry_count=retry_count+1,next_attempt_at=clock_timestamp()+make_interval(secs=>least(1800,30*(retry_count+1))),error_code=p_error,lease_token=null,lease_until=null,notification_pending=true where id=r.id;
end$$;
create function public.account_deletion_finish(p_id uuid,p_token uuid) returns void language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;t timestamptz=clock_timestamp();begin
 r=account_private.fenced(p_id,p_token);
 if r.phase<>'VERIFY' or r.subject_id is not null then raise exception 'postconditions incomplete' using errcode='23514';end if;
 update public.account_deletion_requests set state='ERASED',phase='DONE',completed_at=t,expires_at=t+interval '720 hours',lease_token=null,lease_until=null,error_code=case when r.provider_verified then null else 'PROVIDER_EXTERNAL_GATE' end,notification_pending=not r.provider_verified where id=r.id;
 delete from account_private.lifecycle_identity_blocks where request_id=r.id;
end$$;
create function public.account_deletion_maintenance() returns jsonb language plpgsql security definer set search_path='' as $$declare n integer;begin
 delete from public.account_deletion_requests where state in ('ERASED','CANCELLED') and expires_at<=clock_timestamp();get diagnostics n=row_count;
 delete from account_private.reauth_tickets where expires_at<=clock_timestamp();
 return jsonb_build_object('purged',n,'overdue', (select count(*) from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING') and scheduled_deletion_at<clock_timestamp()-interval '5 minutes'),'notification_pending',(select count(*) from public.account_deletion_requests where notification_pending),'heartbeat_stale',not exists(select 1 from account_private.dispatch_health where last_seen>clock_timestamp()-interval '10 minutes'));
end$$;
create function public.account_deletion_provider_result(p_id uuid,p_token uuid,p_verified boolean) returns void language plpgsql security definer set search_path='' as $$declare r public.account_deletion_requests;begin
 r=account_private.fenced(p_id,p_token);
 if p_verified is null then raise invalid_parameter_value;end if;
 update public.account_deletion_requests set provider_verified=p_verified,error_code=case when p_verified then null else 'PROVIDER_EXTERNAL_GATE' end where id=r.id;
end$$;
create function public.account_deletion_bind(p_id uuid,p_markers jsonb,p_restore_version text,p_restore_marker text) returns void language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests;m jsonb;begin
 select * into r from public.account_deletion_requests where id=p_id for update;
 if r.id is null or r.state not in ('DELETION_PENDING','ERASING') or r.subject_id is null then raise invalid_parameter_value;end if;
 if jsonb_typeof(p_markers) is distinct from 'array' or jsonb_array_length(p_markers) not between 1 and 16 then raise invalid_parameter_value;end if;
 for m in select value from jsonb_array_elements(p_markers) loop
 if m-array['version','marker']<>'{}' or not(m ?& array['version','marker']) then raise invalid_parameter_value;end if;
 insert into account_private.lifecycle_identity_blocks values(r.id,m->>'version',m->>'marker') on conflict do nothing;
 end loop;
 insert into account_private.restore_tags values(r.id,p_restore_version,p_restore_marker) on conflict(request_id) do nothing;
end$$;
-- Pending obligations must be checkpointed before they become due.
create function public.account_deletion_unbound(p_limit integer default 20) returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('request_id',r.id,'subject_id',r.subject_id,'phase',r.phase,'lease_token',null)),'[]') from
 (select d.* from public.account_deletion_requests d where d.state in ('DELETION_PENDING','ERASING') and d.subject_id is not null and not exists(select 1 from account_private.restore_tags t where t.request_id=d.id) order by d.requested_at,d.id limit least(100,greatest(1,coalesce(p_limit,20)))) r
$$;
create function public.account_identity_blocked(p_markers jsonb) returns boolean language plpgsql security definer set search_path='' as $$begin
 if jsonb_typeof(p_markers) is distinct from 'array' or jsonb_array_length(p_markers) not between 1 and 16 then raise invalid_parameter_value;end if;
 return exists(select 1 from account_private.lifecycle_identity_blocks b join public.account_deletion_requests r on r.id=b.request_id join jsonb_array_elements(p_markers) m on m->>'version'=b.key_version and m->>'marker'=b.marker where r.state in ('DELETION_PENDING','ERASING'));
end$$;
create function public.account_deletion_notifications(p_limit integer default 20) returns jsonb language plpgsql security definer set search_path='' as $$begin
 if p_limit is null or p_limit not between 1 and 100 then raise invalid_parameter_value;end if;
 return coalesce((select jsonb_agg(jsonb_build_object('request_id',r.id,'deadline',r.scheduled_deletion_at,'state',r.state,'error_code',r.error_code)) from (select * from public.account_deletion_requests where notification_pending order by requested_at,id limit p_limit) r),'[]');
end$$;
create function public.account_deletion_notification_ack(p_id uuid) returns void language sql security definer set search_path='' as $$update public.account_deletion_requests set notification_pending=false where id=p_id$$;
create function public.account_deletion_restore_manifest() returns jsonb language sql security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('request_id',r.id,'state',r.state,'deadline',r.scheduled_deletion_at,'expires_at',r.expires_at,'key_version',t.key_version,'restore_tag',t.marker)),'[]') from public.account_deletion_requests r join account_private.restore_tags t on t.request_id=r.id where r.state in ('DELETION_PENDING','ERASING','ERASED')
$$;
create function public.account_benefit_record_existing(p_subject uuid,p_markers jsonb) returns void language plpgsql security definer set search_path='' as $$declare m jsonb;begin
 if not exists(select 1 from public.credit_grants g join public.credit_accounts a on a.id=g.account_id where a.user_id=p_subject and g.origin='signup_bonus') then return;end if;
 if jsonb_typeof(p_markers) is distinct from 'array' or jsonb_array_length(p_markers) not between 1 and 16 then raise invalid_parameter_value;end if;
 for m in select value from jsonb_array_elements(p_markers) order by value->>'version',value->>'marker' loop
 if m-array['version','marker']<>'{}' or not(m ?& array['version','marker']) then raise invalid_parameter_value;end if;
 perform pg_advisory_xact_lock(hashtextextended(m->>'version'||'/'||(m->>'marker'),91571));
 insert into account_private.benefit_claims(benefit_type,key_version,marker) values('essay_signup_3_v1',m->>'version',m->>'marker') on conflict do nothing;
 end loop;
end$$;
create function public.account_deletion_postconditions(p_id uuid,p_token uuid) returns boolean language plpgsql security definer set search_path='' as $$declare r public.account_deletion_requests;begin
 r=account_private.fenced(p_id,p_token);
 return r.subject_id is null and r.phase='VERIFY';
end$$;
create function account_private.caller_write_gate() returns trigger language plpgsql security definer set search_path='' as $$declare u uuid=auth.uid();begin
 if u is not null then perform account_private.lock_subject(u);if not account_private.allowed(u) then raise insufficient_privilege;end if;end if;return null;
end$$;
do $$declare t text;begin
 foreach t in array array['profiles','feedback_submissions','bookmarks','recent_views','day_targets','study_sessions','mock_exam_attempts','student_target_universities','essay_practice_sessions'] loop
 if to_regclass('public.'||t) is not null then execute format('create trigger account_lifecycle_statement before insert or update on public.%I for each statement execute function account_private.caller_write_gate()',t);end if;
 end loop;
end$$;
create function public.account_deletion_health() returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('enabled',account_private.enabled(),'overdue',(select count(*) from public.account_deletion_requests where state in ('DELETION_PENDING','ERASING') and scheduled_deletion_at<statement_timestamp()-interval '5 minutes'),'expired_receipts',(select count(*) from public.account_deletion_requests where state in ('ERASED','CANCELLED') and expires_at<=statement_timestamp()),'expired_leases',(select count(*) from public.account_deletion_requests where state='ERASING' and lease_until<=statement_timestamp()),'heartbeat_stale',not exists(select 1 from account_private.dispatch_health where last_seen>statement_timestamp()-interval '10 minutes'))
$$;
create index account_deletion_lease on public.account_deletion_requests(lease_until) where state='ERASING';
create index account_deletion_subject on public.account_deletion_requests(subject_id,requested_at desc,id);
create index account_lifecycle_identity_lookup on account_private.lifecycle_identity_blocks(key_version,marker);
create function account_private.activation_guard() returns trigger language plpgsql set search_path='' as $$begin
 if old.enabled and not new.enabled then raise exception 'activation cannot revert to legacy signup' using errcode='23514';end if;return new;
end$$;
create trigger account_activation_one_way before update on account_private.dispatch_health for each row execute function account_private.activation_guard();
-- Least privilege; private helpers never gain default EXECUTE.
do $$declare r record;begin
 for r in select schemaname,tablename from pg_tables where schemaname='account_private' or schemaname='public' and tablename='account_deletion_requests' loop
 execute format('alter table %I.%I enable row level security',r.schemaname,r.tablename);
 execute format('revoke all on table %I.%I from public,anon,authenticated,service_role',r.schemaname,r.tablename);
 end loop;
 for r in select p.oid::regprocedure sig,n.nspname,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='account_private' or n.nspname='public' and p.proname like 'account_%' loop
 execute format('revoke all on function %s from public,anon,authenticated,service_role',r.sig);
 if r.nspname='public' then
 if r.proname in ('account_service_allowed','account_deletion_request','account_deletion_status','account_deletion_cancel') then execute format('grant execute on function %s to authenticated',r.sig);
 else execute format('grant execute on function %s to account_lifecycle_worker',r.sig);end if;
 end if;
 end loop;
end$$;
grant execute on function account_private.allowed(uuid),account_private.lock_subject(uuid),account_private.enabled() to essay_executor;
grant select on account_private.benefit_delivery to essay_executor;
commit;
