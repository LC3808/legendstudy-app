-- OWNER REVIEW / NOT APPLIED. Run only as postgres on LegendStudy.
-- Single transaction; fail closed if runtime or the three verified grants drift.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
lock table public.credit_grants in access exclusive mode;
lock table public.credit_transactions in share mode;
do $$ begin
 if current_user <> 'postgres' then raise exception 'postgres required'; end if;
 if md5(pg_get_functiondef('public.iap_post_verified_purchase(uuid,text,text,text,timestamptz)'::regprocedure)) <> 'b2ed6d8deca59f8cad0b83a1e7f02225' then
  raise exception 'IAP RPC changed: re-review required'; end if;
 if (select count(*) from public.credit_grants where external_reference like 'iap/%') <> 3 then
  raise exception 'Receipt inventory changed: re-review required'; end if;
 if (select count(*) from public.credit_grants g where external_reference like 'iap/%'
     and origin='purchase' and expires_at>clock_timestamp()
     and (expires_at at time zone 'Asia/Seoul')::date in (date '2027-01-22',date '2027-01-23')
     and exists(select 1 from public.credit_transactions t where t.grant_id=g.id
       and t.transaction_type='purchase' and t.reason_code in ('iap_apple_v1','iap_google_v1'))
    ) <> 3 then raise exception 'Verified grant inventory changed'; end if;
 if not exists(select 1 from pg_trigger where tgrelid='public.credit_grants'::regclass
    and tgname='credit_grant_terms_frozen' and tgenabled='O'
    and tgfoid='account_private.finance_privacy_guard()'::regprocedure) then
   raise exception 'Finance guard changed'; end if;
end $$;
-- Restricted, append-only amendment evidence. No receipt strings or new wallet.
create table account_private.iap_expiry_amendments_20261023 (
 grant_id uuid primary key references public.credit_grants(id),
 old_expires_at timestamptz not null,
 new_expires_at timestamptz not null check(new_expires_at>old_expires_at),
 amended_at timestamptz not null default clock_timestamp(),
 policy text not null default 'iap_kst_calendar_3months_end_of_day_v1'
);
revoke all on account_private.iap_expiry_amendments_20261023 from public,anon,authenticated,service_role;
create trigger iap_expiry_amendments_frozen before update or delete
 on account_private.iap_expiry_amendments_20261023 for each row
 execute function account_private.finance_privacy_guard();
insert into account_private.iap_expiry_amendments_20261023(grant_id,old_expires_at,new_expires_at)
 select id,expires_at,((expires_at at time zone 'Asia/Seoul')::date+time '23:59:59.999999') at time zone 'Asia/Seoul'
 from public.credit_grants where external_reference like 'iap/%';
-- Only inside the exclusive table lock. The permanent guard/function stays intact.
alter table public.credit_grants disable trigger credit_grant_terms_frozen;
update public.credit_grants g set expires_at=a.new_expires_at
 from account_private.iap_expiry_amendments_20261023 a
 where g.id=a.grant_id and g.expires_at=a.old_expires_at;
alter table public.credit_grants enable trigger credit_grant_terms_frozen;
create or replace function public.iap_post_verified_purchase(p_user uuid,p_platform text,p_product text,p_transaction text,p_purchased_at timestamptz)
returns text language plpgsql security definer set search_path='' as $$
declare quantity integer; reference text; account uuid; existing public.credit_grants; expiry timestamptz; legacy_expiry timestamptz;
begin
 if auth.role() is distinct from 'service_role' then raise sqlstate 'PT403' using message='VERIFIER_REQUIRED'; end if;
 quantity=case p_product when 'com.legendstudy.essay.credit1' then 1 when 'com.legendstudy.essay.credit3' then 3 when 'com.legendstudy.essay.credit5' then 5 when 'com.legendstudy.essay.credit10' then 10 else null end;
 if p_user is null or quantity is null or p_platform is null or p_platform not in ('apple','google') or p_transaction is null or char_length(p_transaction) not between 1 and 256 or p_transaction !~ '^[A-Za-z0-9._-]+$' or p_purchased_at is null or not isfinite(p_purchased_at) or p_purchased_at>clock_timestamp()+interval '1 minute' then raise sqlstate 'PT422' using message='INVALID_PURCHASE';end if;
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 reference='iap/'||p_platform||'/'||encode(pg_catalog.sha256(pg_catalog.convert_to(p_transaction,'UTF8')),'hex');
 -- Global receipt lock serializes simultaneous claims from different accounts.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(reference,0));
 legacy_expiry=(p_purchased_at at time zone 'UTC'+interval '3 months') at time zone 'UTC';
 expiry=(((p_purchased_at at time zone 'Asia/Seoul')::date+interval '3 months')::date+time '23:59:59.999999') at time zone 'Asia/Seoul';
 select id into account from public.credit_accounts where user_id=p_user;
 select * into existing from public.credit_grants where external_reference=reference;
 if found then
  if existing.account_id is distinct from account or existing.origin<>'purchase' or (existing.expires_at is distinct from expiry and existing.expires_at is distinct from legacy_expiry)
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

do $$ begin
 if (select count(*) from account_private.iap_expiry_amendments_20261023 a
     join public.credit_grants g on g.id=a.grant_id where g.expires_at=a.new_expires_at)<>3
 then raise exception 'Amendment verification failed';end if;
end $$;
commit;
