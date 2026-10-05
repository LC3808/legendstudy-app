-- APP-RELEASE-BLOCKER-CLOSEOUT-1 — Apple revoke material (additive, worker-only).
--
-- Companion to 20261001000300_account_deletion_lifecycle. Adds a single private,
-- worker-only store for provenance-bound Apple revoke tokens plus two SECURITY DEFINER
-- RPCs, so the deletion worker's PROVIDER phase can revoke Sign in with Apple grants.
-- Dormant until the worker runs; the client never touches this material. Erasure never
-- depends on it (a missing/failed revoke is retained as unknown, never faked).
--
-- NOT APPLIED. Owner staged apply required (after 20261001000300). It does not alter any
-- existing ADR-2 object; it only adds one table, two functions and their grants.

begin;

create table if not exists account_private.provider_revocation_material(
  subject_id uuid primary key references auth.users(id) on delete cascade,
  provider text not null check(provider in ('apple')),
  token text not null,
  token_type text not null check(token_type in ('refresh_token','access_token')),
  captured_at timestamptz not null default clock_timestamp()
);
alter table account_private.provider_revocation_material enable row level security;
revoke all on table account_private.provider_revocation_material from public,anon,authenticated,service_role;

-- Trusted server (worker role) stores a subject's Apple revoke token, captured during a
-- fresh Apple reauthentication. Overwrites any prior token for that subject.
create or replace function public.account_store_apple_revocation(p_subject uuid,p_token text,p_token_type text)
returns void language plpgsql security definer set search_path='' as $$
begin
  if p_subject is null or coalesce(p_token,'')='' or p_token_type not in ('refresh_token','access_token') then
    raise invalid_parameter_value using message='INVALID_PROVIDER_MATERIAL';
  end if;
  insert into account_private.provider_revocation_material(subject_id,provider,token,token_type)
  values(p_subject,'apple',p_token,p_token_type)
  on conflict(subject_id) do update
    set provider='apple',token=excluded.token,token_type=excluded.token_type,captured_at=clock_timestamp();
end;$$;

-- Trusted server (worker role) reads a subject's revoke material for an ERASING request,
-- lease-fenced via the existing ADR-2 fence. NULL when none is stored. The row is removed
-- by the auth.users FK cascade once the AUTH phase deletes the subject.
create or replace function public.account_provider_material(p_id uuid,p_token uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests; m account_private.provider_revocation_material;
begin
  r=account_private.fenced(p_id,p_token);
  select * into m from account_private.provider_revocation_material where subject_id=r.subject_id;
  if m.subject_id is null then return null; end if;
  return jsonb_build_object('provider',m.provider,'token',m.token,'token_type',m.token_type);
end;$$;

revoke all on function public.account_store_apple_revocation(uuid,text,text) from public,anon,authenticated,service_role;
revoke all on function public.account_provider_material(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.account_store_apple_revocation(uuid,text,text) to account_lifecycle_worker;
grant execute on function public.account_provider_material(uuid,uuid) to account_lifecycle_worker;

commit;
