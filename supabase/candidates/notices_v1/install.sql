-- OWNER APPLY ONLY. New isolated notices domain; no existing notification/essay writes.
begin;
create schema notice_private;
revoke all on schema notice_private from public, anon, authenticated, service_role;
create table notice_private.notices (
 notice_id uuid primary key default gen_random_uuid(), title text not null check(length(trim(title)) between 1 and 200),
 content text not null check(length(trim(content)) between 1 and 50000),
 category text not null check(category in ('general','update','beta','maintenance','policy','event')),
 status text not null check(status in ('draft','published','archived')),
 is_pinned boolean not null default false, is_public boolean not null default true,
 show_app boolean not null default true, show_web boolean not null default true,
 published_at timestamptz, expires_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id) on delete set null,
 check(status <> 'published' or published_at is not null),
 check(expires_at is null or (published_at is not null and expires_at > published_at))
);
create table notice_private.revisions (
 notice_id uuid not null references notice_private.notices, recorded_at timestamptz not null default clock_timestamp(),
 actor uuid references auth.users(id) on delete set null, snapshot jsonb not null
);
create table notice_private.reads (
 user_id uuid not null references auth.users(id) on delete cascade,
 notice_id uuid not null references notice_private.notices,
 read_at timestamptz not null default now(), primary key(user_id,notice_id)
);
alter table notice_private.notices enable row level security;
alter table notice_private.revisions enable row level security;
alter table notice_private.reads enable row level security;
revoke all on all tables in schema notice_private from public,anon,authenticated,service_role;
create index notices_feed on notice_private.notices(is_pinned desc,published_at desc,notice_id) where status='published';
-- SECURITY DEFINER API is the sole access path. No client chooses a user ID.
create function notice_private.visible(n notice_private.notices, channel text) returns boolean
language sql stable set search_path='' as $$
 select channel in ('app','web') and n.status='published' and n.published_at <= now()
 and (n.expires_at is null or n.expires_at > now())
 and (n.is_public or (auth.uid() is not null and account_private.allowed(auth.uid())))
 and case channel when 'app' then n.show_app when 'web' then n.show_web else false end
$$;
create function notice_private.dto(n notice_private.notices) returns jsonb
language sql stable set search_path='' as $$
 select to_jsonb(n) - 'created_by' || jsonb_build_object('is_read',exists(
 select 1 from notice_private.reads r where r.user_id=auth.uid() and r.notice_id=n.notice_id and r.read_at>=n.updated_at))
$$;
create function public.notice_list(p_channel text, p_offset integer default 0, p_limit integer default 20) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if p_channel is null or p_channel not in ('app','web') or p_offset is null or p_offset<0 or p_limit is null or p_limit not between 1 and 50 then raise exception 'INVALID_REQUEST' using errcode='22023'; end if;
 select jsonb_build_object('items',coalesce((select jsonb_agg(notice_private.dto(n)) from (
 select * from notice_private.notices n where notice_private.visible(n,p_channel)
 order by is_pinned desc,published_at desc,notice_id limit p_limit offset p_offset) n),'[]'::jsonb),
 'total',(select count(*) from notice_private.notices n where notice_private.visible(n,p_channel)),
 'unread',case when auth.uid() is null then 0 else (select count(*) from notice_private.notices n
 where notice_private.visible(n,p_channel) and not exists(select 1 from notice_private.reads r where r.user_id=auth.uid() and r.notice_id=n.notice_id and r.read_at>=n.updated_at)) end) into result;
 return result;
end $$;
create function public.notice_detail(p_notice_id uuid,p_channel text) returns jsonb
language sql stable security definer set search_path='' as $$
 select notice_private.dto(n) from notice_private.notices n where n.notice_id=p_notice_id and notice_private.visible(n,p_channel)
$$;
create function public.notice_mark_read(p_notice_id uuid,p_channel text,p_updated_at timestamptz) returns boolean
language plpgsql security definer set search_path='' as $$
declare n notice_private.notices;
begin
 if auth.uid() is null or not account_private.allowed(auth.uid()) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 select t.* into n from notice_private.notices t where t.notice_id=p_notice_id for share;
 if not found or not notice_private.visible(n,p_channel) or n.updated_at is distinct from p_updated_at then return false; end if;
 insert into notice_private.reads(user_id,notice_id,read_at) values(auth.uid(),n.notice_id,clock_timestamp())
 on conflict(user_id,notice_id) do update set read_at=excluded.read_at;
 return true;
end $$;
create function public.notice_admin_list(p_offset integer default 0) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if p_offset is null or p_offset<0 then raise exception 'INVALID_REQUEST'; end if;
 return jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(n)) from (select * from notice_private.notices order by updated_at desc,notice_id limit 20 offset p_offset) n),'[]'::jsonb),'total',(select count(*) from notice_private.notices));
end $$;
create function public.notice_admin_save(p jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare n notice_private.notices; id uuid; old_time timestamptz;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 id:=nullif(p->>'notice_id','')::uuid;
 if id is not null then
 select * into n from notice_private.notices where notice_id=id for update;
 if not found then raise exception 'NOT_FOUND'; end if;
 old_time:=nullif(p->>'updated_at','')::timestamptz;
 if old_time is distinct from n.updated_at then raise exception 'NOTICE_CONFLICT'; end if;
 else id:=gen_random_uuid(); end if;
 insert into notice_private.notices(notice_id,title,content,category,status,is_pinned,is_public,show_app,show_web,published_at,expires_at,created_by)
 values(id,trim(p->>'title'),trim(p->>'content'),p->>'category',p->>'status',coalesce((p->>'is_pinned')::boolean,false),coalesce((p->>'is_public')::boolean,true),coalesce((p->>'show_app')::boolean,true),coalesce((p->>'show_web')::boolean,true),nullif(p->>'published_at','')::timestamptz,nullif(p->>'expires_at','')::timestamptz,auth.uid())
 on conflict(notice_id) do update set title=excluded.title,content=excluded.content,category=excluded.category,status=excluded.status,is_pinned=excluded.is_pinned,is_public=excluded.is_public,show_app=excluded.show_app,show_web=excluded.show_web,published_at=excluded.published_at,expires_at=excluded.expires_at,updated_at=clock_timestamp()
 returning * into n;
 insert into notice_private.revisions(notice_id,actor,snapshot) values(id,auth.uid(),to_jsonb(n)-'created_by');
 return to_jsonb(n);
end $$;
revoke all on all functions in schema notice_private from public,anon,authenticated,service_role;
revoke all on function public.notice_list(text,integer,integer),public.notice_detail(uuid,text),public.notice_mark_read(uuid,text,timestamptz),public.notice_admin_list(integer),public.notice_admin_save(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.notice_list(text,integer,integer),public.notice_detail(uuid,text) to anon,authenticated;
grant execute on function public.notice_mark_read(uuid,text,timestamptz),public.notice_admin_list(integer),public.notice_admin_save(jsonb) to authenticated;
commit;
