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
commit;
