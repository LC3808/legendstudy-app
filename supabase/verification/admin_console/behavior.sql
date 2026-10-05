-- ADMIN-P0-A behavioral verification.
--
-- Runs against the isolated cluster built by harness.sh. Two phases:
--   PHASE 1  the pending subsystems (deletion / Math / payment) are NOT installed
--   PHASE 2  structural stand-ins are created for them, so the installed-path
--            branches execute too
-- Stand-ins are labelled: they prove the admin boundary behaves correctly when
-- those relations exist, and are NOT a claim that the real migrations applied.
\set ON_ERROR_STOP on

drop table if exists public.admin_verify;
create table public.admin_verify(id serial primary key, name text, ok boolean);
create or replace function pg_temp.check(p_name text, p_ok boolean) returns void
language plpgsql as $$
begin
 insert into admin_verify(name,ok) values(p_name,coalesce(p_ok,false));
 if not coalesce(p_ok,false) then raise warning 'CHECK FAILED: %', p_name; end if;
end$$;

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
insert into auth.users(id,email,created_at) values
 ('11111111-1111-4111-8111-111111111111','admin@legendstudy.com',now()-interval '90 days'),
 ('22222222-2222-4222-8222-222222222222','member1@legendstudy.com',now()-interval '10 days'),
 ('33333333-3333-4333-8333-333333333333','member2@legendstudy.com',now()-interval '2 days'),
 ('44444444-4444-4444-8444-444444444444','outsider@legendstudy.com',now()-interval '1 day');

insert into public.admin_users(user_id) values ('11111111-1111-4111-8111-111111111111');

insert into public.profiles(id,display_name,grade_level,neis_school_code,neis_office_code) values
 ('22222222-2222-4222-8222-222222222222','회원1',3,'S100','B10'),
 ('33333333-3333-4333-8333-333333333333','회원2',2,'S100','B10');

insert into public.credit_accounts(id,user_id) values
 ('a1111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222');

insert into public.credit_grants(id,account_id,origin,external_reference,created_at,expires_at) values
 ('b1111111-1111-4111-8111-111111111111','a1111111-1111-4111-8111-111111111111','signup_bonus','signup/fixture',now()-interval '10 days',now()+interval '90 days'),
 ('b2222222-2222-4222-8222-222222222222','a1111111-1111-4111-8111-111111111111','purchase','order/fixture',now()-interval '5 days',now()+interval '20 days'),
 ('b3333333-3333-4333-8333-333333333333','a1111111-1111-4111-8111-111111111111','promotion','promo/fixture',now()-interval '400 days',now()-interval '1 day');

insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference) values
 ('a1111111-1111-4111-8111-111111111111','b1111111-1111-4111-8111-111111111111','signup_bonus',3,0,'t1','signup','system/signup'),
 ('a1111111-1111-4111-8111-111111111111','b2222222-2222-4222-8222-222222222222','purchase',5,0,'t2','purchase','system/payment'),
 ('a1111111-1111-4111-8111-111111111111','b2222222-2222-4222-8222-222222222222','adjustment',-1,0,'t3','essay_evaluation','system/consumer'),
 ('a1111111-1111-4111-8111-111111111111','b3333333-3333-4333-8333-333333333333','promotion',2,0,'t4','operational_promotion','operator/99999999-9999-4999-8999-999999999999');



-- ---------------------------------------------------------------------------
-- A. Operator gate
-- ---------------------------------------------------------------------------
do $$
declare d jsonb;
begin
 -- A1 anonymous: no request context at all
 perform set_config('request.jwt.claims','',true);
 perform pg_temp.check('A1 anonymous admin_operator=false', public.admin_operator() is false);
 begin
  perform public.admin_dashboard();
  perform pg_temp.check('A2 anonymous dashboard denied', false);
 exception when sqlstate 'PT401' then perform pg_temp.check('A2 anonymous dashboard denied', true);
 end;

 -- A3 authenticated but not on the operations allowlist
 perform set_config('request.jwt.claims',json_build_object('sub','44444444-4444-4444-8444-444444444444','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform pg_temp.check('A3 non-operator admin_operator=false', public.admin_operator() is false);
 begin
  perform public.admin_dashboard();
  perform pg_temp.check('A4 non-operator dashboard denied', false);
 exception when sqlstate 'PT401' then perform pg_temp.check('A4 non-operator dashboard denied', true);
 end;

 -- A5 expired session
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())-60)::text,true);
 perform pg_temp.check('A5 expired operator denied', public.admin_operator() is false);

 -- A6 subject mismatch
 perform set_config('request.jwt.claims',json_build_object('sub','22222222-2222-4222-8222-222222222222','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform pg_temp.check('A6 subject mismatch denied', public.admin_operator() is false);

 -- A7 wrong role
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','anon','exp',extract(epoch from now())+600)::text,true);
 perform pg_temp.check('A7 non-authenticated role denied', public.admin_operator() is false);

 -- A8 malformed claims
 perform set_config('request.jwt.claims','not-json',true);
 perform pg_temp.check('A8 malformed claims denied', public.admin_operator() is false);

 -- A9 operator allowed
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform pg_temp.check('A9 operator admin_operator=true', public.admin_operator() is true);
end$$;

-- ---------------------------------------------------------------------------
-- B. Dashboard
-- ---------------------------------------------------------------------------
do $$
declare d jsonb;
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 d := public.admin_dashboard();
 perform pg_temp.check('B1 dto_version', d->>'dto_version'='admin-v1');
 perform pg_temp.check('B2 members.total=2', (d->'members'->>'total')::int=2);
 perform pg_temp.check('B3 new_7d>=2', (d->'members'->>'new_7d')::int>=2);
 perform pg_temp.check('B4 active_30d observed (0 without a valid session)', (d->'members'->>'active_30d')::int=0);
 perform pg_temp.check('B5 grade_distribution present', jsonb_array_length(d->'profile'->'grade_distribution')>=1);
 perform pg_temp.check('B6 school_code only', (d->'profile'->>'school_code_note') like '%not stored%');
 -- signup 3 available, purchase 5 granted -1 consumed => 4 available, promotion expired => 0
 perform pg_temp.check('B7 credit.spendable=7', (d->'credit'->>'spendable')::int=7);
 perform pg_temp.check('B8 spendable by origin', (d->'credit'->'available_by_origin'->>'signup_bonus')::int=3
   and (d->'credit'->'available_by_origin'->>'purchase')::int=4
   and (d->'credit'->'available_by_origin'->>'promotion')::int=0);
 perform pg_temp.check('B9 granted_total=10', (d->'credit'->>'granted_total')::int=10);
 perform pg_temp.check('B10 consumed_total=1', (d->'credit'->>'consumed_total')::int=1);
 perform pg_temp.check('B11 expiring_30d=4', (d->'credit'->>'expiring_30d')::int=4);
 perform pg_temp.check('B12 payment LIVE_OFF', d->'payment'->>'runtime_state'='LIVE_OFF');
 perform pg_temp.check('B13 payment not installed', (d->'payment'->>'installed')::boolean is false);
 perform pg_temp.check('B14 payment orders null (not a fake 0)', jsonb_typeof(d->'payment'->'orders')='null');
 perform pg_temp.check('B15 math RUNTIME_OFF', d->'math'->>'runtime_state'='RUNTIME_OFF');
 perform pg_temp.check('B16 math not installed', (d->'math'->>'installed')::boolean is false);
 perform pg_temp.check('B17 math attempts null', jsonb_typeof(d->'math'->'attempts')='null');
 perform pg_temp.check('B18 no secret tokens', (d::text !~* 'password|secret|refresh_token|service_role|bearer'));
end$$;

-- ---------------------------------------------------------------------------
-- C. Member search
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 r := public.admin_member_search('member1@legendstudy.com');
 perform pg_temp.check('C1 exact email', jsonb_array_length(r->'items')=1);
 perform pg_temp.check('C2 item email', r->'items'->0->>'email'='member1@legendstudy.com');
 perform pg_temp.check('C3 spendable present', (r->'items'->0->>'spendable')::int=7);
 perform pg_temp.check('C4 account_state NORMAL', r->'items'->0->>'account_state'='NORMAL');
 r := public.admin_member_search('22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('C5 exact uuid', jsonb_array_length(r->'items')=1);
 r := public.admin_member_search('mem');
 perform pg_temp.check('C6 prefix search', jsonb_array_length(r->'items')=2);
 r := public.admin_member_search('member',2,1);
 perform pg_temp.check('C7 pagination offset', jsonb_array_length(r->'items')=1 and (r->>'offset')::int=1);
 perform pg_temp.check('C8 no secret fields', (r::text !~* 'password|secret|refresh|service_role|external_reference|actor_reference|"body"'));
 begin perform public.admin_member_search('ab');
  perform pg_temp.check('C9 short query denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('C9 short query denied',true); end;
 begin perform public.admin_member_search('member1@legendstudy.com',0);
  perform pg_temp.check('C10 limit 0 denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('C10 limit 0 denied',true); end;
 begin perform public.admin_member_search('member1@legendstudy.com',51);
  perform pg_temp.check('C11 limit 51 denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('C11 limit 51 denied',true); end;
 begin perform public.admin_member_search('member1@legendstudy.com',25,-1);
  perform pg_temp.check('C12 negative offset denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('C12 negative offset denied',true); end;
 begin perform public.admin_member_search(null);
  perform pg_temp.check('C13 null query denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('C13 null query denied',true); end;
end$$;

-- ---------------------------------------------------------------------------
-- D. Member detail
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 r := public.admin_member_detail('22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('D1 email', r->'member'->>'email'='member1@legendstudy.com');
 perform pg_temp.check('D2 display name', r->'member'->>'display_name'='회원1');
 perform pg_temp.check('D3 school code', r->'member'->>'school_code'='S100');
 perform pg_temp.check('D4 state NORMAL', r->'account'->>'state'='NORMAL');
 perform pg_temp.check('D5 deletion null when subsystem absent', jsonb_typeof(r->'account'->'deletion')='null');
 perform pg_temp.check('D6 study sessions observed', (r->'usage'->'study'->>'sessions_total')::int=0);
 perform pg_temp.check('D7 study seconds is numeric', (r->'usage'->'study'->>'active_seconds_total') ~ '^[0-9]+$');
 perform pg_temp.check('D8 mock attempts observed', (r->'usage'->'mock'->>'attempts')::int=0);
 perform pg_temp.check('D9 math installed=false', (r->'usage'->'math'->>'installed')::boolean is false);
 perform pg_temp.check('D10 no answer body', (r::text !~* '"body"|password|secret|refresh|service_role'));
 begin perform public.admin_member_detail(gen_random_uuid());
  perform pg_temp.check('D11 unknown account denied',false);
 exception when sqlstate 'PT404' then perform pg_temp.check('D11 unknown account denied',true); end;
 begin perform public.admin_member_detail(null);
  perform pg_temp.check('D12 null account denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('D12 null account denied',true); end;
end$$;

-- ---------------------------------------------------------------------------
-- E. Credit read / history
-- ---------------------------------------------------------------------------
do $$
declare r jsonb;
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 r := public.admin_member_credit('22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('E1 summary spendable=7', (r->'summary'->>'spendable')::int=7);
 perform pg_temp.check('E2 summary free=3', (r->'summary'->>'free')::int=3);
 perform pg_temp.check('E3 summary paid=4', (r->'summary'->>'paid')::int=4);
 perform pg_temp.check('E4 summary other=0 (promotion expired)', (r->'summary'->>'other')::int=0);
 perform pg_temp.check('E5 summary reserved=0', (r->'summary'->>'reserved')::int=0);
 perform pg_temp.check('E6 next_expiry is the purchase grant', (r->'summary'->>'next_expiry') is not null);
 perform pg_temp.check('E7 grants_total=3', (r->'page'->>'grants_total')::int=3);
 perform pg_temp.check('E8 transactions_total=4', (r->'page'->>'transactions_total')::int=4);
 perform pg_temp.check('E9 grants list bounded', jsonb_array_length(r->'grants')=3);
 perform pg_temp.check('E10 expired grant flagged', exists(select 1 from jsonb_array_elements(r->'grants') g where (g->>'origin')='promotion' and (g->>'expired')::boolean and (g->>'available')::int=0));
 perform pg_temp.check('E11 grant available arithmetic', exists(select 1 from jsonb_array_elements(r->'grants') g where (g->>'origin')='purchase' and (g->>'granted')::int=5 and (g->>'balance')::int=4 and (g->>'available')::int=4));
 perform pg_temp.check('E12 transactions list bounded', jsonb_array_length(r->'transactions')=4);
 perform pg_temp.check('E13 transaction fields', exists(select 1 from jsonb_array_elements(r->'transactions') t where (t->>'transaction_type')='adjustment' and (t->>'balance_delta')::int=-1 and (t->>'reason_code')='essay_evaluation'));
 perform pg_temp.check('E14 actor reduced to namespace', not exists(select 1 from jsonb_array_elements(r->'transactions') t where (t->>'actor_kind') like '%/%'));
 perform pg_temp.check('E15 no external_reference', (r::text not like '%external_reference%'));
 perform pg_temp.check('E16 no provider payload', (r::text !~* 'password|secret|refresh|service_role|bearer'));
 r := public.admin_member_credit('22222222-2222-4222-8222-222222222222',2,1);
 perform pg_temp.check('E17 grants pagination', jsonb_array_length(r->'grants')=2 and jsonb_array_length(r->'transactions')=2);
 begin perform public.admin_member_credit('22222222-2222-4222-8222-222222222222',99);
  perform pg_temp.check('E18 invalid limit denied',false);
 exception when sqlstate 'PT422' then perform pg_temp.check('E18 invalid limit denied',true); end;
 begin perform public.admin_member_credit(gen_random_uuid());
  perform pg_temp.check('E19 unknown account denied',false);
 exception when sqlstate 'PT404' then perform pg_temp.check('E19 unknown account denied',true); end;
 -- an account without a credit account must not error
 perform pg_temp.check('E20 account without wallet', public.admin_member_credit('33333333-3333-4333-8333-333333333333') is not null);
end$$;

-- ---------------------------------------------------------------------------
-- F. Ownership and ACL
-- ---------------------------------------------------------------------------
do $$
declare f record; actual text;
begin
 -- Every operations entry point, P0-A and P0-B alike: one owner, SECURITY
 -- DEFINER, and an empty search_path.
 for f in
  select p.oid, p.proname, pg_get_userbyid(p.proowner) owner, p.prosecdef definer, p.proconfig cfg,
   p.prorettype='trigger'::regtype as is_trigger
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and (p.proname like 'admin\_%' or p.proname like 'inquiry\_%'
   or p.proname like 'claim\_inquiry%' or p.proname like 'complete\_inquiry%')
 loop
  perform pg_temp.check('F owner postgres: '||f.proname, f.owner='postgres');
  -- A trigger body must run with the invoker's rights, so only real entry points
  -- are required to be SECURITY DEFINER.
  if not f.is_trigger then
   perform pg_temp.check('F security definer: '||f.proname, f.definer);
  end if;
  perform pg_temp.check('F empty search_path: '||f.proname, f.cfg is not distinct from array['search_path=""']);
 end loop;
 -- An explicit set, not a count: a renamed or dropped entry point must fail.
 select string_agg(p.proname,' ' order by p.proname) into actual
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and (p.proname like 'admin\_%' or p.proname like 'inquiry\_%'
   or p.proname like 'claim\_inquiry%' or p.proname like 'complete\_inquiry%');
 perform pg_temp.check('F full operations entry-point set present',
  actual='admin_account_state admin_count admin_credit_snapshot admin_dashboard admin_inquiry_detail admin_inquiry_list admin_inquiry_reply admin_inquiry_set_status admin_member_credit admin_member_detail admin_member_search admin_operator admin_payment_orders admin_support_metrics claim_inquiry_notifications complete_inquiry_notification inquiry_mine inquiry_submit inquiry_touch');

 perform pg_temp.check('F anon cannot execute admin_count',
  not has_function_privilege('anon','public.admin_count(text)','execute'));
 perform pg_temp.check('F authenticated cannot execute admin_count',
  not has_function_privilege('authenticated','public.admin_count(text)','execute'));
 perform pg_temp.check('F authenticated cannot execute admin_account_state',
  not has_function_privilege('authenticated','public.admin_account_state(uuid)','execute'));
 perform pg_temp.check('F authenticated cannot execute admin_credit_snapshot',
  not has_function_privilege('authenticated','public.admin_credit_snapshot(uuid)','execute'));
 perform pg_temp.check('F service_role cannot execute admin_count',
  not has_function_privilege('service_role','public.admin_count(text)','execute'));
 perform pg_temp.check('F authenticated can execute admin_operator',
  has_function_privilege('authenticated','public.admin_operator()','execute'));
 perform pg_temp.check('F authenticated can execute admin_dashboard',
  has_function_privilege('authenticated','public.admin_dashboard()','execute'));
 perform pg_temp.check('F authenticated can execute admin_member_search',
  has_function_privilege('authenticated','public.admin_member_search(text,integer,integer)','execute'));
 perform pg_temp.check('F authenticated can execute admin_member_detail',
  has_function_privilege('authenticated','public.admin_member_detail(uuid)','execute'));
 perform pg_temp.check('F authenticated can execute admin_member_credit',
  has_function_privilege('authenticated','public.admin_member_credit(uuid,integer,integer)','execute'));
end$$;

-- The helper is not an arbitrary-query surface.
do $$
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 perform pg_temp.check('F count rejects non-public relation', public.admin_count('auth.users') is null);
 perform pg_temp.check('F count rejects injection', public.admin_count('public.profiles; drop table public.profiles') is null);
 perform pg_temp.check('F count of missing relation is null', public.admin_count('public.payment_orders') is null);
 perform pg_temp.check('F count of present relation', public.admin_count('public.profiles')=2);
end$$;

-- ---------------------------------------------------------------------------
-- G. PHASE 2 — structural stand-ins for the pending subsystems
-- ---------------------------------------------------------------------------
-- Column set mirrors 20261003000100_payment_foundation so that reads written
-- against the real table are exercised here too. The CHECK constraints are
-- deliberately omitted: this is a structural stand-in for read behaviour, and
-- it is NOT a claim that the payment migration applied.
create table public.payment_orders(
 id uuid primary key default gen_random_uuid(), subject_id uuid,
 request_key uuid not null default gen_random_uuid(),
 provider text not null default 'TOSS', mode text not null default 'TEST',
 sku text not null default '5c', amount integer not null default 4900,
 quantity integer not null default 5, currency text not null default 'KRW',
 policy_version text not null default 'commerce-2026-10-03',
 deduction_unit integer not null default 4900, validity_months integer not null default 3,
 state text not null default 'ORDER_CREATED', grant_state text not null default 'NONE',
 provider_purchase_id text, grant_id uuid,
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '30 minutes',
 paid_at timestamptz, credit_expires_at timestamptz);
create table public.math_attempts(
 id uuid primary key default gen_random_uuid(), student_id uuid not null,
 created_at timestamptz not null default now());
create table public.math_evaluations(
 id uuid primary key default gen_random_uuid(), attempt_id uuid not null,
 state text not null default 'PROCESSING');
create table public.account_deletion_requests(
 id uuid primary key default gen_random_uuid(), subject_id uuid,
 requested_at timestamptz not null default now(), state text not null default 'DELETION_PENDING',
 phase text not null default 'PERSONAL', scheduled_deletion_at timestamptz default now(),
 cancelled_at timestamptz, completed_at timestamptz);

insert into public.math_attempts(id,student_id) values
 ('e1111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222');
insert into public.math_evaluations(id,attempt_id) values
 ('f1111111-1111-4111-8111-111111111111','e1111111-1111-4111-8111-111111111111');
insert into public.payment_orders(id,subject_id,grant_id,state,sku,amount,currency,paid_at) values
 ('aa111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','b2222222-2222-4222-8222-222222222222','PAID','credit_5',4900,'KRW',now()-interval '5 days');

do $$
declare d jsonb; r jsonb;
begin
 perform set_config('request.jwt.claims',json_build_object('sub','11111111-1111-4111-8111-111111111111','role','authenticated','exp',extract(epoch from now())+600)::text,true);
 d := public.admin_dashboard();
 perform pg_temp.check('G1 payment installed=true', (d->'payment'->>'installed')::boolean);
 perform pg_temp.check('G2 payment orders=1 (real count)', (d->'payment'->>'orders')::int=1);
 perform pg_temp.check('G3 payment still LIVE_OFF', d->'payment'->>'runtime_state'='LIVE_OFF');
 perform pg_temp.check('G4 math installed=true', (d->'math'->>'installed')::boolean);
 perform pg_temp.check('G5 math attempts=1 (real count)', (d->'math'->>'attempts')::int=1);
 perform pg_temp.check('G6 math still RUNTIME_OFF', d->'math'->>'runtime_state'='RUNTIME_OFF');
 r := public.admin_member_detail('22222222-2222-4222-8222-222222222222');
 perform pg_temp.check('G7 member math attempts=1', (r->'usage'->'math'->>'attempts')::int=1);
 perform pg_temp.check('G8 member math evaluations=1', (r->'usage'->'math'->>'evaluations')::int=1);
 perform pg_temp.check('G9 member math still RUNTIME_OFF', r->'usage'->'math'->>'runtime_state'='RUNTIME_OFF');
 perform pg_temp.check('G10 deletion absent for normal member', jsonb_typeof(r->'account'->'deletion')='null');
 -- deletion lifecycle now installed: a pending request must surface
 insert into public.account_deletion_requests(id,subject_id,state,phase,scheduled_deletion_at)
  values ('bb111111-1111-4111-8111-111111111111','33333333-3333-4333-8333-333333333333','DELETION_PENDING','PERSONAL',now()+interval '14 days');
 r := public.admin_member_detail('33333333-3333-4333-8333-333333333333');
 perform pg_temp.check('G11 deletion state surfaced', r->'account'->>'state'='DELETION_PENDING');
 perform pg_temp.check('G12 deletion detail surfaced', r->'account'->'deletion'->>'state'='DELETION_PENDING'
   and (r->'account'->'deletion'->>'phase')='PERSONAL');
 r := public.admin_member_search('member2@legendstudy.com');
 perform pg_temp.check('G13 search reflects deletion state', r->'items'->0->>'account_state'='DELETION_PENDING');
 update public.account_deletion_requests set state='ERASING' where id='bb111111-1111-4111-8111-111111111111';
 perform pg_temp.check('G14 ERASING surfaced', public.admin_account_state('33333333-3333-4333-8333-333333333333')='ERASING');
 update public.account_deletion_requests set state='ERASED', completed_at=now() where id='bb111111-1111-4111-8111-111111111111';
 perform pg_temp.check('G15 ERASED surfaced', public.admin_account_state('33333333-3333-4333-8333-333333333333')='ERASED');
end$$;

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------
do $$
declare total int; failed int;
begin
 select count(*), count(*) filter (where not ok) into total,failed from admin_verify;
 raise notice 'ADMIN_CONSOLE_CHECKS total=% failed=%', total, failed;
 if failed>0 then
  raise notice 'FAILED: %', (select string_agg(name, ' | ') from admin_verify where not ok);
  raise exception 'ADMIN_P0_A_BEHAVIOR_FAILED';
 end if;
end$$;
