-- PAYMENT APP foundation. NOT APPLIED. No provider/network calls or LIVE activation.
begin;
create schema payment_private;
revoke all on schema payment_private from public,anon,authenticated,service_role;
grant usage on schema payment_private to essay_executor;
create table payment_private.configuration(singleton boolean primary key check(singleton), mode text not null check(mode in ('TEST','LIVE')));
insert into payment_private.configuration values(true,'TEST');
create table public.payment_orders(
 id uuid primary key default gen_random_uuid(),
 subject_id uuid references public.profiles(id) on delete set null,
 request_key uuid not null,
 provider text not null default 'TOSS' check(provider in ('TOSS','APPLE_IAP','GOOGLE_PLAY')),
 mode text not null check(mode in ('TEST','LIVE')),
 sku text not null check(sku in ('1c','3c','5c','10c')),
 amount integer not null check(amount>0), quantity integer not null check(quantity in (1,3,5,10)),
 currency text not null default 'KRW' check(currency='KRW'),
 policy_version text not null default 'commerce-2026-10-03' check(policy_version='commerce-2026-10-03'),
 deduction_unit integer not null default 4900 check(deduction_unit=4900), validity_months integer not null default 3 check(validity_months=3),
 state text not null default 'ORDER_CREATED' check(state in ('ORDER_CREATED','AUTHORIZATION_PENDING','PAID','CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED','FAILED','EXPIRED')),
 grant_state text not null default 'NONE' check(grant_state in ('NONE','TEST_RECORDED','POSTED','REVOKED')),
 provider_purchase_id text check(length(provider_purchase_id) between 1 and 1024),
 grant_id uuid unique references public.credit_grants(id) on delete restrict,
 created_at timestamptz not null default clock_timestamp(), expires_at timestamptz not null default clock_timestamp()+interval '30 minutes',
 paid_at timestamptz, credit_expires_at timestamptz,
 unique(subject_id,request_key),
 unique(provider,mode,provider_purchase_id),
 check(mode<>'TEST' or (grant_id is null and grant_state in ('NONE','TEST_RECORDED','REVOKED'))),
 check(grant_state<>'POSTED' or (mode='LIVE' and grant_id is not null)),
 check(state not in ('PAID','CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED') or (paid_at is not null and provider_purchase_id is not null))
);
create table public.payment_operations(
 id uuid primary key default gen_random_uuid(),order_id uuid not null references public.payment_orders(id) on delete restrict,
 kind text not null check(kind in ('CONFIRM','CANCEL')), request_key uuid not null,
 state text not null check(state in ('PENDING','SUCCEEDED','FAILED')),
 provider_idempotency_key text not null unique default gen_random_uuid()::text,
 amount integer not null check(amount>0), consumed integer not null default 0 check(consumed>=0), revoke_quantity integer not null default 0 check(revoke_quantity>=0),
 reason text not null check(reason in ('PURCHASE','GENERAL_REFUND')),
 error_code text check(error_code in ('PROVIDER_REJECTED','PROVIDER_UNAVAILABLE','OUTCOME_UNKNOWN')),
 created_at timestamptz not null default clock_timestamp(), completed_at timestamptz,
 unique(order_id,kind,request_key)
);
create unique index payment_one_pending_operation on public.payment_operations(order_id) where state='PENDING';
create unique index payment_one_confirm on public.payment_operations(order_id) where kind='CONFIRM';
create unique index payment_one_cancel_success on public.payment_operations(order_id) where kind='CANCEL' and state='SUCCEEDED';
create table public.payment_events(
 id bigint generated always as identity primary key,order_id uuid not null references public.payment_orders(id) on delete restrict,
 operation_id uuid references public.payment_operations(id) on delete restrict,
 event text not null check(event in ('CREATED','CONFIRM_STARTED','CONFIRMED','CANCEL_STARTED','CANCELLED','UNKNOWN','REJECTED')),
 created_at timestamptz not null default clock_timestamp()
);
create index payment_owner_history on public.payment_orders(subject_id,created_at,id);
create index payment_reconcile on public.payment_operations(created_at,id) where state='PENDING';
create index payment_events_order on public.payment_events(order_id,id);
alter table public.payment_orders enable row level security;
alter table public.payment_operations enable row level security;
alter table public.payment_events enable row level security;
alter table payment_private.configuration enable row level security;
revoke all on public.payment_orders,public.payment_operations,public.payment_events,payment_private.configuration from public,anon,authenticated,service_role;
revoke all on sequence public.payment_events_id_seq from public,anon,authenticated,service_role;
grant select on payment_private.configuration to essay_executor;
grant select,insert,update on public.payment_orders,public.payment_operations to essay_executor;
grant select,insert on public.payment_events to essay_executor;
grant usage on sequence public.payment_events_id_seq to essay_executor;

create function payment_private.result(p_id uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('dto_version','payment-v1','order_id','ls_'||replace(id::text,'-',''),'id',id,'provider',provider,'mode',mode,'sku',sku,'amount',amount,'quantity',quantity,'currency',currency,'state',state,'grant_state',grant_state,'expires_at',expires_at,'paid_at',paid_at,'credit_expires_at',credit_expires_at) from public.payment_orders where id=p_id
$$;
revoke all on function payment_private.result(uuid) from public,anon,authenticated,service_role;
grant execute on function payment_private.result(uuid) to essay_executor;
-- A pending refund must freeze new consumption authorizations. Existing reservations
-- cause cancel_begin to fail; all operations first lock the canonical account.
create function payment_private.spend_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare purchase public.payment_orders; operation public.payment_operations;
begin
 select * into purchase from public.payment_orders where grant_id=new.grant_id;
 if purchase.state in ('CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED') then
  select * into operation from public.payment_operations where order_id=purchase.id and kind='CANCEL' and state='PENDING';
  if purchase.state<>'CANCEL_PENDING' or operation.id is null or new.transaction_type<>'adjustment'
   or new.balance_delta<>-operation.revoke_quantity or new.reserved_delta<>0
   or new.idempotency_key is distinct from 'payment_cancel/'||operation.id::text
   or new.reason_code<>'purchase_cancel_v1' then
   raise sqlstate 'PT409' using message='PURCHASE_REFUND_FENCED';
  end if;
 end if;
 return new;end$$;
revoke all on function payment_private.spend_guard() from public,anon,authenticated,service_role;
create trigger payment_purchase_spend_guard before insert on public.credit_transactions for each row execute function payment_private.spend_guard();

-- Exact bootstrap allowlist: payment_order(jsonb), payment_process(jsonb).
-- Fail rather than modifying an unexpected starting ownership topology.
do $$begin
 if current_user<>'postgres' or pg_has_role('postgres','essay_executor','SET') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'PAYMENT_BOOTSTRAP_TOPOLOGY';end if;
end$$;
create temporary table payment_bootstrap_before on commit drop as select (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) memberships,(select nspacl::text from pg_namespace where nspname='public') acl;
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to essay_executor;
set role essay_executor;
create function public.payment_order(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid();o public.payment_orders;v_mode text;n integer;a integer;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 -- Match account lifecycle lock order; no implicit ADR installation/activation.
 if to_regprocedure('account_private.lock_subject(uuid)') is null then raise sqlstate 'PT503' using message='LIFECYCLE_PREREQUISITE';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 if p->>'action'='create' then
  if p-array['dto_version','action','sku','request_key']<>'{}'::jsonb or nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  select mode into v_mode from payment_private.configuration where singleton;
  if v_mode is null then raise sqlstate 'PT503' using message='MODE_UNAVAILABLE';end if;
  select quantity,price into n,a from (values('1c',1,4900),('3c',3,11900),('5c',5,17900),('10c',10,29900)) x(sku,quantity,price) where sku=p->>'sku';
  if n is null then raise sqlstate 'PT422' using message='INVALID_SKU';end if;
  insert into public.payment_orders(subject_id,request_key,mode,sku,amount,quantity) values(u,(p->>'request_key')::uuid,v_mode,p->>'sku',a,n) on conflict(subject_id,request_key) do nothing returning * into o;
  if o.id is null then
   select * into o from public.payment_orders where subject_id=u and request_key=(p->>'request_key')::uuid;
   if o.sku is distinct from p->>'sku' then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  else insert into public.payment_events(order_id,event) values(o.id,'CREATED');end if;
 elsif p->>'action'='get' then
  if p-array['dto_version','action','id']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  select * into o from public.payment_orders where id=(p->>'id')::uuid and subject_id=u;
  if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 else raise sqlstate 'PT422' using message='INVALID_ACTION';end if;
 return payment_private.result(o.id);
end$$;
revoke all on function public.payment_order(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_order(jsonb) to authenticated;

-- Trusted gateway only: independently authenticate the buyer and verify Toss by
-- server-held matching TEST credentials before reporting canonical provider facts.
-- Browser/anon/service_role have no EXECUTE. No raw provider payload accepted.
create function public.payment_process(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare allowed_keys text[];o public.payment_orders;op public.payment_operations;account uuid;remaining integer;reserved integer;used integer;amount integer;g uuid;result jsonb;paid timestamptz;action text=p->>'action';k uuid;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>4096 or p->>'dto_version' is distinct from 'payment-v1' or p-array['dto_version','action','id','request_key','payment_key','amount','paid_at','operation_id','outcome','error_code']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 allowed_keys=case action
 when 'confirm_begin' then array['dto_version','action','id','request_key','payment_key','amount']
 when 'confirm_finish' then array['dto_version','action','id','operation_id','payment_key','amount','paid_at']
 when 'cancel_begin' then array['dto_version','action','id','request_key']
 when 'cancel_finish' then array['dto_version','action','id','operation_id','payment_key','amount']
 when 'outcome' then array['dto_version','action','id','operation_id','outcome']
 when 'get' then array['dto_version','action','id'] end;
 if allowed_keys is null or p-allowed_keys<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 -- Lifecycle -> account -> order -> operation/grant; gateway identity is a
 -- dedicated authenticated operator, not caller-supplied account authority.
 if o.subject_id is not null and to_regprocedure('account_private.lock_subject(uuid)') is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into account from public.credit_accounts where id=coalesce((select account_id from public.credit_grants where id=o.grant_id),(select id from public.credit_accounts where user_id=o.subject_id)) for update;
 select * into o from public.payment_orders where id=o.id for update;
 if o.provider<>'TOSS' then raise sqlstate 'PT403' using message='PROVIDER_NOT_ENABLED';end if;
 if o.mode is distinct from (select mode from payment_private.configuration where singleton) then raise sqlstate 'PT403' using message='MODE_DISABLED';end if;
 if action='confirm_begin' then
  if nullif(p->>'payment_key','') is null or length(p->>'payment_key')>200 or (p->>'amount')::integer is distinct from o.amount or nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='CONFIRM_MISMATCH';end if;
  k=(p->>'request_key')::uuid;
  if o.provider_purchase_id is not null and o.provider_purchase_id is distinct from p->>'payment_key' then raise sqlstate 'PT409' using message='PAYMENT_IDENTITY_CONFLICT';end if;
  select * into op from public.payment_operations where order_id=o.id and kind='CONFIRM';
  if op.id is null then
   if o.state<>'ORDER_CREATED' or clock_timestamp()>=o.expires_at then raise sqlstate 'PT409' using message='ORDER_EXPIRED_OR_CONFLICT';end if;
   if o.subject_id is null or not account_private.allowed(o.subject_id) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
   update public.payment_orders set state='AUTHORIZATION_PENDING',provider_purchase_id=p->>'payment_key' where id=o.id;
   insert into public.payment_operations(order_id,kind,request_key,state,amount,reason) values(o.id,'CONFIRM',k,'PENDING',o.amount,'PURCHASE') returning * into op;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRM_STARTED');
  elsif op.request_key<>k then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
 elsif action='confirm_finish' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id and kind='CONFIRM' for update;
  if op.id is null or p->>'payment_key' is distinct from o.provider_purchase_id or (p->>'amount')::integer is distinct from o.amount then raise sqlstate 'PT422' using message='CONFIRM_MISMATCH';end if;
  paid=(p->>'paid_at')::timestamptz;
  if paid is null or paid<o.created_at-interval '5 minutes' or paid>clock_timestamp()+interval '5 minutes' then raise sqlstate 'PT422' using message='INVALID_PAID_AT';end if;
  if op.state='SUCCEEDED' then
   if paid is distinct from o.paid_at then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  else
   if op.state<>'PENDING' or o.state<>'AUTHORIZATION_PENDING' then raise sqlstate 'PT409' using message='ORDER_STATE_CONFLICT';end if;
   if o.mode='LIVE' then
    if o.subject_id is null or not account_private.allowed(o.subject_id) then raise sqlstate 'PT409' using message='PAID_REQUIRES_REFUND_RECONCILIATION';end if;
    g=essay_private.credit_post_grant(o.subject_id,o.quantity,'purchase','payment/'||o.id::text,'purchase_v1','system/payment',(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC');
   end if;
   update public.payment_orders set state='PAID',paid_at=paid,credit_expires_at=(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC',grant_id=g,grant_state=case when mode='TEST' then 'TEST_RECORDED' else 'POSTED' end where id=o.id;
   update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRMED');
  end if;
 elsif action='cancel_begin' then
  if nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  k=(p->>'request_key')::uuid;
  select * into op from public.payment_operations where order_id=o.id and kind='CANCEL' and request_key=k;
  if op.id is null then
   if o.state<>'PAID' or clock_timestamp()>=o.credit_expires_at then raise sqlstate 'PT409' using message='REFUND_UNAVAILABLE';end if;
   if o.mode='TEST' then used=0;remaining=o.quantity;reserved=0;
   else
    perform 1 from public.credit_grants where id=o.grant_id for update;
    select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0),greatest(0,-coalesce(sum(balance_delta) filter(where transaction_type in ('consume','refund')),0)) into remaining,reserved,used from public.credit_transactions where grant_id=o.grant_id;
   end if;
   amount=greatest(0,o.amount-used*o.deduction_unit);
   if reserved<>0 then raise sqlstate 'PT409' using message='CREDIT_RESERVED';end if;
   if amount=0 then raise sqlstate 'PT409' using message='NO_REFUND_DUE';end if;
   if remaining<0 or used>o.quantity or remaining<>o.quantity-used then raise sqlstate 'PT409' using message='LEDGER_RECONCILIATION_REQUIRED';end if;
   insert into public.payment_operations(order_id,kind,request_key,state,amount,consumed,revoke_quantity,reason) values(o.id,'CANCEL',k,'PENDING',amount,used,remaining,'GENERAL_REFUND') returning * into op;
   update public.payment_orders set state='CANCEL_PENDING' where id=o.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCEL_STARTED');
  end if;
 elsif action='cancel_finish' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id and kind='CANCEL' for update;
  if op.id is null or (p->>'amount')::integer is distinct from op.amount or p->>'payment_key' is distinct from o.provider_purchase_id then raise sqlstate 'PT422' using message='CANCEL_MISMATCH';end if;
  if op.state<>'SUCCEEDED' then
   if op.state<>'PENDING' or o.state<>'CANCEL_PENDING' then raise sqlstate 'PT409' using message='ORDER_STATE_CONFLICT';end if;
   if o.mode='LIVE' and op.revoke_quantity>0 then
    insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
    values(account,o.grant_id,'adjustment',-op.revoke_quantity,0,'payment_cancel/'||op.id::text,'purchase_cancel_v1','system/payment');
   end if;
   update public.payment_orders set state=case when op.amount=o.amount then 'CANCELLED' else 'PARTIALLY_CANCELLED' end,grant_state='REVOKED' where id=o.id;
   update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCELLED');
  end if;
 elsif action='outcome' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id for update;
  if op.id is null or op.state<>'PENDING' or p->>'outcome' not in ('UNKNOWN','REJECTED') or p->>'outcome' is null then raise sqlstate 'PT422' using message='INVALID_OUTCOME';end if;
  if p->>'outcome'='UNKNOWN' then update public.payment_operations set error_code='OUTCOME_UNKNOWN' where id=op.id;
  else
   update public.payment_operations set state='FAILED',error_code='PROVIDER_REJECTED',completed_at=clock_timestamp() where id=op.id;
   update public.payment_orders set state=case when op.kind='CONFIRM' then 'FAILED' else 'PAID' end where id=o.id;
  end if;
  insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,p->>'outcome');
 elsif action='get' then
  select * into op from public.payment_operations where order_id=o.id order by created_at desc,id desc limit 1;
 else raise sqlstate 'PT422' using message='INVALID_ACTION';end if;
 select * into op from public.payment_operations where id=op.id;
 return payment_private.result(o.id)||jsonb_build_object('operation_id',op.id,'operation_state',op.state,'provider_idempotency_key',op.provider_idempotency_key,'operation_amount',op.amount,'consumed',op.consumed,'payment_key',(select provider_purchase_id from public.payment_orders where id=o.id));
end$$;
revoke all on function public.payment_process(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_process(jsonb) to essay_finance;
reset role;
revoke create on schema public from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$begin
 if (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) is distinct from (select memberships from payment_bootstrap_before) or (select nspacl::text from pg_namespace where nspname='public') is distinct from (select acl from payment_bootstrap_before) then raise exception 'PAYMENT_BOOTSTRAP_RESTORE';end if;
end$$;
commit;
