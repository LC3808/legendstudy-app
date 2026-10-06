-- ADMIN-P0-A — operator-gated, read-only operations console boundary.
--
-- Additive read-only surface for the LegendStudy release-operations console.
-- It adds no wallet, no analytics store, no role, no table, no column and no
-- service-role fallback. Browser callers reach operations data only through
-- these SECURITY DEFINER functions; existing table grants are untouched and
-- every entry point re-checks the operations allowlist on each call.
--
-- Authorization model:
--   public.admin_users        = service operations administrators (this file)
--   public.quality_operators  = AI Quality / Human Review operators (unchanged)
-- The two scopes are deliberately separate and neither is widened into the
-- other. public.admin_operator() mirrors public.is_quality_operator()'s
-- fail-closed pattern: identity is always auth.uid(), the gateway validates the
-- JWT signature, and a missing/expired/malformed claim set denies.
--
-- Write authority is intentionally absent: no Credit grant, no balance update,
-- no transaction insert, no payment action. Credit granting stays on the
-- canonical public.essay_admin_grant(...) path, which requires a separately
-- provisioned essay_finance capability that is never available to a browser.
--
-- Installable independently of the still-pending subsystem migrations. Relations
-- whose migration is not yet applied are reported as NOT_INSTALLED (JSON null)
-- instead of aborting the whole console or silently reading as a real zero:
--   public.payment_orders                 payment_foundation
--   public.math_attempts/_evaluations     math_essay_persistence
--   public.account_deletion_requests      account_deletion_lifecycle
-- A relation that is installed but empty reports a genuine 0.
--
-- Known activation gate (not a defect of this file): once the payment runtime is
-- installed, the CANCEL_PENDING grant fence must be added to
-- public.admin_credit_snapshot() so the operator figure keeps matching the
-- consumer public.credit_summary(). Today no order can be CANCEL_PENDING
-- (payment LIVE OFF), so both agree. See verification/admin_console/README.md.
--
-- Secrets never leave the database through these functions: no password or
-- password hash, no JWT or refresh token, no provider access token, no raw
-- payment provider payload, no credit external_reference and no raw answer body.
begin;

-- 1. Operations operator gate -------------------------------------------------
create function public.admin_operator() returns boolean
language plpgsql stable security definer set search_path='' as $$
declare claims jsonb; expiry numeric;
begin
 -- Identity is always auth.uid(); API JWT signature validation remains at the gateway.
 -- Require an unexpired verified request context, also denying missing/malformed context.
 claims := nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if auth.uid() is null or claims->>'sub' is distinct from auth.uid()::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' then return false; end if;
 expiry := (claims->>'exp')::numeric;
 if expiry <= extract(epoch from statement_timestamp()) then return false; end if;
 return exists(select 1 from public.admin_users a where a.user_id=auth.uid());
exception when invalid_text_representation or numeric_value_out_of_range then return false;
end$$;

-- 2. Installation probes ------------------------------------------------------
-- Bounded by construction: only `public.<snake_case>` is addressable, so this
-- cannot become an arbitrary-query surface. NULL means "the owning migration is
-- not applied yet", which is distinct from an installed-but-empty 0.
create function public.admin_count(p_relation text) returns bigint
language plpgsql stable security definer set search_path='' as $$
declare n bigint;
begin
 if p_relation is null or p_relation !~ '^public\.[a-z_]+$' or to_regclass(p_relation) is null then return null; end if;
 execute format('select count(*) from %s', p_relation) into n;
 return n;
end$$;

-- 3. Canonical lifecycle state for one subject --------------------------------
-- Uses the tokens public.account_deletion_status() already publishes. When the
-- deletion lifecycle migration is not installed no request can exist, so the
-- only reachable states are NORMAL and ERASED.
create function public.admin_account_state(p_user uuid) returns text
language plpgsql stable security definer set search_path='' as $$
declare st text;
begin
 if p_user is null then return 'UNKNOWN'; end if;
 if not exists(select 1 from auth.users u where u.id=p_user) then return 'ERASED'; end if;
 if to_regclass('public.account_deletion_requests') is not null then
  execute 'select r.state from public.account_deletion_requests r where r.subject_id=$1 order by r.requested_at desc, r.id desc limit 1'
   using p_user into st;
  if st in ('ERASED','ERASING','DELETION_PENDING','CANCELLED') then return st; end if;
 end if;
 return 'NORMAL';
end$$;

-- 4. Credit snapshot for one account ------------------------------------------
-- Same shape and same arithmetic as the consumer public.credit_summary()
-- (credit-v1), so the operator figure and the member's own figure cannot drift:
-- available = greatest(0, balance - reserved), excluding expired grants.
-- Read-only; no balance is written.
create function public.admin_credit_snapshot(p_account_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if p_account_id is null then return null; end if;
 with g as (
  select gr.id,gr.origin,gr.expires_at,
   coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved
  from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id
  where gr.account_id=p_account_id group by gr.id
 ), s as (
  select *,greatest(0,balance-reserved) available from g
  where expires_at is null or expires_at>statement_timestamp()
 )
 select jsonb_build_object(
  'spendable',coalesce(sum(available),0),
  'paid',coalesce(sum(available) filter (where origin='purchase'),0),
  'free',coalesce(sum(available) filter (where origin='signup_bonus'),0),
  'other',coalesce(sum(available) filter (where origin not in ('purchase','signup_bonus')),0),
  'reserved',coalesce((select sum(reserved) from g where expires_at is null or expires_at>statement_timestamp()),0),
  'next_expiry',min(expires_at) filter (where available>0)
 ) into result from s;
 return result;
end$$;

-- 5. Dashboard ----------------------------------------------------------------
-- Only facts that exist today. Payment and Math report their true installation
-- and row state; a zero here is an observed zero, never a substitute revenue or
-- activity KPI.
create function public.admin_dashboard() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'members',jsonb_build_object(
   'total',(select count(*) from public.profiles),
   'new_today',(select count(*) from public.profiles p where p.created_at>=date_trunc('day',statement_timestamp())),
   'new_7d',(select count(*) from public.profiles p where p.created_at>statement_timestamp()-interval '7 days'),
   'new_30d',(select count(*) from public.profiles p where p.created_at>statement_timestamp()-interval '30 days'),
   'active_30d',(select count(distinct s.user_id) from public.study_sessions s where s.started_at>statement_timestamp()-interval '30 days')
  ),
  'profile',jsonb_build_object(
   'grade_distribution',coalesce((select jsonb_agg(jsonb_build_object('key',g.k,'count',g.c) order by g.c desc,g.k) from (
     select coalesce(p.grade_level::text,'UNKNOWN') k,count(*) c from public.profiles p group by 1) g),'[]'::jsonb),
   'school_distribution',coalesce((select jsonb_agg(jsonb_build_object('school_code',s.code,'count',s.c) order by s.c desc,s.code) from (
     select p.neis_school_code code,count(*) c from public.profiles p where p.neis_school_code is not null group by 1 order by c desc,code limit 20) s),'[]'::jsonb),
   'school_code_note','school names are not stored; distribution is by NEIS school code only'
  ),
  'essay',jsonb_build_object(
   'submissions',(select count(*) from public.essay_attempts a where a.submitted_at is not null),
   'evaluation_requests',(select count(*) from public.essay_evaluations),
   'evaluation_completed',(select count(*) from public.essay_evaluations e where e.status='completed'),
   'evaluation_failed',(select count(*) from public.essay_evaluations e where e.status='failed'),
   'rewrites',(select count(*) from public.essay_attempts a where a.attempt_no>1),
   'reevaluations',(select count(*) from public.essay_evaluations e where e.supersedes_evaluation_id is not null)
  ),
  'math',jsonb_build_object(
   'installed',(to_regclass('public.math_attempts') is not null),
   'runtime_state','RUNTIME_OFF',
   'runtime_label','수리논술 평가 기능 비활성 (운영 준비 중)',
   'attempts',public.admin_count('public.math_attempts'),
   'evaluations',public.admin_count('public.math_evaluations')
  ),
  'credit',(
   with g as (
    select gr.id,gr.origin,gr.expires_at,
     coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved
    from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id group by gr.id
   ), s as (
    select *,greatest(0,balance-reserved) available from g
    where expires_at is null or expires_at>statement_timestamp()
   )
   select jsonb_build_object(
    'spendable',coalesce(sum(available),0),
    'available_by_origin',jsonb_build_object(
     'signup_bonus',coalesce(sum(available) filter (where origin='signup_bonus'),0),
     'purchase',coalesce(sum(available) filter (where origin='purchase'),0),
     'promotion',coalesce(sum(available) filter (where origin='promotion'),0),
     'admin_grant',coalesce(sum(available) filter (where origin='admin_grant'),0),
     'compensation',coalesce(sum(available) filter (where origin='compensation'),0),
     'b2b_program',coalesce(sum(available) filter (where origin='b2b_program'),0),
     'other',coalesce(sum(available) filter (where origin not in ('signup_bonus','purchase','promotion','admin_grant','compensation','b2b_program')),0)
    ),
    'expiring_30d',coalesce(sum(available) filter (where expires_at is not null and expires_at<=statement_timestamp()+interval '30 days'),0),
    'granted_total',(select coalesce(sum(t.balance_delta),0) from public.credit_transactions t where t.balance_delta>0),
    'consumed_total',(select coalesce(-sum(t.balance_delta),0) from public.credit_transactions t where t.balance_delta<0)
   ) from s
  ),
  'payment',jsonb_build_object(
   'installed',(to_regclass('public.payment_orders') is not null),
   'runtime_state','LIVE_OFF',
   'runtime_label','결제 기능 미활성 (실결제 아님)',
   'orders',public.admin_count('public.payment_orders')
  )
 ) into result;
 return result;
end$$;

-- 6. Member search ------------------------------------------------------------
-- Bounded by construction: exact account UUID, or exact e-mail, or an e-mail
-- prefix of at least three characters. Never a free-text scan over answer
-- bodies, and never an unbounded page.
create function public.admin_member_search(p_query text,p_limit integer default 25,p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare q text; lim integer; off integer; result jsonb;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 q := btrim(coalesce(p_query,''));
 if char_length(q)<3 or char_length(q)>254 then raise sqlstate 'PT422' using message='INVALID_QUERY'; end if;
 if p_limit is null or p_limit<1 or p_limit>50 then raise sqlstate 'PT422' using message='INVALID_LIMIT'; end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise sqlstate 'PT422' using message='INVALID_OFFSET'; end if;
 lim := p_limit; off := p_offset;
 with m as (
  select u.id account_id,u.email::text email,u.created_at,
   p.display_name,p.grade_level::text grade_level,p.neis_school_code school_code,
   a.id credit_account_id
  from auth.users u
  left join public.profiles p on p.id=u.id
  left join public.credit_accounts a on a.user_id=u.id
  where (q ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' and u.id=q::uuid)
     or lower(u.email)=lower(q)
     or (position('@' in q)=0 and lower(u.email) like lower(q)||'%')
  order by u.created_at desc,u.id
  limit lim offset off
 )
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'query',q,'limit',lim,'offset',off,
  'items',coalesce((select jsonb_agg(jsonb_build_object(
   'account_id',m.account_id,'email',m.email,'created_at',m.created_at,
   'display_name',m.display_name,'grade_level',m.grade_level,'school_code',m.school_code,
   'account_state',public.admin_account_state(m.account_id),
   'spendable',coalesce((public.admin_credit_snapshot(m.credit_account_id))->'spendable',to_jsonb(0))
  ) order by m.created_at desc,m.account_id) from m),'[]'::jsonb)
 ) into result;
 return result;
end$$;

-- 7. Member detail ------------------------------------------------------------
-- Summaries only. Answer bodies, drafts, evaluation text and provider payloads
-- are never returned here. Subsystem-specific metrics are guarded so a console
-- deployed before the payment/Math/deletion migrations still renders truthfully.
create function public.admin_member_detail(p_account_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
 result jsonb; del jsonb; state text;
 study_total bigint; study_30d bigint; study_seconds bigint; study_last timestamptz;
 essay_attempts bigint; essay_submitted bigint; essay_evals bigint; essay_last timestamptz;
 math_attempts bigint; math_evals bigint;
 mock_attempts bigint; mock_last timestamptz;
 bookmark_count bigint; view_count bigint; view_last timestamptz;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p_account_id is null then raise sqlstate 'PT422' using message='INVALID_ACCOUNT'; end if;
 if not exists(select 1 from auth.users u where u.id=p_account_id) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND'; end if;

 state := public.admin_account_state(p_account_id);
 if to_regclass('public.account_deletion_requests') is not null then
  execute $q$select jsonb_build_object('request_id',r.id,'state',r.state,'phase',r.phase,
    'requested_at',r.requested_at,'scheduled_deletion_at',r.scheduled_deletion_at,
    'cancelled_at',r.cancelled_at,'completed_at',r.completed_at)
   from public.account_deletion_requests r where r.subject_id=$1
   order by r.requested_at desc, r.id desc limit 1$q$ using p_account_id into del;
 end if;

 select count(*),count(*) filter (where s.started_at>statement_timestamp()-interval '30 days'),
  coalesce(sum(s.duration_seconds),0),max(s.started_at)
  into study_total,study_30d,study_seconds,study_last
 from public.study_sessions s where s.user_id=p_account_id;

 select count(*),count(*) filter (where a.submitted_at is not null),max(a.submitted_at)
  into essay_attempts,essay_submitted,essay_last
 from public.essay_attempts a join public.essay_practice_sessions ps on ps.id=a.session_id
 where ps.user_id=p_account_id;
 select count(*) into essay_evals from public.essay_evaluations e
 where e.session_id in (select ps.id from public.essay_practice_sessions ps where ps.user_id=p_account_id);

 if to_regclass('public.math_attempts') is not null then
  execute 'select count(*) from public.math_attempts ma where ma.student_id=$1' using p_account_id into math_attempts;
  if to_regclass('public.math_evaluations') is not null then
   execute 'select count(*) from public.math_evaluations me join public.math_attempts ma on ma.id=me.attempt_id where ma.student_id=$1' using p_account_id into math_evals;
  end if;
 end if;

 select count(*),max(mx.submitted_at) into mock_attempts,mock_last
 from public.mock_exam_attempts mx where mx.user_id=p_account_id;
 select count(*) into bookmark_count from public.bookmarks b where b.user_id=p_account_id;
 select count(*),max(v.viewed_at) into view_count,view_last from public.recent_views v where v.user_id=p_account_id;

 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'member',jsonb_build_object(
   'account_id',u.id,'email',u.email::text,'created_at',u.created_at,
   'display_name',p.display_name,'grade_level',p.grade_level::text,
   'school_code',p.neis_school_code,'school_office_code',p.neis_office_code
  ),
  'account',jsonb_build_object('state',state,'deletion',del),
  'usage',jsonb_build_object(
   'study',jsonb_build_object('sessions_total',study_total,'sessions_30d',study_30d,
     'active_seconds_total',study_seconds,'last_started_at',study_last),
   'essay',jsonb_build_object('attempts',essay_attempts,'submitted',essay_submitted,
     'evaluations',essay_evals,'last_submitted_at',essay_last),
   'math',jsonb_build_object('installed',(to_regclass('public.math_attempts') is not null),
     'runtime_state','RUNTIME_OFF','attempts',math_attempts,'evaluations',math_evals),
   'mock',jsonb_build_object('attempts',mock_attempts,'last_submitted_at',mock_last),
   'library',jsonb_build_object('bookmarks',bookmark_count,'recent_views',view_count,
     'last_viewed_at',view_last)
  )
 ) into result from auth.users u left join public.profiles p on p.id=u.id where u.id=p_account_id;
 return result;
end$$;

-- 8. Credit read / history ----------------------------------------------------
-- Summary plus grant-level and transaction-level history. external_reference is
-- deliberately not returned (it can carry a manual or provider reference) and
-- actor_reference is reduced to its namespace, so an operator identity is not
-- spread across the console. No provider payload is reachable from here.
create function public.admin_member_credit(p_account_id uuid,p_limit integer default 25,p_offset integer default 0)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare lim integer; off integer; acct uuid; result jsonb;
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 if p_account_id is null then raise sqlstate 'PT422' using message='INVALID_ACCOUNT'; end if;
 if p_limit is null or p_limit<1 or p_limit>50 then raise sqlstate 'PT422' using message='INVALID_LIMIT'; end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise sqlstate 'PT422' using message='INVALID_OFFSET'; end if;
 lim := p_limit; off := p_offset;
 if not exists(select 1 from auth.users u where u.id=p_account_id) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND'; end if;
 select c.id into acct from public.credit_accounts c where c.user_id=p_account_id;
 select jsonb_build_object(
  'dto_version','admin-v1',
  'as_of',statement_timestamp(),
  'account_id',p_account_id,
  'summary',public.admin_credit_snapshot(acct),
  'page',jsonb_build_object(
   'limit',lim,'offset',off,
   'grants_total',(select count(*) from public.credit_grants gr where gr.account_id=acct),
   'transactions_total',(select count(*) from public.credit_transactions t where t.account_id=acct)
  ),
  'grants',coalesce((
   select jsonb_agg(jsonb_build_object(
    'grant_id',x.id,'origin',x.origin,'created_at',x.created_at,'expires_at',x.expires_at,
    'granted',x.granted,'balance',x.balance,'reserved',x.reserved,'available',x.available,
    'expired',x.expired
   ) order by x.created_at desc,x.id)
   from (
    select gr.id,gr.origin,gr.created_at,gr.expires_at,
     coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved,
     coalesce(sum(t.balance_delta) filter (where t.balance_delta>0),0) granted,
     (gr.expires_at is not null and gr.expires_at<=statement_timestamp()) expired,
     case when gr.expires_at is not null and gr.expires_at<=statement_timestamp() then 0
      else greatest(0,coalesce(sum(t.balance_delta),0)-coalesce(sum(t.reserved_delta),0)) end available
    from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id
    where gr.account_id=acct group by gr.id
    order by gr.created_at desc,gr.id limit lim offset off
   ) x
  ),'[]'::jsonb),
  'transactions',coalesce((
   select jsonb_agg(jsonb_build_object(
    'transaction_id',t.id,'grant_id',t.grant_id,'transaction_type',t.transaction_type,
    'balance_delta',t.balance_delta,'reserved_delta',t.reserved_delta,
    'reason_code',t.reason_code,'actor_kind',nullif(split_part(coalesce(t.actor_reference,''),'/',1),''),
    'reversal_of',t.reversal_of,'created_at',t.created_at
   ) order by t.created_at desc,t.id)
   from (select * from public.credit_transactions t where t.account_id=acct order by t.created_at desc,t.id limit lim offset off) t
  ),'[]'::jsonb)
 ) into result;
 return result;
end$$;

-- 9. Ownership and ACL --------------------------------------------------------
-- Owned by postgres like the rest of the ledger. Client roles may execute only
-- the operator-gated entry points; the internal helpers are revoked from every
-- client role so an authenticated caller cannot read another subject's state or
-- probe installation state directly.
alter function public.admin_operator() owner to postgres;
alter function public.admin_count(text) owner to postgres;
alter function public.admin_account_state(uuid) owner to postgres;
alter function public.admin_credit_snapshot(uuid) owner to postgres;
alter function public.admin_dashboard() owner to postgres;
alter function public.admin_member_search(text,integer,integer) owner to postgres;
alter function public.admin_member_detail(uuid) owner to postgres;
alter function public.admin_member_credit(uuid,integer,integer) owner to postgres;

revoke all on function public.admin_operator() from public,anon,authenticated,service_role;
revoke all on function public.admin_count(text) from public,anon,authenticated,service_role;
revoke all on function public.admin_account_state(uuid) from public,anon,authenticated,service_role;
revoke all on function public.admin_credit_snapshot(uuid) from public,anon,authenticated,service_role;
revoke all on function public.admin_dashboard() from public,anon,authenticated,service_role;
revoke all on function public.admin_member_search(text,integer,integer) from public,anon,authenticated,service_role;
revoke all on function public.admin_member_detail(uuid) from public,anon,authenticated,service_role;
revoke all on function public.admin_member_credit(uuid,integer,integer) from public,anon,authenticated,service_role;

grant execute on function public.admin_operator(),
 public.admin_dashboard(),
 public.admin_member_search(text,integer,integer),
 public.admin_member_detail(uuid),
 public.admin_member_credit(uuid,integer,integer)
 to authenticated;
commit;
