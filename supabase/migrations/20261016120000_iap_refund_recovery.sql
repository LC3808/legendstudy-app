-- IAP store-refund Credit recovery (additive; A안).
-- Reuses the common Credit Ledger via a negative `adjustment`. Identifies the
-- refunded purchase by its canonical iap reference, recovers ONLY the unused
-- credit of THAT grant (never other paid grants, never free signup credit,
-- never consumed/reserved units), records already-used as shortfall, and is
-- idempotent across redelivered Apple/Google notifications.
--
-- Does NOT change: the Toss payment engine, iap_post_verified_purchase, the
-- essay-domain positive `refund` type, credit_transactions schema/constraints.
-- Creates NO wallet. Service-role only (store-verified notifications / backend
-- finance). Owner approved (A안, 2026-10-16); applied to the TEST project first.
--
-- ROLLBACK (manual, additive-only):
--   drop function public.iap_revoke_refunded_purchase(text,text,text,text,jsonb);
--   drop table public.iap_refund_events;
begin;

-- Idempotency + immutable audit of every store refund/void notification.
create table public.iap_refund_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('apple','google')),
  event_id text not null check (char_length(event_id) between 1 and 256),
  event_type text not null check (event_type in ('REFUND','REVOKE','VOIDED','REFUND_REVERSED')),
  reference text not null,
  transaction_id text not null,
  grant_id uuid references public.credit_grants(id),
  granted_qty integer,
  recovered_qty integer not null default 0,
  shortfall_qty integer not null default 0,
  status text not null check (status in ('PROCESSED','ALREADY_RECOVERED','UNMATCHED','REVERSED','IGNORED')),
  raw jsonb,
  created_at timestamptz not null default clock_timestamp(),
  -- Same notification redelivered → one row, no second recovery.
  unique (provider, event_id)
);
alter table public.iap_refund_events enable row level security;
-- No client policy: authenticated/anon see nothing. The SECURITY DEFINER RPC
-- (owner postgres, table owner) reads/writes it; no end-user access.
revoke all on public.iap_refund_events from public, anon, authenticated;

create function public.iap_revoke_refunded_purchase(
  p_platform text, p_transaction text, p_event_id text, p_event_type text, p_raw jsonb default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  reference text; recov_key text; rev_key text;
  g public.credit_grants; account_user uuid; existing public.iap_refund_events;
  granted integer; available integer; recover integer; prior_recover integer;
begin
  -- Only the verified-notification edge / backend finance (service_role) may post.
  if auth.role() is distinct from 'service_role' then raise sqlstate 'PT403' using message='VERIFIER_REQUIRED'; end if;
  if p_platform is null or p_platform not in ('apple','google')
     or p_transaction is null or char_length(p_transaction) not between 1 and 256 or p_transaction !~ '^[A-Za-z0-9._-]+$'
     or p_event_id is null or char_length(p_event_id) not between 1 and 256
     or p_event_type is null or p_event_type not in ('REFUND','REVOKE','VOIDED','REFUND_REVERSED') then
    raise sqlstate 'PT422' using message='INVALID_REFUND_EVENT';
  end if;
  reference := 'iap/'||p_platform||'/'||encode(pg_catalog.sha256(pg_catalog.convert_to(p_transaction,'UTF8')),'hex');
  recov_key := 'iap_refund/'||reference;      -- one recovery per grant, any notification
  rev_key   := 'iap_refund_reversal/'||reference;
  -- Serialize concurrent notifications for the same purchase.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(reference,0));

  -- Exact-notification idempotency: same (provider,event_id) seen before → no-op.
  select * into existing from public.iap_refund_events where provider=p_platform and event_id=p_event_id;
  if found then
    return jsonb_build_object('status',existing.status,'recovered',existing.recovered_qty,'shortfall',existing.shortfall_qty,'duplicate',true);
  end if;

  select * into g from public.credit_grants where external_reference=reference and origin='purchase';
  if not found then
    insert into public.iap_refund_events(provider,event_id,event_type,reference,transaction_id,status,raw)
      values(p_platform,p_event_id,p_event_type,reference,p_transaction,'UNMATCHED',p_raw);
    return jsonb_build_object('status','UNMATCHED','recovered',0,'shortfall',0,'duplicate',false);
  end if;

  -- Lock the owning subject (if still attached) to serialize with consume/reserve.
  select user_id into account_user from public.credit_accounts where id=g.account_id;
  if account_user is not null then perform account_private.lock_subject(account_user); end if;

  select coalesce(sum(balance_delta) filter (where transaction_type='purchase'),0)
    into granted from public.credit_transactions where grant_id=g.id;
  -- Unused, unreserved credit still in this grant (same basis as essay spend).
  select greatest(0,coalesce(sum(balance_delta - reserved_delta),0))
    into available from public.credit_transactions where grant_id=g.id;

  if p_event_type='REFUND_REVERSED' then
    -- Apple REFUND_REVERSED: restore the previously recovered credit, once.
    select coalesce(-sum(balance_delta),0) into prior_recover
      from public.credit_transactions where grant_id=g.id and idempotency_key=recov_key;
    if prior_recover>0 and not exists(select 1 from public.credit_transactions where idempotency_key=rev_key) then
      insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
        values(g.account_id,g.id,'adjustment',prior_recover,0,rev_key,'iap_refund_reversal_'||p_platform,'system/iap_refund');
      insert into public.iap_refund_events(provider,event_id,event_type,reference,transaction_id,grant_id,granted_qty,recovered_qty,shortfall_qty,status,raw)
        values(p_platform,p_event_id,p_event_type,reference,p_transaction,g.id,granted,-prior_recover,0,'REVERSED',p_raw);
      return jsonb_build_object('status','REVERSED','recovered',-prior_recover,'shortfall',0,'duplicate',false);
    end if;
    insert into public.iap_refund_events(provider,event_id,event_type,reference,transaction_id,grant_id,granted_qty,recovered_qty,shortfall_qty,status,raw)
      values(p_platform,p_event_id,p_event_type,reference,p_transaction,g.id,granted,0,0,'IGNORED',p_raw);
    return jsonb_build_object('status','IGNORED','recovered',0,'shortfall',0,'duplicate',false);
  end if;

  -- REFUND / REVOKE / VOIDED → recover unused credit exactly once per grant.
  if exists(select 1 from public.credit_transactions where idempotency_key=recov_key) then
    insert into public.iap_refund_events(provider,event_id,event_type,reference,transaction_id,grant_id,granted_qty,recovered_qty,shortfall_qty,status,raw)
      values(p_platform,p_event_id,p_event_type,reference,p_transaction,g.id,granted,0,0,'ALREADY_RECOVERED',p_raw);
    return jsonb_build_object('status','ALREADY_RECOVERED','recovered',0,'shortfall',0,'duplicate',false);
  end if;
  recover := available;                              -- clamp ≥0 already applied
  if recover>0 then
    insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
      values(g.account_id,g.id,'adjustment',-recover,0,recov_key,'iap_refund_'||p_platform,'system/iap_refund');
  end if;
  insert into public.iap_refund_events(provider,event_id,event_type,reference,transaction_id,grant_id,granted_qty,recovered_qty,shortfall_qty,status,raw)
    values(p_platform,p_event_id,p_event_type,reference,p_transaction,g.id,granted,recover,granted-recover,'PROCESSED',p_raw);
  return jsonb_build_object('status','PROCESSED','recovered',recover,'shortfall',granted-recover,'duplicate',false);
end$$;

alter function public.iap_revoke_refunded_purchase(text,text,text,text,jsonb) owner to postgres;
revoke all on function public.iap_revoke_refunded_purchase(text,text,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.iap_revoke_refunded_purchase(text,text,text,text,jsonb) to service_role;

commit;
