-- REVIEWED A-ONLY PROPOSAL. NOT APPLIED. Requires separate Owner approval.
-- Replaces only the un-applied HOME portion of 37eb530, not an incremental patch.
-- Do NOT also run the original combined candidate.sql. Run preflight first.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
do $guard$
begin
  if to_regclass('public.home_configuration_revisions') is not null
    or to_regprocedure('public.my_home_configuration()') is not null
    or to_regprocedure('public.save_my_home_configuration(jsonb,bigint)') is not null then
    raise exception 'HOME_OBJECTS_ALREADY_EXIST: stop and review, do not overwrite';
  end if;
  if md5(pg_get_functiondef(to_regprocedure('account_private.allowed(uuid)'))) is distinct from '5bb28e0026f17746239e4369a772a5ce'
    or md5(pg_get_functiondef(to_regprocedure('account_private.lock_subject(uuid)'))) is distinct from 'e48a7203c22b570c80e65ed51a7d20c9'
    or to_regprocedure('public.account_service_allowed()') is null then
    raise exception 'ACCOUNT_LIFECYCLE_DRIFT: compare current live definitions before approval';
  end if;
end;
$guard$;
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
  for select to authenticated using (user_id = (select auth.uid()) and (select public.account_service_allowed()));
revoke all on public.home_configuration_revisions from public, anon, authenticated;
-- Only the RPC can read/write. Historical revisions are not client-writable.
create function public.my_home_configuration() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare v_result jsonb;
begin
  if not account_private.allowed(auth.uid()) then raise insufficient_privilege; end if;
  select jsonb_build_object('config_version', config_version, 'cards', cards, 'revision', revision, 'updated_at', updated_at) into v_result
  from public.home_configuration_revisions where user_id = auth.uid() order by revision desc limit 1;
  return v_result;
end;
$$;
create function public.save_my_home_configuration(p_config jsonb, p_revision bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare v_owner uuid := auth.uid(); v_current jsonb; v_card jsonb; v_ids text[] := '{}'; v_revision bigint;
begin
  if v_owner is null then raise exception 'Authentication required' using errcode='28000'; end if;
  -- Same lock order as the existing account lifecycle: subject, then home.
  perform account_private.lock_subject(v_owner);
  if not account_private.allowed(v_owner) then raise insufficient_privilege; end if;
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

commit;
