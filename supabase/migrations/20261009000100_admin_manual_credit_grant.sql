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
commit;
