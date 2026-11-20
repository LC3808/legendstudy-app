-- Disposable PostgreSQL only. Minimal dependencies, not a Production migration.
-- Actual application/day_targets migrations are loaded after this foundation.
create schema auth;
create schema account_private;
revoke all on schema account_private from public, anon, authenticated;

create table auth.users(id uuid primary key);
create table public.profiles(
 id uuid primary key references auth.users on delete cascade,
 target_label text, target_date date
);
create table public.universities(id uuid primary key, name text not null, slug text, is_active boolean not null default true);
create table public.admin_users(user_id uuid primary key references auth.users on delete cascade);
create table public.account_deletion_requests(
 id uuid primary key default gen_random_uuid(),
 subject_id uuid references auth.users on delete cascade,
 state text not null
);
alter table public.admin_users enable row level security;
alter table public.account_deletion_requests enable row level security;
revoke all on public.admin_users, public.account_deletion_requests from public,anon,authenticated;

create function auth.uid() returns uuid language sql stable as $$
 select (nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')::uuid
$$;
create function account_private.lock_subject(u uuid) returns void language sql volatile security definer set search_path='' as $$
 select pg_advisory_xact_lock(hashtextextended(u::text,84612))
$$;
create function account_private.allowed(u uuid) returns boolean language sql stable security definer set search_path='' as $$
 select u is not null and exists(select 1 from auth.users where id=u)
 and not exists(select 1 from public.account_deletion_requests where subject_id=u and state in ('DELETION_PENDING','ERASING'))
$$;
create function public.account_service_allowed() returns boolean language sql stable security definer set search_path='' as $$select account_private.allowed(auth.uid())$$;
create function public.admin_operator() returns boolean language plpgsql stable security definer set search_path='' as $$
declare claims jsonb=nullif(current_setting('request.jwt.claims',true),'')::jsonb;
begin
 return coalesce(claims->>'role'='authenticated' and (claims->>'exp')::numeric>extract(epoch from now())
 and exists(select 1 from public.admin_users where user_id=auth.uid()),false);
end$$;
create function account_private.personal_write_gate() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid; rowdata jsonb=to_jsonb(new); begin
 u=case when tg_table_name='profiles' then (rowdata->>'id')::uuid else coalesce(rowdata->>'user_id',rowdata->>'owner_id')::uuid end;
 if u is not null then perform account_private.lock_subject(u);if not account_private.allowed(u) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;end if;
 return new;
end$$;
create function account_private.caller_write_gate() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); begin
 if u is not null then perform account_private.lock_subject(u);if not account_private.allowed(u) then raise insufficient_privilege;end if;end if;
 return null;
end$$;
revoke all on all functions in schema account_private from public,anon,authenticated;
revoke all on function public.account_service_allowed(),public.admin_operator() from public,anon,authenticated;
grant execute on function public.account_service_allowed(),public.admin_operator() to authenticated;
grant usage on schema public,auth to anon,authenticated;

insert into auth.users(id) values
 ('00000000-0000-4000-8000-000000000001'),
 ('00000000-0000-4000-8000-000000000002'),
 ('00000000-0000-4000-8000-000000000003'),
 ('00000000-0000-4000-8000-000000000004');
insert into public.profiles(id) select id from auth.users;
insert into public.admin_users values('00000000-0000-4000-8000-000000000001');
insert into public.universities(id,name,slug) values
 ('10000000-0000-4000-8000-000000000001','합성대학교','synthetic-one'),
 ('10000000-0000-4000-8000-000000000002','다른합성대학교','synthetic-two');
