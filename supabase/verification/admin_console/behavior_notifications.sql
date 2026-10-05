-- ADMIN-P0-B ADDENDUM — shared user notification center behavioural verification.
--
-- Runs last, after behavior.sql and behavior_p0b.sql, against the same isolated
-- cluster, so the P0-A/P0-B fixtures already exist and the fixture-driven ledger
-- postings have already exercised the grant producer.
--
-- Covers:
--   A. model, ACL and duration of the owner boundary
--   B. reader RPCs (list / count / mark one / mark all)
--   C. producers (inquiry reply, Credit grant) including idempotency
--   D. low Credit is a crossing, not a state; expiry thresholds and dedupe
\set ON_ERROR_STOP on
create or replace function pg_temp.check(p_name text, p_ok boolean) returns void
language plpgsql as $$
begin
 insert into admin_verify(name,ok) values(p_name,coalesce(p_ok,false));
 if not coalesce(p_ok,false) then raise warning 'CHECK FAILED: %', p_name; end if;
end$$;
create or replace function pg_temp.as_member(p uuid) returns void language plpgsql as $$
begin perform set_config('request.jwt.claims',
 json_build_object('sub',p::text,'role','authenticated','exp',extract(epoch from now())+600)::text,true);
end$$;
create or replace function pg_temp.as_anon() returns void language plpgsql as $$
begin perform set_config('request.jwt.claims','',true); end$$;
create or replace function pg_temp.err(p_sql text) returns text language plpgsql as $$
begin execute p_sql; return 'NONE'; exception when others then return sqlstate; end$$;

-- Extra members for the daily producers, kept separate from the P0-A fixtures so
-- the balance thresholds are not perturbed.
insert into auth.users(id,email,created_at) values
 ('55555555-5555-4555-8555-555555555555','expiry@legendstudy.com',now()-interval '30 days'),
 ('66666666-6666-4666-8666-666666666666','lowbalance@legendstudy.com',now()-interval '30 days'),
 ('77777777-7777-4777-8777-777777777777','zero@legendstudy.com',now()-interval '30 days')
on conflict (id) do nothing;
insert into public.profiles(id,display_name,grade_level,neis_school_code,neis_office_code) values
 ('55555555-5555-4555-8555-555555555555','만료회원',3,'S100','B10'),
 ('66666666-6666-4666-8666-666666666666','잔액회원',3,'S100','B10'),
 ('77777777-7777-4777-8777-777777777777','영회원',3,'S100','B10')
on conflict (id) do nothing;

-- ===========================================================================
-- A. Model and access boundary
-- ===========================================================================
select pg_temp.check('N-A1 authenticated cannot read the notification table directly',
  not has_table_privilege('authenticated','public.user_notifications','select'));
select pg_temp.check('N-A2 authenticated cannot insert notifications',
  not has_table_privilege('authenticated','public.user_notifications','insert'));
select pg_temp.check('N-A3 authenticated cannot update notifications',
  not has_table_privilege('authenticated','public.user_notifications','update'));
select pg_temp.check('N-A4 anon cannot read the notification table',
  not has_table_privilege('anon','public.user_notifications','select'));
select pg_temp.check('N-A5 service_role cannot insert notifications',
  not has_table_privilege('service_role','public.user_notifications','insert'));
select pg_temp.check('N-A6 row level security is enabled with no permissive policy',
  (select relrowsecurity from pg_class where oid='public.user_notifications'::regclass)
  and not exists(select 1 from pg_policies where tablename='user_notifications'));
select pg_temp.check('N-A7 the emitter is not callable by any client role',
  not has_function_privilege('authenticated','notification_private.emit(uuid,text,text,text,text,uuid,text,timestamptz)','execute')
  and not has_function_privilege('service_role','notification_private.emit(uuid,text,text,text,text,uuid,text,timestamptz)','execute'));
select pg_temp.check('N-A8 the notification schema is not reachable by clients',
  not has_schema_privilege('authenticated','notification_private','usage')
  and not has_schema_privilege('service_role','notification_private','usage'));
select pg_temp.check('N-A9 duplicate dedupe key per member is rejected',
  exists(select 1 from pg_constraint where conname='user_notifications_dedupe' and contype='u'));
select pg_temp.check('N-A10 an arbitrary notification type is rejected', pg_temp.err(
  $q$select notification_private.emit('22222222-2222-4222-8222-222222222222','totally_made_up','t','b',null,null,'x/1')$q$)
  <> 'NONE');
select pg_temp.check('N-A11 the daily producer is not callable by a browser session',
  not has_function_privilege('authenticated','public.user_notification_run_daily_producers(integer)','execute'));
select pg_temp.check('N-A12 the payment producer is not callable by a browser session',
  not has_function_privilege('authenticated','public.user_notification_payment_complete(uuid)','execute'));
select pg_temp.check('N-A13 the math producer is not callable by a browser session',
  not has_function_privilege('authenticated','public.user_notification_math_evaluation_complete(uuid,uuid)','execute'));

-- The P0-A ledger fixtures posted a purchase and a promotion before this suite
-- ran, so the grant producer has already fired without any client involvement.
select pg_temp.check('N-A14 canonical ledger postings produced notifications',
  (select count(*) from public.user_notifications where user_id='22222222-2222-4222-8222-222222222222') >= 2);

-- Deterministic counting from here on.
delete from public.user_notifications;

-- ===========================================================================
-- B. Reader RPCs and the owner boundary
-- ===========================================================================
insert into public.user_notifications(user_id,type,title,body,target_type,target_id,dedupe_key,created_at,read_at) values
 ('22222222-2222-4222-8222-222222222222','service_notice','첫 번째 안내','본문 1',null,null,'seed/1',now()-interval '3 hours',null),
 ('22222222-2222-4222-8222-222222222222','service_notice','두 번째 안내','본문 2',null,null,'seed/2',now()-interval '2 hours',null),
 ('22222222-2222-4222-8222-222222222222','service_notice','세 번째 안내','본문 3',null,null,'seed/3',now()-interval '1 hour',now()-interval '30 minutes'),
 ('33333333-3333-4333-8333-333333333333','service_notice','남의 안내','본문',null,null,'seed/other',now(),null);

do $$
begin
perform pg_temp.as_member('22222222-2222-4222-8222-222222222222');
perform pg_temp.check('N-B1 list returns only the caller own rows',
  (public.user_notifications_list(50,0,false)->>'items')::jsonb @> '[]'::jsonb
  and jsonb_array_length(public.user_notifications_list(50,0,false)->'items') = 3
  and (public.user_notifications_list(50,0,false)::text not like '%남의 안내%'));
perform pg_temp.check('N-B2 list is newest first',
  (public.user_notifications_list(50,0,false)->'items'->0->>'title') = '세 번째 안내'
  and (public.user_notifications_list(50,0,false)->'items'->2->>'title') = '첫 번째 안내');
perform pg_temp.check('N-B3 list carries the read flag',
  (public.user_notifications_list(50,0,false)->'items'->0->>'is_read')::boolean is true
  and (public.user_notifications_list(50,0,false)->'items'->1->>'is_read')::boolean is false);
perform pg_temp.check('N-B4 unread count counts only unread own rows',
  public.user_notifications_unread_count() = 2);
perform pg_temp.check('N-B5 unread_only filter hides read rows',
  jsonb_array_length(public.user_notifications_list(50,0,true)->'items') = 2);
perform pg_temp.check('N-B6 paging is bounded',
  (public.user_notifications_list(5000,0,false)->>'limit')::integer = 50);

declare touched boolean; begin
  touched := public.user_notification_mark_read((select id from public.user_notifications where dedupe_key='seed/other'));
  perform pg_temp.check('N-B7 marking a foreign notification is refused', touched = false);
  perform pg_temp.check('N-B7b the foreign notification is untouched',
    (select read_at from public.user_notifications where dedupe_key='seed/other') is null);
  touched := public.user_notification_mark_read((select id from public.user_notifications where dedupe_key='seed/1'));
  perform pg_temp.check('N-B8 marking an own notification succeeds once', touched = true);
  perform pg_temp.check('N-B8b the own notification is now read',
    (select read_at from public.user_notifications where dedupe_key='seed/1') is not null);
  perform pg_temp.check('N-B8c the unread count dropped by one',
    public.user_notifications_unread_count() = 1);
  declare cleared integer; begin
    cleared := public.user_notifications_mark_all_read();
    perform pg_temp.check('N-B9 marking all read affects only the caller', cleared = 1);
    perform pg_temp.check('N-B9b the caller has nothing unread',
      public.user_notifications_unread_count() = 0);
    perform pg_temp.check('N-B9c the foreign notification is still unread',
      (select read_at from public.user_notifications where dedupe_key='seed/other') is null);
    perform pg_temp.check('N-B10 marking all read twice is idempotent',
      public.user_notifications_mark_all_read() = 0);
  end;
end;

perform pg_temp.as_anon();
perform pg_temp.check('N-B11 unauthenticated list is refused',
  pg_temp.err($q$select public.user_notifications_list(20,0,false)$q$) = 'PT401');
perform pg_temp.check('N-B12 unauthenticated count is refused',
  pg_temp.err($q$select public.user_notifications_unread_count()$q$) = 'PT401');
perform pg_temp.check('N-B13 unauthenticated mark read is refused',
  pg_temp.err($q$select public.user_notification_mark_read(gen_random_uuid())$q$) = 'PT401');
perform pg_temp.check('N-B14 unauthenticated mark all read is refused',
  pg_temp.err($q$select public.user_notifications_mark_all_read()$q$) = 'PT401');
end$$;

-- ===========================================================================
-- C. Producers
-- ===========================================================================
delete from public.user_notifications;

-- C.1 inquiry reply, driven through the real operator RPC so the reply row, the
-- email enqueue and the in-app notification are all produced by the product path.
insert into public.inquiries(id,user_id,category,title,body,status,request_key,created_at,updated_at)
values ('c1111111-1111-4111-8111-111111111111','22222222-2222-4222-8222-222222222222','payment',
        '환불 문의드립니다','환불 가능 여부를 확인하고 싶습니다.','RECEIVED',
        'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',now()-interval '2 hours',now()-interval '2 hours')
on conflict (id) do nothing;

do $$
declare r jsonb;
begin
  perform pg_temp.as_member('11111111-1111-4111-8111-111111111111');
  r := public.admin_inquiry_reply(jsonb_build_object(
        'dto_version','admin-v1',
        'id','c1111111-1111-4111-8111-111111111111',
        'body','확인했습니다. 환불 가능 여부를 안내드립니다.',
        'request_key','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1'));
  perform pg_temp.check('N-C1 an operator reply produces exactly one notification',
    (select count(*) from public.user_notifications
      where user_id='22222222-2222-4222-8222-222222222222' and type='inquiry_reply') = 1);
  perform pg_temp.check('N-C2 the reply notification targets the inquiry',
    (select target_type='inquiry' and target_id='c1111111-1111-4111-8111-111111111111'
       from public.user_notifications where type='inquiry_reply' limit 1));
  perform pg_temp.check('N-C3 the reply notification is unread and summary only',
    (select read_at is null and body = '문의하신 내용에 답변이 등록되었습니다.'
       from public.user_notifications where type='inquiry_reply' limit 1));
  perform pg_temp.check('N-C3b the reply enqueued an email delivery',
    exists(select 1 from public.inquiry_notifications
            where inquiry_id='c1111111-1111-4111-8111-111111111111'));

  -- Same request key again: the operator RPC returns the existing reply without
  -- inserting, so nothing new is produced.
  r := public.admin_inquiry_reply(jsonb_build_object(
        'dto_version','admin-v1',
        'id','c1111111-1111-4111-8111-111111111111',
        'body','확인했습니다. 환불 가능 여부를 안내드립니다.',
        'request_key','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1'));
  perform pg_temp.check('N-C4 a retried operator reply does not duplicate the notification',
    (select count(*) from public.user_notifications where type='inquiry_reply') = 1);
  perform pg_temp.check('N-C4b the retry did not insert a second reply',
    (select count(*) from public.inquiry_replies
      where inquiry_id='c1111111-1111-4111-8111-111111111111') = 1);
end$$;

-- C.2 email independence: the reply enqueued mail; failing that mail must not
-- remove or acknowledge the in-app notification.
update public.inquiry_notifications set status='failed', last_error_code='provider_rejected'
 where inquiry_id='c1111111-1111-4111-8111-111111111111';
select pg_temp.check('N-C5 the email delivery is recorded as failed',
  exists(select 1 from public.inquiry_notifications
          where inquiry_id='c1111111-1111-4111-8111-111111111111' and status='failed'));
select pg_temp.check('N-C5b a failed email delivery leaves the notification intact',
  (select count(*) from public.user_notifications where type='inquiry_reply') = 1);
select pg_temp.check('N-C5c a failed email delivery does not mark the notification read',
  (select read_at is null from public.user_notifications where type='inquiry_reply' limit 1));

-- C.3 Credit grant: canonical posting only.
delete from public.user_notifications;
insert into public.credit_accounts(user_id) values ('55555555-5555-4555-8555-555555555555')
on conflict(user_id) do nothing;
insert into public.credit_grants(id,account_id,origin,external_reference,expires_at,created_at)
values ('e1111111-1111-4111-8111-111111111111',
        (select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'purchase','nf/order-1',null,now())
on conflict (id) do nothing;
insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
values ((select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'e1111111-1111-4111-8111-111111111111','purchase',5,0,'nf-grant/order-1','purchase','system/payment',now());
select pg_temp.check('N-C6 a canonical grant produces exactly one credit_grant notification',
  (select count(*) from public.user_notifications
    where user_id='55555555-5555-4555-8555-555555555555' and type='credit_grant') = 1);
select pg_temp.check('N-C7 the grant notification states the quantity',
  (select title = '5 Credits가 지급되었습니다' and target_type = 'credit_history'
     from public.user_notifications where type='credit_grant' limit 1));

-- A ledger movement that is not a grant must not notify.
insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
values ((select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'e1111111-1111-4111-8111-111111111111','adjustment',5,0,'nf-adj-pos/order-1','manual_correction','operator/system',now()),
       ((select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'e1111111-1111-4111-8111-111111111111','adjustment',-1,0,'nf-adj-neg/order-1','essay_evaluation','system/consumer',now()),
       ((select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'e1111111-1111-4111-8111-111111111111','expiration',-1,0,'nf-expire/order-1','credit_expiry','system/scheduler',now());
select pg_temp.check('N-C8 a positive adjustment, a negative adjustment and an expiry do not notify',
  (select count(*) from public.user_notifications where type='credit_grant') = 1);

-- A signup bonus is the free Credit the member already sees at signup.
insert into public.credit_grants(id,account_id,origin,external_reference,expires_at,created_at)
values ('e2222222-2222-4222-8222-222222222222',
        (select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'signup_bonus','nf/signup',null,now())
on conflict (id) do nothing;
insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
values ((select id from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555'),
        'e2222222-2222-4222-8222-222222222222','signup_bonus',3,0,'nf-grant/signup','signup','system/signup',now());
select pg_temp.check('N-C9 a signup bonus does not notify',
  (select count(*) from public.user_notifications where type='credit_grant') = 1);

-- The operator grant path produces the same single notification.
do $$ begin
  perform pg_temp.as_member('11111111-1111-4111-8111-111111111111');
  begin
    perform public.essay_admin_grant('66666666-6666-4666-8666-666666666666', 4, 'admin_grant',
      'a9999999-9999-4999-8999-999999999999', 'test_account', null);
  exception when others then null; end;
end $$;
select pg_temp.check('N-C10 an operator grant notifies through the same producer',
  (select count(*) from public.user_notifications
    where user_id='66666666-6666-4666-8666-666666666666' and type='credit_grant') = 1);

-- ===========================================================================
-- D. Low Credit is a crossing, and the daily producer is expiry only
-- ===========================================================================
delete from public.user_notifications;
-- Also drop the grant the operator producer check posted, so the fixtures below
-- see only what their own comments describe.
delete from public.credit_transactions where grant_id in (
  select id from public.credit_grants
   where id in ('e1111111-1111-4111-8111-111111111111','e2222222-2222-4222-8222-222222222222')
      or external_reference = 'manual/a9999999-9999-4999-8999-999999999999');
delete from public.credit_grants
 where id in ('e1111111-1111-4111-8111-111111111111','e2222222-2222-4222-8222-222222222222')
    or external_reference = 'manual/a9999999-9999-4999-8999-999999999999';

-- Expiry member: five dated grants, one of them outside every threshold.
insert into public.credit_accounts(user_id) values ('55555555-5555-4555-8555-555555555555')
on conflict(user_id) do nothing;
do $$
declare acct uuid; today date := (essay_private.clock() at time zone 'Asia/Seoul')::date;
        offsets integer[] := array[30,14,7,3,20,7];
        quantities integer[] := array[3,2,1,4,5,2];
        i integer;
begin
  select id into acct from public.credit_accounts where user_id='55555555-5555-4555-8555-555555555555';
  for i in 1..array_length(offsets,1) loop
    insert into public.credit_grants(account_id,origin,external_reference,expires_at,created_at)
    values (acct,'purchase','nf/exp-'||offsets[i]||'-'||i,
            ((today + offsets[i])::timestamp + time '12:00') at time zone 'Asia/Seoul', now());
    insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
    select acct, g.id, 'purchase', quantities[i], 0, 'nf-exp-tx/'||offsets[i]||'-'||i, 'purchase', 'system/payment', now()
      from public.credit_grants g where g.external_reference='nf/exp-'||offsets[i]||'-'||i;
  end loop;
end $$;

-- Zero balance member: granted then fully consumed. Granted 3 is not a crossing
-- (nothing was above the threshold) and consuming 3 arrives at zero from a
-- balance that was already low, so this member is never told anything.
insert into public.credit_accounts(user_id) values ('77777777-7777-4777-8777-777777777777')
on conflict(user_id) do nothing;
insert into public.credit_grants(account_id,origin,external_reference,expires_at,created_at)
select id,'promotion','nf/zero',null,now() from public.credit_accounts where user_id='77777777-7777-4777-8777-777777777777'
on conflict do nothing;
insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
select a.id, g.id, 'promotion', 3, 0, 'nf-zero-tx', 'operational_promotion', 'operator/system', now()
  from public.credit_accounts a join public.credit_grants g on g.account_id=a.id and g.external_reference='nf/zero'
 where a.user_id='77777777-7777-4777-8777-777777777777';
insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
select a.id, g.id, 'adjustment', -3, 0, 'nf-zero-consume', 'essay_evaluation', 'system/consumer', now()
  from public.credit_accounts a join public.credit_grants g on g.account_id=a.id and g.external_reference='nf/zero'
 where a.user_id='77777777-7777-4777-8777-777777777777';

-- Crossing member: the balance walks 5 -> 4 -> 3 -> 2 -> 1 -> 0, recovers to 6,
-- and walks down again.
delete from public.user_notifications;

create function pg_temp.spend(n integer, key text) returns void language plpgsql as $f$
begin
  insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
  select a.id, gr.id, 'adjustment', -n, 0, key, 'essay_evaluation', 'system/consumer', now()
    from public.credit_accounts a
    join public.credit_grants gr on gr.account_id=a.id and gr.external_reference='nf/cross'
   where a.user_id='66666666-6666-4666-8666-666666666666';
end; $f$;

create function pg_temp.low_count() returns integer language sql as $f$
  select count(*)::integer from public.user_notifications
   where user_id='66666666-6666-4666-8666-666666666666'
     and type='low_credit_notification'; $f$;

do $$
declare acct uuid; g uuid;
begin
  insert into public.credit_accounts(user_id) values ('66666666-6666-4666-8666-666666666666')
  on conflict(user_id) do nothing;
  select id into acct from public.credit_accounts where user_id='66666666-6666-4666-8666-666666666666';
  insert into public.credit_grants(account_id,origin,external_reference,expires_at,created_at)
  values (acct,'promotion','nf/cross',null,now()) returning id into g;
  insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
  values (acct,g,'promotion',5,0,'nf-cross-grant','operational_promotion','operator/system',now());

  perform pg_temp.check('N-D6 a grant that lands above the threshold announces nothing',
    pg_temp.low_count() = 0);

  perform pg_temp.spend(1,'nf-cross-spend-1');   -- 5 -> 4, still above
  perform pg_temp.check('N-D6b 5 -> 4 announces nothing', pg_temp.low_count() = 0);

  perform pg_temp.spend(1,'nf-cross-spend-2');   -- 4 -> 3, the crossing
  perform pg_temp.check('N-D7 4 -> 3 announces the low balance exactly once',
    pg_temp.low_count() = 1);
  perform pg_temp.check('N-D7b the low balance notification is the Owner copy and unread',
    exists(select 1 from public.user_notifications
      where user_id='66666666-6666-4666-8666-666666666666'
        and type='low_credit_notification'
        and title = '남은 Credit이 3개입니다.'
        and body = '필요한 경우 Credit을 충전해 주세요.'
        and target_type = 'credit_history' and target_id is null
        and read_at is null));

  perform pg_temp.spend(1,'nf-cross-spend-3');   -- 3 -> 2
  perform pg_temp.check('N-D8 3 -> 2 announces nothing', pg_temp.low_count() = 1);

  perform pg_temp.spend(1,'nf-cross-spend-4');   -- 2 -> 1
  perform pg_temp.spend(1,'nf-cross-spend-5');   -- 1 -> 0
  perform pg_temp.check('N-D9 falling to zero from inside the low band announces nothing',
    pg_temp.low_count() = 1);

  -- Recovery and a second cycle.
  insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
  values (acct,g,'promotion',6,0,'nf-cross-grant-2','operational_promotion','operator/system',now());
  perform pg_temp.spend(1,'nf-cross-spend-6');   -- 6 -> 5
  perform pg_temp.spend(1,'nf-cross-spend-7');   -- 5 -> 4
  perform pg_temp.check('N-D9b recovering above the threshold and falling to 4 announces nothing',
    pg_temp.low_count() = 1);
  perform pg_temp.spend(1,'nf-cross-spend-8');   -- 4 -> 3, a new cycle
  perform pg_temp.check('N-D10 recovering above 3 and crossing again is a new cycle',
    pg_temp.low_count() = 2);
  perform pg_temp.check('N-D10b the new cycle states the new balance',
    exists(select 1 from public.user_notifications
      where user_id='66666666-6666-4666-8666-666666666666'
        and type='low_credit_notification' and title = '남은 Credit이 3개입니다.'
        and dedupe_key = 'low-credit/' || (select id::text from public.credit_transactions
                                            where idempotency_key='nf-cross-spend-8')));
end$$;

-- reserve and release move the reserved amount, never the balance, so an
-- evaluation that is abandoned and retried cannot re-announce a low balance the
-- member never left. The ledger constraint keeps them at balance_delta = 0 and
-- the producer returns early on a zero movement.
do $$
begin
  perform pg_temp.check('N-D11 reserve / release cannot move the ledger balance',
    exists(select 1 from pg_constraint c
      join pg_class t on t.oid = c.conrelid
     where t.relname = 'credit_transactions' and c.contype = 'c'
       and pg_get_constraintdef(c.oid) like '%reserve%balance_delta = 0%'
       and pg_get_constraintdef(c.oid) like '%release%balance_delta = 0%'));
  perform pg_temp.check('N-D11b the crossing producer ignores a zero movement',
    pg_get_functiondef('notification_private.on_credit_balance_changed()'::regprocedure)
      like '%coalesce(new.balance_delta, 0) = 0%');
end$$;

-- The daily producer is expiry only: it must not create or touch low Credit.
do $$
declare r1 jsonb;
begin
  delete from public.user_notifications;
  r1 := public.user_notification_run_daily_producers(500);
  perform pg_temp.check('N-D12 the daily run reports the expiries it created',
    (r1->>'expiry_created')::integer = 4);
  perform pg_temp.check('N-D12b the daily result no longer reports a balance counter',
    not (r1 ? 'balance_created'));
  perform pg_temp.check('N-D13 D-30 / D-14 / D-7 / D-3 each produced exactly one notification',
    (select count(*) from public.user_notifications
      where user_id='55555555-5555-4555-8555-555555555555' and type='credit_expiry') = 4);
  perform pg_temp.check('N-D13b the D-7 group summed the two grants expiring that day',
    exists(select 1 from public.user_notifications
      where user_id='55555555-5555-4555-8555-555555555555'
        and dedupe_key like 'credit-expiry/%/7' and title = '3 Credits가 7일 후 만료됩니다'));
  perform pg_temp.check('N-D13c a non-threshold date produced nothing',
    not exists(select 1 from public.user_notifications where dedupe_key like 'credit-expiry/%/20'));
  perform pg_temp.check('N-D13d the expiry notification carries the quantity and the date',
    exists(select 1 from public.user_notifications
      where dedupe_key like 'credit-expiry/%/30' and title = '3 Credits가 30일 후 만료됩니다'
        and body like '%만료일: %' and target_type = 'credit_history'));
  perform pg_temp.check('N-D14 no member is sent a low balance notification by the scheduler',
    not exists(select 1 from public.user_notifications where type='low_credit_notification'));
end$$;

-- Second run, same day, same scheduler: nothing new.
do $$
declare r2 jsonb;
begin
  r2 := public.user_notification_run_daily_producers(500);
  perform pg_temp.check('N-D15 a repeated scheduler run creates nothing',
    (r2->>'expiry_created')::integer = 0);
  perform pg_temp.check('N-D15b the expiry notifications were not duplicated',
    (select count(*) from public.user_notifications
      where user_id='55555555-5555-4555-8555-555555555555' and type='credit_expiry') = 4);
  perform pg_temp.check('N-D15c the scheduler never produced a low balance notification',
    not exists(select 1 from public.user_notifications where type='low_credit_notification'));
end$$;

-- A balance that is already below the threshold and drops further is not a new
-- crossing, and an exhausted grant must not produce an expiry notification.
do $$
declare acct uuid; today date := (essay_private.clock() at time zone 'Asia/Seoul')::date; g uuid;
begin
  select id into acct from public.credit_accounts where user_id='77777777-7777-4777-8777-777777777777';
  insert into public.credit_grants(account_id,origin,external_reference,expires_at,created_at)
  values (acct,'promotion','nf/zero-d3',((today + 3)::timestamp + time '12:00') at time zone 'Asia/Seoul',now())
  returning id into g;
  insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference,created_at)
  values (acct,g,'promotion',2,0,'nf-zero-d3-grant','operational_promotion','operator/system',now()),
         (acct,g,'adjustment',-2,0,'nf-zero-d3-consume','essay_evaluation','system/consumer',now());
  delete from public.user_notifications where user_id='77777777-7777-4777-8777-777777777777';
  perform public.user_notification_run_daily_producers(500);
  perform pg_temp.check('N-D16 a fully consumed grant expires without a notification',
    not exists(select 1 from public.user_notifications where user_id='77777777-7777-4777-8777-777777777777'));
  perform pg_temp.check('N-D16b an unexpired grant at or below the threshold is not a crossing',
    not exists(select 1 from public.user_notifications where type='low_credit_notification'));
end$$;

-- ===========================================================================
-- E. Result
-- ===========================================================================
do $$
declare total integer; failed integer;
begin
  select count(*), count(*) filter (where not ok) into total, failed from admin_verify where name like 'N-%';
  raise notice 'NOTIFICATION_CENTER_CHECKS total=% failed=%', total, failed;
  if failed > 0 then raise warning 'NOTIFICATION FAILED: % checks', failed; end if;
end$$;