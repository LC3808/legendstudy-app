CREATE OR REPLACE FUNCTION essay_private.credit_post_grant(p_user uuid, p_quantity integer, p_origin text, p_key text, p_reason text, p_actor text, p_expires timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare account uuid; g public.credit_grants; t public.credit_transactions;
begin
 if p_user is null or p_quantity is null or p_quantity<=0 or p_quantity>100000
 or p_origin is null or p_origin not in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program')
 or nullif(btrim(p_key),'') is null or length(p_key)>200 or nullif(btrim(p_reason),'') is null or nullif(btrim(p_actor),'') is null
 or not exists(select 1 from public.profiles where id=p_user) then raise sqlstate 'PT422' using message='INVALID_GRANT';end if;
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 insert into public.credit_accounts(user_id) values(p_user) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=p_user for update;
 select * into g from public.credit_grants where external_reference=p_key;
 if g.id is not null then
  select * into t from public.credit_transactions where idempotency_key='grant/'||p_key;
  if g.account_id is distinct from account or g.origin is distinct from p_origin or g.expires_at is distinct from p_expires
  or t.balance_delta is distinct from p_quantity or t.reason_code is distinct from p_reason or t.actor_reference is distinct from p_actor
  then raise sqlstate 'PT409' using message='CONFLICT';end if;return g.id;
 end if;
 if p_expires is not null and p_expires<=essay_private.clock() then raise sqlstate 'PT422' using message='INVALID_EXPIRY';end if;
 insert into public.credit_grants(account_id,origin,external_reference,expires_at) values(account,p_origin,p_key,p_expires) returning * into g;
 insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
 values(account,g.id,p_origin,p_quantity,0,'grant/'||p_key,p_reason,p_actor);
 return g.id;
exception when unique_violation then raise sqlstate 'PT409' using message='CONFLICT';
end$function$
;
CREATE OR REPLACE FUNCTION public.admin_manual_credit_grant(p_user uuid, p_email text, p_quantity integer, p_reason text, p_key uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
end $function$
;
