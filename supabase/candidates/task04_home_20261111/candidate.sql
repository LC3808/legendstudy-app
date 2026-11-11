-- CANDIDATE ONLY. Not part of migrations; never applied to production by task04.
-- Run only in an isolated database for review, or after separate Owner approval.
begin;
create table public.home_configuration_revisions (
  user_id uuid not null references auth.users(id) on delete cascade,
  revision bigint not null check (revision > 0),
  config_version integer not null check (config_version = 1),
  cards jsonb not null check (jsonb_typeof(cards) = 'array'),
  updated_at timestamptz not null default now(),
  primary key(user_id, revision)
);
alter table public.home_configuration_revisions enable row level security;
create policy home_configuration_owner_read on public.home_configuration_revisions
  for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.home_configuration_revisions from public, anon, authenticated;
-- Only the RPC can read/write. Historical revisions are not client-writable.
create function public.my_home_configuration() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('config_version', config_version, 'cards', cards, 'revision', revision, 'updated_at', updated_at)
  from public.home_configuration_revisions where user_id = auth.uid() order by revision desc limit 1;
$$;
create function public.save_my_home_configuration(p_config jsonb, p_revision bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_owner uuid := auth.uid(); v_current jsonb; v_card jsonb; v_ids text[] := '{}'; v_revision bigint;
begin
  if v_owner is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_revision is null or p_revision < 0 or p_config is null or jsonb_typeof(p_config) <> 'object'
    or p_config->>'config_version' is distinct from '1' or jsonb_typeof(p_config->'cards') is distinct from 'array'
    then raise exception 'Invalid configuration' using errcode='22023'; end if;
  if pg_column_size(p_config) > 65536 or jsonb_array_length(p_config->'cards') > 100 then raise exception 'Too many cards' using errcode='22023'; end if;
  for v_card in select value from jsonb_array_elements(p_config->'cards') loop
    if jsonb_typeof(v_card->'card_id') is distinct from 'string' or not (v_card->>'card_id' ~ '^[a-z][a-z0-9_]{0,79}$')
      or jsonb_typeof(v_card->'visible') is distinct from 'boolean'
      or jsonb_typeof(v_card->'display_order') is distinct from 'number'
      or not (v_card->>'display_order' ~ '^[0-9]{1,3}$')
      or (v_card->>'card_id') = any(v_ids)
      then raise exception 'Invalid card' using errcode='22023'; end if;
    v_ids := array_append(v_ids, v_card->>'card_id');
  end loop;
  perform pg_advisory_xact_lock(hashtextextended('home-configuration:' || v_owner::text, 0));
  v_current := public.my_home_configuration();
  v_revision := coalesce((v_current->>'revision')::bigint, 0);
  -- A lost response can be retried safely without duplicating history.
  if v_current is not null and v_current->'cards' = p_config->'cards' then return v_current; end if;
  if v_revision <> p_revision then raise exception 'Configuration changed' using errcode='40001'; end if;
  insert into public.home_configuration_revisions(user_id, revision, config_version, cards)
    values(v_owner, v_revision + 1, 1, p_config->'cards');
  return public.my_home_configuration();
end;
$$;
revoke all on function public.my_home_configuration() from public, anon;
revoke all on function public.save_my_home_configuration(jsonb,bigint) from public, anon;
grant execute on function public.my_home_configuration() to authenticated;
grant execute on function public.save_my_home_configuration(jsonb,bigint) to authenticated;

-- An operator-reviewed allowlist, not URLs guessed from catalog slugs.
create table public.university_official_sources (
  university_id uuid not null references public.universities(id),
  source_host text not null check (source_host ~ '^[a-z0-9.-]+$'),
  reviewed_at timestamptz not null,
  primary key(university_id,source_host)
);
create table public.university_news_revisions (
  id uuid primary key default gen_random_uuid(),
  series_key uuid not null,
  revision integer not null check(revision > 0),
  university_id uuid not null references public.universities(id),
  academic_year integer check(academic_year between 2020 and 2200),
  admission_round text,
  admission_type text,
  department_name text,
  scope text not null check(scope in ('university','track','division')),
  kind text not null check(kind in ('schedule','news')),
  event_type text not null,
  title text not null check(length(title) between 1 and 500),
  precision text not null check(precision in ('unknown','date','exact','after')),
  starts_on date, ends_on date,
  starts_at timestamptz, ends_at timestamptz,
  timezone text not null default 'Asia/Seoul' check(timezone='Asia/Seoul'),
  source_host text not null,
  source_title text not null,
  source_url text not null check(source_url ~ '^https://[^/]+/'),
  source_sha256 text not null check(source_sha256 ~ '^[a-f0-9]{64}$'),
  source_archive_key text not null,
  source_locator text not null, -- PDF page/paragraph/notice identifier
  published_at timestamptz,
  verified_at timestamptz not null,
  updated_at timestamptz not null, -- source modification time; not collection time
  expires_at timestamptz not null,
  status text not null check(status in ('verified','withdrawn')),
  created_at timestamptz not null default now(),
  unique(series_key,revision),
  foreign key(university_id,source_host) references public.university_official_sources,
  check(lower(substring(source_url from '^https://([^/:?#]+)')) = source_host),
  check(expires_at > verified_at),
  check(kind='news' or academic_year is not null),
  check((scope='university' and admission_round is null and admission_type is null and department_name is null)
    or (scope='track' and academic_year is not null and admission_round is not null and admission_type is not null and department_name is null)
    or (scope='division' and academic_year is not null and admission_round is not null and admission_type is not null and department_name is not null)),
  check((precision='unknown' and starts_on is null and ends_on is null and starts_at is null and ends_at is null)
    or (precision='date' and starts_on is not null and starts_at is null and ends_at is null and (ends_on is null or ends_on >= starts_on))
    or (precision in ('exact','after') and starts_at is not null and starts_on is null and ends_on is null and (ends_at is null or ends_at >= starts_at)))
);
create index university_news_source_fk on public.university_news_revisions(university_id,source_host);
create index university_news_series_revision on public.university_news_revisions(series_key,revision desc);
alter table public.university_official_sources enable row level security;
alter table public.university_news_revisions enable row level security;
revoke all on public.university_official_sources, public.university_news_revisions from public, anon, authenticated;
create function public.task04_news_immutable() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'Append a new revision; official evidence is immutable'; end; $$;
create trigger university_news_immutable before update or delete on public.university_news_revisions
for each row execute function public.task04_news_immutable();
create function public.university_news_feed(p_universities uuid[], p_offset integer default 0, p_as_of timestamptz default null) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare v_items jsonb; v_more boolean; v_snapshot timestamptz := coalesce(p_as_of, now());
begin
  if p_universities is null or cardinality(p_universities) > 1000 or p_offset is null or p_offset < 0 or p_offset > 10000 or v_snapshot > now() or v_snapshot < now() - interval '10 minutes'
    then raise exception 'Invalid query' using errcode='22023'; end if;
  -- Choose latest BEFORE filtering status/university, so withdrawals or corrected
  -- identity never resurrect an older verified schedule. No student data read.
  with latest as (
    select distinct on (series_key) n.* from public.university_news_revisions n where n.created_at <= v_snapshot order by series_key,revision desc
  ), page as (
    select n.*, u.name as university_name from latest n join public.universities u on u.id=n.university_id
    where n.status='verified' and n.university_id=any(p_universities) order by n.series_key limit 101 offset p_offset
  ), numbered as (select *, row_number() over(order by series_key) rn from page)
  select coalesce(jsonb_agg(to_jsonb(numbered) - 'rn' - 'source_archive_key' - 'source_sha256' order by series_key) filter(where rn <= 100),'[]'::jsonb), coalesce(bool_or(rn > 100),false)
    into v_items,v_more from numbered;
  return jsonb_build_object('version','university-news-v1','snapshot_at',v_snapshot,'items',v_items,'has_more',v_more);
end; $$;
revoke all on function public.task04_news_immutable() from public, anon, authenticated;
revoke all on function public.university_news_feed(uuid[],integer,timestamptz) from public, anon;
grant execute on function public.university_news_feed(uuid[],integer,timestamptz) to authenticated;
commit;
