-- LOCAL TEST DATABASE ONLY. No real accounts.
create schema auth;create schema account_private;create schema essay_private;
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('test.actor',true),'')::uuid$$;
create function public.admin_operator() returns boolean language sql as $$select coalesce(current_setting('test.admin',true),'false')='true'$$;
create function account_private.allowed(uuid) returns boolean language sql as $$select coalesce(current_setting('test.allowed',true),'true')='true'$$;
create function account_private.lock_subject(uuid) returns void language sql as $$select pg_advisory_xact_lock(hashtextextended($1::text,0))$$;
create function essay_private.clock() returns timestamptz language sql as $$select coalesce(nullif(current_setting('test.clock',true),'' )::timestamptz,clock_timestamp())$$;
create table auth.users(id uuid primary key,email text);
create table public.profiles(id uuid primary key);
create table public.credit_accounts(id uuid primary key default gen_random_uuid(),user_id uuid unique);
create table public.credit_grants(id uuid primary key default gen_random_uuid(),account_id uuid references public.credit_accounts,origin text check(origin in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program')),external_reference text unique,expires_at timestamptz,created_at timestamptz default now(),unique(id,account_id));
create table public.credit_transactions(id uuid primary key default gen_random_uuid(),account_id uuid references public.credit_accounts,grant_id uuid,transaction_type text,balance_delta int not null,reserved_delta int not null,idempotency_key text unique,reason_code text,actor_reference text,created_at timestamptz default now(),foreign key(grant_id,account_id) references public.credit_grants(id,account_id),check((transaction_type in ('purchase','signup_bonus','promotion','admin_grant','compensation','b2b_program','refund') and balance_delta>0 and reserved_delta=0) or (transaction_type='reserve' and balance_delta=0 and reserved_delta>0) or (transaction_type='consume' and balance_delta<0 and reserved_delta=balance_delta) or (transaction_type='release' and balance_delta=0 and reserved_delta<0) or (transaction_type='expiration' and balance_delta<0 and reserved_delta=0) or (transaction_type='adjustment' and balance_delta<>0 and reserved_delta=0)));
create function essay_private.immutable() returns trigger language plpgsql as $$begin raise exception 'immutable finance row';end$$;
create trigger immutable before update or delete on public.credit_transactions for each row execute function essay_private.immutable();
insert into auth.users values('00000000-0000-4000-8000-000000000001','admin@example.test'),('00000000-0000-4000-8000-000000000002','student@example.test');
insert into public.profiles select id from auth.users;
grant usage on schema public,auth to authenticated,anon;
