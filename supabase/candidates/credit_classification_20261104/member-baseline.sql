CREATE OR REPLACE FUNCTION public.admin_member_credit(p_account_id uuid, p_limit integer DEFAULT 25, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare lim integer; off integer; acct uuid; result jsonb; fenced uuid[] := array[]::uuid[];
begin
 if not public.admin_operator() then raise sqlstate 'PT401' using message='OPERATOR_REQUIRED'; end if;
 -- Match credit_summary without requiring the optional payment subsystem.
 if to_regclass('public.payment_orders') is not null then
  execute $$select coalesce(array_agg(o.grant_id) filter (where o.grant_id is not null),array[]::uuid[]) from public.payment_orders o where o.state='CANCEL_PENDING'$$ into fenced;
 end if;
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
     case when (gr.expires_at is not null and gr.expires_at<=statement_timestamp()) or gr.id=any(fenced) then 0
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
end$function$;
