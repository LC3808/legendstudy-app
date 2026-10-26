create role anon;create role authenticated;create role service_role;
create schema auth;create schema account_private;
create function auth.uid() returns uuid language sql as $$select '00000000-0000-4000-8000-000000000001'::uuid$$;
create function public.admin_operator() returns boolean language sql as $$select coalesce(current_setting('test.admin',true),'false')='true'$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select true$$;
create table auth.users(id uuid primary key,email text,created_at timestamptz,last_sign_in_at timestamptz);
create table public.credit_accounts(id uuid primary key,user_id uuid unique);
create table public.credit_grants(id uuid primary key,account_id uuid,origin text,expires_at timestamptz,created_at timestamptz);
create table public.credit_transactions(id uuid primary key,account_id uuid,grant_id uuid,transaction_type text,balance_delta int,reserved_delta int,created_at timestamptz);
create table public.payment_orders(grant_id uuid,state text);
insert into auth.users select md5(i::text)::uuid,'member'||i||'@example.test',now()-i*interval '1 day',null from generate_series(1,55)i;
insert into credit_accounts select id,id from auth.users;
insert into credit_grants select id,id,'purchase',null,created_at from auth.users;
insert into credit_transactions select id,id,id,'purchase',10,0,created_at from auth.users;
CREATE OR REPLACE FUNCTION public.admin_credit_snapshot(p_account_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb; fenced uuid[] := array[]::uuid[];
begin
 if p_account_id is null then return null; end if;
 -- Match credit_summary without requiring the optional payment subsystem.
 if to_regclass('public.payment_orders') is not null then
  execute $$select coalesce(array_agg(o.grant_id) filter (where o.grant_id is not null),array[]::uuid[]) from public.payment_orders o where o.state='CANCEL_PENDING'$$ into fenced;
 end if;
 with g as (
  select gr.id,gr.origin,gr.expires_at,
   coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved
  from public.credit_grants gr left join public.credit_transactions t on t.grant_id=gr.id
  where gr.account_id=p_account_id group by gr.id
 ), s as (
  select *,greatest(0,balance-reserved) available from g
  where (expires_at is null or expires_at>statement_timestamp()) and not (id=any(fenced))
 )
 select jsonb_build_object(
  'spendable',coalesce(sum(available),0),
  'paid',coalesce(sum(available) filter (where origin='purchase'),0),
  'free',coalesce(sum(available) filter (where origin='signup_bonus'),0),
  'other',coalesce(sum(available) filter (where origin not in ('purchase','signup_bonus')),0),
  'reserved',coalesce(sum(reserved),0),
  'next_expiry',min(expires_at) filter (where available>0)
 ) into result from s;
 return result;
end$function$
;
