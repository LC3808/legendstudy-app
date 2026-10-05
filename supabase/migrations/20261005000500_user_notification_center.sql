-- ADMIN-P0-B ADDENDUM — shared user notification center.
--
-- LegendStudy APP and LegendStudy LAB are one account on one backend, so the
-- notification inbox is one server-side source of truth. Web and APP read the
-- same rows and the same read_at, which is why the reader is a plain
-- owner-scoped RPC rather than anything client-specific.
--
-- This is deliberately NOT the email layer. public.feedback_notifications and
-- public.inquiry_notifications are email delivery outboxes with their own
-- retry/attempt semantics; they keep that meaning. A row here is "the member
-- can see this in the inbox", and it survives mail failure because the two are
-- produced from the same canonical event but stored independently.
--
-- Everything here is additive: no existing table, function, trigger or grant
-- from the essay/credit/payment/account-deletion work is modified, and the Math
-- runtime is not touched (its producer is a documented connection point).

begin;

-- ---------------------------------------------------------------------------
-- 1. Internal schema for the single trusted producer entry point.
-- ---------------------------------------------------------------------------
create schema if not exists notification_private;
revoke all on schema notification_private from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Canonical model.
--
-- `user_id` is always the auth user id, never a credit account id, because that
-- is the identity both clients hold. A notification carries a summary and a
-- target reference only: no answer text, no provider payload, no token.
-- ---------------------------------------------------------------------------
create table public.user_notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null,
    title text not null,
    body text not null,
    target_type text,
    target_id uuid,
    dedupe_key text not null,
    created_at timestamptz not null default essay_private.clock(),
    read_at timestamptz,
    constraint user_notifications_title_len check (char_length(title) between 1 and 120),
    constraint user_notifications_body_len check (char_length(body) between 1 and 400),
    constraint user_notifications_dedupe_len check (char_length(dedupe_key) between 1 and 200),
    -- The P0 producer set, plus the types already reserved for later features so
    -- that adding a producer needs no schema change. An unknown type is still
    -- rejected: the type space is closed, not free text.
    constraint user_notifications_type check (type in (
        'inquiry_reply',
        'essay_evaluation_complete',
        'math_evaluation_complete',
        'payment_complete',
        'credit_grant',
        'credit_balance_reminder',
        'credit_expiry',
        'payment_refund',
        'account_notice',
        'admission_schedule',
        'dday',
        'service_notice'
    )),
    constraint user_notifications_target_type check (
        target_type is null or target_type in (
            'inquiry', 'essay_evaluation', 'math_evaluation',
            'payment_order', 'credit_history', 'essay_lab'
        )
    ),
    -- A target is a typed reference. A row id always needs its type; a type with
    -- no id means "that screen" (the Credit history, say). An arbitrary URL is
    -- not representable here, which is the point.
    constraint user_notifications_target_pair check (
        target_id is null or target_type is not null
    ),
    constraint user_notifications_read_state check (read_at is null or read_at >= created_at),
    constraint user_notifications_dedupe unique (user_id, dedupe_key)
);

comment on table public.user_notifications is
    'Canonical user notification inbox shared by LegendStudy APP and LAB. Written only by trusted producers through notification_private.emit; read and acknowledged by the owner through public.user_notification_* RPCs. Email delivery state lives in the separate outbox tables.';
comment on column public.user_notifications.dedupe_key is
    'Producer-owned idempotency key. The unique (user_id, dedupe_key) constraint is the authority against duplicate notifications, including repeated scheduler runs and retried operator submissions.';

create index user_notifications_owner_recent
    on public.user_notifications (user_id, created_at desc, id desc);
create index user_notifications_owner_unread
    on public.user_notifications (user_id)
    where read_at is null;

-- No client role reaches the table directly. RLS is on with no policy, so the
-- default is deny, and the table privileges are revoked as a second layer.
alter table public.user_notifications enable row level security;
revoke all on table public.user_notifications from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. The trusted producer entry point.
--
-- Only SECURITY DEFINER producers inside this database can call it: EXECUTE is
-- revoked from every role including service_role, and the producers run as the
-- schema owner. A browser session therefore has no path to create a row.
-- ---------------------------------------------------------------------------
create function notification_private.emit(
    p_user uuid,
    p_type text,
    p_title text,
    p_body text,
    p_target_type text,
    p_target_id uuid,
    p_dedupe_key text,
    p_created_at timestamptz default null
) returns uuid
language plpgsql security definer set search_path='' as $$
declare new_id uuid;
begin
    if p_user is null
       or nullif(btrim(p_dedupe_key), '') is null
       or nullif(btrim(p_title), '') is null
       or nullif(btrim(p_body), '') is null then
        raise sqlstate 'PT422' using message='INVALID_NOTIFICATION';
    end if;
    insert into public.user_notifications(user_id, type, title, body, target_type, target_id, dedupe_key, created_at)
    values (p_user, p_type, p_title, p_body, p_target_type, p_target_id, btrim(p_dedupe_key),
            coalesce(p_created_at, essay_private.clock()))
    on conflict (user_id, dedupe_key) do nothing
    returning id into new_id;
    return new_id;
exception
    when check_violation or foreign_key_violation or not_null_violation then
        raise sqlstate 'PT422' using message='INVALID_NOTIFICATION';
end$$;
revoke all on function notification_private.emit(uuid,text,text,text,text,uuid,text,timestamptz)
    from public, anon, authenticated, service_role;

-- ===========================================================================
-- 4. Producers
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 4.1 inquiry_reply — the member's 1:1 inquiry received an operator reply.
--
-- Attached to the reply row rather than to the operator RPC, so it fires on the
-- one event that matters and cannot be bypassed by a future call path. A
-- duplicate submit returns the existing reply without inserting, so no second
-- notification is produced; the dedupe key is the reply identity.
-- ---------------------------------------------------------------------------
create function notification_private.on_inquiry_reply() returns trigger
language plpgsql security definer set search_path='' as $$
declare owner uuid; subject text;
begin
    select i.user_id, i.title into owner, subject
      from public.inquiries i where i.id = new.inquiry_id;
    if owner is null then return null; end if;
    perform notification_private.emit(
        owner,
        'inquiry_reply',
        '1:1 문의 답변이 도착했습니다',
        '문의하신 내용에 답변이 등록되었습니다.',
        'inquiry',
        new.inquiry_id,
        'inquiry-reply/' || new.id::text
    );
    return null;
end$$;
revoke all on function notification_private.on_inquiry_reply() from public, anon, authenticated, service_role;

create trigger inquiry_reply_notifies_member
    after insert on public.inquiry_replies
    for each row execute function notification_private.on_inquiry_reply();

-- ---------------------------------------------------------------------------
-- 4.2 credit_grant — a canonical Credit grant was posted to the ledger.
--
-- Attached to the ledger posting, not to any UI or caller, so purchase,
-- promotion, admin_grant, compensation and b2b_program are covered by one rule
-- and the notification exists only after the ledger row exists. signup_bonus is
-- excluded: the member already sees the free Credit at signup and a notification
-- for it would be noise (the brief leaves this to operations).
-- The idempotency key of the posting is the dedupe key, so a retried poster that
-- returns the existing grant produces nothing.
-- ---------------------------------------------------------------------------
create function notification_private.on_credit_grant_posted() returns trigger
language plpgsql security definer set search_path='' as $$
declare owner uuid; origin text; quantity integer;
begin
    if new.transaction_type not in ('purchase', 'promotion', 'admin_grant', 'compensation', 'b2b_program')
       or coalesce(new.balance_delta, 0) <= 0 then
        return null;
    end if;
    select ca.user_id, g.origin into owner, origin
      from public.credit_grants g
      join public.credit_accounts ca on ca.id = g.account_id
     where g.id = new.grant_id;
    if owner is null then return null; end if;
    quantity := new.balance_delta;
    perform notification_private.emit(
        owner,
        'credit_grant',
        quantity || ' Credits가 지급되었습니다',
        quantity || ' Credits가 지급되었습니다. Credit 내역에서 확인할 수 있습니다.',
        'credit_history',
        new.grant_id,
        'credit-grant/' || new.idempotency_key
    );
    return null;
end$$;
revoke all on function notification_private.on_credit_grant_posted() from public, anon, authenticated, service_role;

create trigger credit_grant_posted_notifies_member
    after insert on public.credit_transactions
    for each row execute function notification_private.on_credit_grant_posted();

-- ---------------------------------------------------------------------------
-- 4.3 essay_evaluation_complete — 인문논술 첨삭 completed.
--
-- Fires on the canonical completed state, never on a client's belief that a
-- request succeeded: only essay_evaluations reaching status='completed' with
-- completed_at set can notify, and the table's own check constraint enforces
-- that a completed row carries real evaluation output.
-- The owner is resolved through the practice session.
-- ---------------------------------------------------------------------------
create function notification_private.on_essay_evaluation_complete() returns trigger
language plpgsql security definer set search_path='' as $$
declare owner uuid;
begin
    if new.status <> 'completed' or new.completed_at is null then return null; end if;
    if tg_op = 'UPDATE' and old.status = 'completed' and old.completed_at is not null then
        return null;  -- already completed; only the first transition notifies
    end if;
    select s.user_id into owner from public.essay_practice_sessions s where s.id = new.session_id;
    if owner is null then return null; end if;
    perform notification_private.emit(
        owner,
        'essay_evaluation_complete',
        '논술 첨삭이 완료되었습니다',
        '논술 첨삭이 완료되었습니다. 결과를 확인해보세요.',
        'essay_evaluation',
        new.attempt_id,   -- the LAB result route is keyed by the attempt
        'essay-evaluation/' || new.id::text
    );
    return null;
end$$;
revoke all on function notification_private.on_essay_evaluation_complete() from public, anon, authenticated, service_role;

create trigger essay_evaluation_complete_notifies_member
    after insert or update of status on public.essay_evaluations
    for each row execute function notification_private.on_essay_evaluation_complete();

-- ---------------------------------------------------------------------------
-- 4.4 payment_complete — provider-confirmed purchase.
--
-- Payment is not live, and its migrations are excluded from this change's
-- verification chain, so this producer is a function rather than a trigger: the
-- future payment success path calls it once the order is paid AND the Credit
-- grant is posted. Nothing can call it today, which is what "dormant" means
-- here. It is granted to essay_executor and to no client role, and it refuses an
-- order/quantity that does not match the ledger.
-- ---------------------------------------------------------------------------
create function public.user_notification_payment_complete(p_order_id uuid)
returns uuid
language plpgsql security definer set search_path='' as $$
declare owner uuid; quantity integer;
begin
    if p_order_id is null then raise sqlstate 'PT422' using message='INVALID_NOTIFICATION'; end if;
    select o.user_id into owner from public.payment_orders o where o.id = p_order_id;
    if owner is null then return null; end if;
    -- Only after the ledger has a matching grant for this order.
    select t.balance_delta into quantity
      from public.credit_transactions t
     where t.idempotency_key = 'grant/' || p_order_id::text;
    if quantity is null or quantity <= 0 then return null; end if;
    return notification_private.emit(
        owner,
        'payment_complete',
        quantity || ' Credits 구매가 완료되었습니다',
        quantity || ' Credits 구매가 완료되었습니다. 결제·Credit 내역에서 확인할 수 있습니다.',
        'payment_order',
        p_order_id,
        'payment-complete/' || p_order_id::text
    );
end$$;
revoke all on function public.user_notification_payment_complete(uuid) from public, anon, authenticated, service_role;
grant execute on function public.user_notification_payment_complete(uuid) to service_role, essay_executor;

-- ---------------------------------------------------------------------------
-- 4.5 math_evaluation_complete — 연결 지점 (READY_TO_CONNECT).
--
-- The Math runtime is being smoke-tested in parallel, and its migrations are not
-- part of this change's verified chain, so no trigger is attached to the Math
-- tables. The entry point below is the whole connection: the Math completion
-- path calls it once, next to the statement that commits the completed state.
-- ---------------------------------------------------------------------------
create function public.user_notification_math_evaluation_complete(p_attempt_id uuid, p_evaluation_id uuid)
returns uuid
language plpgsql security definer set search_path='' as $$
declare owner uuid;
begin
    if p_attempt_id is null or p_evaluation_id is null then
        raise sqlstate 'PT422' using message='INVALID_NOTIFICATION';
    end if;
    select a.student_id into owner from public.math_attempts a where a.id = p_attempt_id;
    if owner is null then return null; end if;
    return notification_private.emit(
        owner,
        'math_evaluation_complete',
        '수리논술 첨삭이 완료되었습니다',
        '수리논술 첨삭이 완료되었습니다. 결과를 확인해보세요.',
        'math_evaluation',
        p_evaluation_id,
        'math-evaluation/' || p_evaluation_id::text
    );
end$$;
revoke all on function public.user_notification_math_evaluation_complete(uuid,uuid)
    from public, anon, authenticated, service_role;
grant execute on function public.user_notification_math_evaluation_complete(uuid,uuid) to essay_executor;

-- ---------------------------------------------------------------------------
-- 4.6 + 4.7 credit_balance_reminder / credit_expiry — the daily producer.
--
-- One bounded, idempotent call covers both. The database unique constraint is
-- the authority on duplication, so a scheduler that runs twice, retries, or
-- overlaps produces nothing extra; the scheduler is only a trigger.
--
-- Expiry thresholds are the user-visible expiry date in Asia/Seoul, so grants
-- expiring on the same day are summed into one notification per threshold
-- instead of one per grant.
-- ---------------------------------------------------------------------------
create function public.user_notification_run_daily_producers(
    p_limit integer default 500,
    p_balance_threshold integer default 3
) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
    bounded integer := least(greatest(coalesce(p_limit, 1), 1), 2000);
    threshold integer := least(greatest(coalesce(p_balance_threshold, 3), 1), 100);
    today date := (essay_private.clock() at time zone 'Asia/Seoul')::date;
    expiry_created integer := 0;
    balance_created integer := 0;
    s record;
begin
    -- Expiry: remaining Credits per (user, expiry date), notified at D-30/14/7/3.
    for s in
        select ca.user_id,
               (g.expires_at at time zone 'Asia/Seoul')::date as expiry_date,
               sum(t.balance_delta - t.reserved_delta)::integer as remaining,
               ((g.expires_at at time zone 'Asia/Seoul')::date - today) as days_left
          from public.credit_grants g
          join public.credit_accounts ca on ca.id = g.account_id
          join public.credit_transactions t on t.grant_id = g.id
         where g.expires_at is not null
           and (g.expires_at at time zone 'Asia/Seoul')::date between today and today + 30
         group by ca.user_id, (g.expires_at at time zone 'Asia/Seoul')::date
        having sum(t.balance_delta - t.reserved_delta) > 0
         order by 2, 1
         limit bounded
    loop
        if s.days_left not in (30, 14, 7, 3) then continue; end if;
        if notification_private.emit(
               s.user_id,
               'credit_expiry',
               s.remaining || ' Credits가 ' || s.days_left || '일 후 만료됩니다',
               s.remaining || ' Credits가 ' || s.days_left || '일 후 만료됩니다. 만료일: '
                   || to_char(s.expiry_date, 'YYYY.MM.DD') || '. Credit 내역에서 확인할 수 있습니다.',
               'credit_history',
               null,
               'credit-expiry/' || to_char(s.expiry_date, 'YYYY-MM-DD') || '/' || s.days_left
           ) is not null then
            expiry_created := expiry_created + 1;
        end if;
    end loop;

    -- Balance: a low positive balance is worth one reminder a day. Zero balance
    -- is not nagged: the member already gets the expiry notice and the inbox is
    -- not an advertising channel. The once-a-day rule is the date in the key.
    for s in
        select ca.user_id, sum(t.balance_delta - t.reserved_delta)::integer as remaining
          from public.credit_accounts ca
          join public.credit_grants g on g.account_id = ca.id
          join public.credit_transactions t on t.grant_id = g.id
         where g.expires_at is null or g.expires_at > essay_private.clock()
         group by ca.user_id
        having sum(t.balance_delta - t.reserved_delta) between 1 and threshold
         order by 1
         limit bounded
    loop
        if notification_private.emit(
               s.user_id,
               'credit_balance_reminder',
               '현재 ' || s.remaining || ' Credits가 남아 있습니다',
               '현재 ' || s.remaining || ' Credits가 남아 있습니다. Credit 내역에서 확인할 수 있습니다.',
               'credit_history',
               null,
               'credit-balance/' || to_char(today, 'YYYY-MM-DD')
           ) is not null then
            balance_created := balance_created + 1;
        end if;
    end loop;

    return jsonb_build_object(
        'expiry_created', expiry_created,
        'balance_created', balance_created,
        'as_of', today
    );
end$$;
revoke all on function public.user_notification_run_daily_producers(integer,integer)
    from public, anon, authenticated, service_role;
grant execute on function public.user_notification_run_daily_producers(integer,integer) to service_role, essay_executor;

-- ===========================================================================
-- 5. Owner-facing read and acknowledgement
-- ===========================================================================

-- Exactly one notification, and only the caller's own.
create function public.user_notification_mark_read(p_id uuid)
returns boolean
language plpgsql security definer set search_path='' as $$
declare u uuid = essay_private.uid(); touched integer;
begin
    if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
    if p_id is null then raise sqlstate 'PT422' using message='INVALID_NOTIFICATION'; end if;
    update public.user_notifications
       set read_at = coalesce(read_at, essay_private.clock())
     where id = p_id and user_id = u;
    get diagnostics touched = row_count;
    return touched = 1;
end$$;
revoke all on function public.user_notification_mark_read(uuid) from public, anon, authenticated, service_role;
grant execute on function public.user_notification_mark_read(uuid) to authenticated;

-- Everything unread becomes read. Idempotent.
create function public.user_notifications_mark_all_read()
returns integer
language plpgsql security definer set search_path='' as $$
declare u uuid = essay_private.uid(); touched integer;
begin
    if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
    update public.user_notifications
       set read_at = essay_private.clock()
     where user_id = u and read_at is null;
    get diagnostics touched = row_count;
    return touched;
end$$;
revoke all on function public.user_notifications_mark_all_read() from public, anon, authenticated, service_role;
grant execute on function public.user_notifications_mark_all_read() to authenticated;

-- Badge count. Cheap: partial index, owner-only.
create function public.user_notifications_unread_count()
returns integer
language plpgsql security definer set search_path='' as $$
declare u uuid = essay_private.uid(); n integer;
begin
    if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
    select count(*)::integer into n
      from public.user_notifications where user_id = u and read_at is null;
    return n;
end$$;
revoke all on function public.user_notifications_unread_count() from public, anon, authenticated, service_role;
grant execute on function public.user_notifications_unread_count() to authenticated;

-- Bounded, newest-first list. The DTO mirrors the other client contracts.
create function public.user_notifications_list(
    p_limit integer default 20,
    p_offset integer default 0,
    p_unread_only boolean default false
) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
    u uuid = essay_private.uid();
    bounded integer := least(greatest(coalesce(p_limit, 20), 1), 50);
    skipped integer := least(greatest(coalesce(p_offset, 0), 0), 5000);
    items jsonb;
    unread integer;
begin
    if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED'; end if;
    select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.created_at desc, x.id desc), '[]'::jsonb)
      into items
      from (
        select n.id, n.type, n.title, n.body, n.target_type, n.target_id,
               n.created_at, n.read_at, (n.read_at is not null) as is_read
          from public.user_notifications n
         where n.user_id = u
           and (not coalesce(p_unread_only, false) or n.read_at is null)
         order by n.created_at desc, n.id desc
         limit bounded offset skipped
      ) x;
    select count(*)::integer into unread
      from public.user_notifications where user_id = u and read_at is null;
    return jsonb_build_object(
        'dto_version', 'notification-v1',
        'as_of', essay_private.clock(),
        'limit', bounded,
        'offset', skipped,
        'unread', unread,
        'items', items
    );
end$$;
revoke all on function public.user_notifications_list(integer,integer,boolean)
    from public, anon, authenticated, service_role;
grant execute on function public.user_notifications_list(integer,integer,boolean) to authenticated;

commit;