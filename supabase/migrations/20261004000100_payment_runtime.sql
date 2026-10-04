-- Additive read/support boundary. No activation, grant, or second wallet.
begin;
create function public.credit_summary() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid(); result jsonb;
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 with grants as (
 select g.id,g.origin,g.expires_at,coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved,
 exists(select 1 from public.payment_orders o where o.grant_id=g.id and o.state='CANCEL_PENDING') fenced
 from public.credit_accounts a join public.credit_grants g on g.account_id=a.id
 left join public.credit_transactions t on t.grant_id=g.id where a.user_id=u
 group by g.id
 ), spend as(select *,greatest(0,balance-reserved) available from grants where (expires_at is null or expires_at>statement_timestamp()) and not fenced)
 select jsonb_build_object('dto_version','credit-v1','as_of',statement_timestamp(),
 'spendable',coalesce(sum(available),0),'paid',coalesce(sum(available) filter(where origin='purchase'),0),
 'free',coalesce(sum(available) filter(where origin='signup_bonus'),0),
 'other',coalesce(sum(available) filter(where origin not in ('purchase','signup_bonus')),0),
 'reserved',coalesce(sum(reserved),0),'next_expiry',min(expires_at) filter(where available>0)) into result from spend;
 return result;
end$$;
revoke all on function public.credit_summary() from public,anon,authenticated,service_role;
grant execute on function public.credit_summary() to authenticated;

-- Operator identity comes only from fresh server Auth verification and allowlist.
-- Immutable bounded audit: no provider secrets, user learning data or raw payload.
create table payment_private.support_audit(
 id bigint generated always as identity primary key,
 operator_id uuid not null, request_key uuid not null, order_id uuid not null references public.payment_orders(id),
 action text not null check(action in ('inspect','cancel','reconcile')),
 created_at timestamptz not null default clock_timestamp(), unique(operator_id,request_key)
);
alter table payment_private.support_audit enable row level security;
revoke all on payment_private.support_audit from public,anon,authenticated,service_role,essay_finance;
create function public.payment_support(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.payment_orders; a uuid; used integer=0; remaining integer=0; reserved integer=0; audit payment_private.support_audit; result jsonb;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' or
 p-array['dto_version','action','id','operator_id','request_key']<>'{}'::jsonb or not(p ?& array['action','id','operator_id','request_key']) or
 p->>'action' not in ('inspect','cancel','reconcile') then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 if o.subject_id is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into a from public.credit_accounts where id=coalesce((select account_id from public.credit_grants where id=o.grant_id),(select id from public.credit_accounts where user_id=o.subject_id)) for update;
 select * into o from public.payment_orders where id=o.id for update;
 insert into payment_private.support_audit(operator_id,request_key,order_id,action) values((p->>'operator_id')::uuid,(p->>'request_key')::uuid,o.id,p->>'action') on conflict(operator_id,request_key) do nothing;
 select * into audit from payment_private.support_audit where operator_id=(p->>'operator_id')::uuid and request_key=(p->>'request_key')::uuid;
 if audit.order_id<>o.id or audit.action<>p->>'action' then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
 if o.mode='LIVE' and o.grant_id is not null then
  select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0),greatest(0,coalesce(-sum(balance_delta) filter(where transaction_type in ('consume','refund')),0))
   into remaining,reserved,used from public.credit_transactions where grant_id=o.grant_id;
 else remaining=o.quantity;end if;
 result=payment_private.result(o.id);
 return jsonb_build_object('order',result,'owner_id',o.subject_id,'used',used,'remaining',remaining,'reserved',reserved,
 'refund_amount',greatest(0,o.amount-used*o.deduction_unit),
 'eligible',o.state='PAID' and o.amount-used*o.deduction_unit>0 and o.credit_expires_at>statement_timestamp() and reserved=0 and remaining=o.quantity-used,
 'compensation_required',o.mode='LIVE' and o.state='AUTHORIZATION_PENDING' and o.grant_id is null and (o.subject_id is null or not account_private.allowed(o.subject_id)),
 'reason','GENERAL_REFUND');
end$$;
revoke all on function public.payment_support(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_support(jsonb) to essay_finance;
-- Provider-approved purchase whose account became restricted before grant.
-- Trusted server verifies DONE receipt first; never grant or revive the account.
-- Durable full-refund claim then uses the existing cancel_finish (revoke_quantity=0).
create function public.payment_compensate(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.payment_orders; op public.payment_operations; paid timestamptz; a uuid;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' or
 p-array['dto_version','id','payment_key','amount','paid_at','request_key']<>'{}'::jsonb or not(p ?& array['id','payment_key','amount','paid_at','request_key']) then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 if o.subject_id is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into a from public.credit_accounts where user_id=o.subject_id for update;
 select * into o from public.payment_orders where id=o.id for update;
 paid=(p->>'paid_at')::timestamptz;
 if o.provider<>'TOSS' or o.mode<>'LIVE' or o.grant_id is not null or p->>'payment_key' is distinct from o.provider_purchase_id or (p->>'amount')::integer is distinct from o.amount or paid is null or paid<o.created_at-interval '5 minutes' or paid>clock_timestamp()+interval '5 minutes' then raise sqlstate 'PT422' using message='COMPENSATION_MISMATCH';end if;
 select * into op from public.payment_operations where order_id=o.id and kind='CANCEL' and request_key=(p->>'request_key')::uuid;
 if op.id is not null then
  if paid is distinct from o.paid_at then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  return payment_private.result(o.id);
 end if;
 if o.state<>'AUTHORIZATION_PENDING' or o.grant_state<>'NONE' or (o.subject_id is not null and account_private.allowed(o.subject_id)) then raise sqlstate 'PT409' using message='COMPENSATION_NOT_REQUIRED';end if;
 select * into op from public.payment_operations where order_id=o.id and kind='CONFIRM' and state='PENDING' for update;
 if op.id is null then raise sqlstate 'PT409' using message='PENDING_CONFIRM_REQUIRED';end if;
 update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
 insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRMED');
 insert into public.payment_operations(order_id,kind,request_key,state,amount,consumed,revoke_quantity,reason)
 values(o.id,'CANCEL',(p->>'request_key')::uuid,'PENDING',o.amount,0,0,'GENERAL_REFUND') returning * into op;
 update public.payment_orders set state='CANCEL_PENDING',paid_at=paid,credit_expires_at=(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC' where id=o.id;
 insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCEL_STARTED');
 return payment_private.result(o.id);
end$$;
revoke all on function public.payment_compensate(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_compensate(jsonb) to essay_finance;
notify pgrst,'reload schema';
commit;
