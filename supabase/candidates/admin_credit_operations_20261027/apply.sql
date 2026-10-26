-- APPLIED 2026-10-27 with Owner approval. DO NOT REEXECUTE. Additive RPCs only; no existing row UPDATE.
begin;
set local lock_timeout='5s';
do $guard$ begin
 if md5(pg_get_functiondef('essay_private.credit_post_grant(uuid,integer,text,text,text,text,timestamptz)'::regprocedure))<>'0df3300b46a557380e30867e061594bf' then raise exception 'BASELINE_CHANGED';end if;
 if md5(pg_get_functiondef('public.admin_manual_credit_grant(uuid,text,integer,text,uuid)'::regprocedure))<>'f9d760b2f810c57aa18d7097e5e7f5b3' then raise exception 'BASELINE_CHANGED';end if;
end $guard$;

create function public.admin_credit_operation_info(p_user uuid,p_grant uuid default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare g public.credit_grants; a uuid; b bigint; r bigint; initial bigint; used bigint; revoked bigint; expired bigint;
begin
 if public.admin_operator() is not true or account_private.allowed(auth.uid()) is not true then raise sqlstate 'PT403' using message='OPERATOR_REQUIRED'; end if;
 if p_grant is null then return jsonb_build_object('version','admin-credit-operations-v1'); end if;
 select id into a from public.credit_accounts where user_id=p_user;
 select * into g from public.credit_grants where id=p_grant and account_id=a;
 if g.id is null then raise sqlstate 'PT404' using message='GRANT_NOT_FOUND'; end if;
 select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0),
 coalesce(sum(balance_delta) filter(where transaction_type=g.origin),0),
 coalesce(-sum(balance_delta) filter(where transaction_type='consume'),0),
 coalesce(-sum(balance_delta) filter(where transaction_type='adjustment' and balance_delta<0),0),
 coalesce(-sum(balance_delta) filter(where transaction_type='expiration'),0)
 into b,r,initial,used,revoked,expired from public.credit_transactions where grant_id=g.id;
 return jsonb_build_object('version','admin-credit-operations-v1','grant_id',g.id,'initial',initial,'used',used,'reserved',r,'recovered',revoked,'expired',expired,'balance',b,
 'recoverable',case when g.origin in ('admin_grant','promotion','compensation') and (g.expires_at is null or g.expires_at>essay_private.clock()) then greatest(0,b-r) else 0 end);
end $$;

create function public.admin_credit_grant_expiring(p_user uuid,p_email text,p_quantity integer,p_kind text,p_validity text,p_date date,p_reason text,p_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); target text; expiry timestamptz; g public.credit_grants; origin text; reason text;
begin
 if public.admin_operator() is not true or account_private.allowed(actor) is not true then raise sqlstate 'PT403' using message='OPERATOR_REQUIRED'; end if;
 if p_user is null or p_key is null or p_quantity is null or p_quantity not between 1 and 100
 or p_kind is null or p_kind not in ('admin_grant','promotion','compensation','other')
 or p_validity is null or p_validity not in ('none','7','14','30','90','custom')
 or (p_validity='custom')<>(p_date is not null)
 or p_reason is null or btrim(p_reason)!~'[^[:space:]]' or length(btrim(p_reason)) not between 1 and 500 then raise sqlstate 'PT422' using message='INVALID_GRANT'; end if;
 select email into target from auth.users where id=p_user;
 if target is null or p_email is null or lower(btrim(target))<>lower(btrim(p_email)) then raise sqlstate 'PT409' using message='TARGET_CONFIRMATION_CHANGED'; end if;
 perform account_private.lock_subject(p_user);
 insert into public.credit_accounts(user_id) values(p_user) on conflict(user_id) do nothing;
 perform 1 from public.credit_accounts where user_id=p_user for update;
 origin:=case when p_kind='other' then 'admin_grant' else p_kind end;
 reason:=jsonb_build_object('operation','admin_grant_v2','kind',p_kind,'validity',p_validity,'date',p_date,'reason',btrim(p_reason))::text;
 -- Reuse persisted expiry on retries; never recompute a moving 7-day deadline.
 select * into g from public.credit_grants where external_reference='admin_expiring/'||p_key::text;
 if g.id is not null then expiry:=g.expires_at;
 elsif p_validity='custom' then expiry:=(p_date+time '23:59:59') at time zone 'Asia/Seoul';
 elsif p_validity<>'none' then expiry:=essay_private.clock()+make_interval(hours=>p_validity::integer*24);
 end if;
 return essay_private.credit_post_grant(p_user,p_quantity,origin,'admin_expiring/'||p_key::text,reason,'operator/'||actor::text,expiry);
end $$;

create function public.admin_credit_recover(p_user uuid,p_grant uuid,p_quantity integer,p_reason text,p_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); a uuid; g public.credit_grants; t public.credit_transactions; b bigint; r bigint; result uuid; reason text;
begin
 if public.admin_operator() is not true or account_private.allowed(actor) is not true then raise sqlstate 'PT403' using message='OPERATOR_REQUIRED'; end if;
 if p_user is null or p_grant is null or p_key is null or p_quantity is null or p_quantity<=0 or p_reason is null or btrim(p_reason)!~'[^[:space:]]' or length(btrim(p_reason)) not between 1 and 500 then raise sqlstate 'PT422' using message='INVALID_RECOVERY'; end if;
 perform account_private.lock_subject(p_user);
 if account_private.allowed(p_user) is not true then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED'; end if;
 select id into a from public.credit_accounts where user_id=p_user for update;
 select * into g from public.credit_grants where id=p_grant and account_id=a for update;
 if g.id is null then raise sqlstate 'PT404' using message='GRANT_NOT_FOUND'; end if;
 if g.origin not in ('admin_grant','promotion','compensation') then raise sqlstate 'PT422' using message='GRANT_NOT_RECOVERABLE'; end if;
 reason:=jsonb_build_object('operation','admin_recovery_v1','reason',btrim(p_reason))::text;
 select * into t from public.credit_transactions where idempotency_key='admin_recovery/'||p_key::text;
 if t.id is not null then
  if t.account_id is distinct from a or t.grant_id is distinct from p_grant or t.balance_delta is distinct from -p_quantity or t.reason_code is distinct from reason or t.actor_reference is distinct from 'operator/'||actor::text then raise sqlstate 'PT409' using message='CONFLICT'; end if;
  return t.id;
 end if;
 if g.expires_at is not null and g.expires_at<=essay_private.clock() then raise sqlstate 'PT409' using message='GRANT_EXPIRED'; end if;
 select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0) into b,r from public.credit_transactions where grant_id=g.id;
 if r<0 or b<r or p_quantity>b-r then raise sqlstate 'PT409' using message='RECOVERABLE_BALANCE_CHANGED'; end if;
 insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
 values(a,g.id,'adjustment',-p_quantity,0,'admin_recovery/'||p_key::text,reason,'operator/'||actor::text) returning id into result;
 return result;
exception when unique_violation then raise sqlstate 'PT409' using message='CONFLICT';
end $$;
revoke all on function public.admin_credit_operation_info(uuid,uuid),public.admin_credit_grant_expiring(uuid,text,integer,text,text,date,text,uuid),public.admin_credit_recover(uuid,uuid,integer,text,uuid) from public,anon,service_role;
grant execute on function public.admin_credit_operation_info(uuid,uuid),public.admin_credit_grant_expiring(uuid,text,integer,text,text,date,text,uuid),public.admin_credit_recover(uuid,uuid,integer,text,uuid) to authenticated;
commit;
