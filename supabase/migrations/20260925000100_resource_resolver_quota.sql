-- B2 candidate ONLY. Owner apply after Claude security review. No content writes.
begin;
create table public.resource_resolver_quota (
  bucket_key text primary key check (bucket_key = 'global' or bucket_key ~ '^resource:[0-9a-f-]{36}$'),
  window_start timestamptz not null,
  used integer not null check (used >= 0),
  expires_at timestamptz not null
);
create index resource_resolver_quota_expiry on public.resource_resolver_quota(expires_at);
alter table public.resource_resolver_quota enable row level security;
-- No client policy and no direct service-role table access. Definer owns only
-- this narrow quota operation; no resource/content SELECT or mutation in RPC.
revoke all on public.resource_resolver_quota from public, anon, authenticated, service_role;

create function public.consume_resource_resolver_quota(p_resource_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  v_now timestamptz;
  v_window timestamptz;
  v_global integer;
  v_resource integer;
  v_key text;
  -- MVP coarse shared bounds, deliberately not a per-user guarantee.
  v_global_limit constant integer := 600;
  v_resource_limit constant integer := 12;
begin
  if p_resource_id is null then return false; end if;
  -- One fixed transaction lock serializes global/resource decisions across all
  -- Edge instances. Lock timeout fails closed instead of holding a long queue.
  perform pg_catalog.set_config('lock_timeout', '500ms', true);
  perform pg_catalog.pg_advisory_xact_lock(20260925, 1);
  v_now := pg_catalog.clock_timestamp();
  v_window := pg_catalog.date_trunc('minute', v_now);
  v_key := 'resource:' || p_resource_id::text;
  -- Bounded lazy cleanup. No cron required; no IP/user/URL fields are stored.
  delete from public.resource_resolver_quota where bucket_key in (
    select bucket_key from public.resource_resolver_quota
    where expires_at <= v_now order by expires_at, bucket_key limit 128
  );
  insert into public.resource_resolver_quota values ('global', v_window, 0, v_window + interval '2 minutes')
    on conflict (bucket_key) do nothing;
  update public.resource_resolver_quota set window_start = v_window, used = 0,
    expires_at = v_window + interval '2 minutes'
    where bucket_key = 'global' and window_start <> v_window;
  select used into v_global from public.resource_resolver_quota where bucket_key = 'global';
  if v_global >= v_global_limit then return false; end if;
  -- Count even resource-denied/unknown UUID requests against the global limit.
  update public.resource_resolver_quota set used = used + 1 where bucket_key = 'global';
  insert into public.resource_resolver_quota values (v_key, v_window, 0, v_window + interval '2 minutes')
    on conflict (bucket_key) do nothing;
  update public.resource_resolver_quota set window_start = v_window, used = 0,
    expires_at = v_window + interval '2 minutes'
    where bucket_key = v_key and window_start <> v_window;
  select used into v_resource from public.resource_resolver_quota where bucket_key = v_key;
  if v_resource >= v_resource_limit then return false; end if;
  update public.resource_resolver_quota set used = used + 1 where bucket_key = v_key;
  return true;
end;
$$;
revoke all on function public.consume_resource_resolver_quota(uuid) from public, anon, authenticated;
grant execute on function public.consume_resource_resolver_quota(uuid) to service_role;
commit;
