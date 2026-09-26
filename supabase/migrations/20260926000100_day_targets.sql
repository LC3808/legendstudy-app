-- Multi D-Day: owner-scoped event collection with a single chosen primary.
-- Additive only. profiles.target_date/target_label are preserved (not dropped)
-- and their existing single value is backfilled as each owner's primary event.
begin;

create table public.day_targets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (
    title = btrim(title, E' \t\n\r\f\013')
    and char_length(title) between 1 and 80
  ),
  event_date date not null check (isfinite(event_date)),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Owner + soonest-date lookups for the Home projection.
create index day_targets_owner_date on public.day_targets (owner_id, event_date);
-- At most one primary per owner, enforced by the database.
create unique index day_targets_one_primary
  on public.day_targets (owner_id) where is_primary;

alter table public.day_targets enable row level security;

-- Only the owner may read or write their own events.
create policy day_targets_owner_select on public.day_targets
  for select to authenticated using (owner_id = auth.uid());
create policy day_targets_owner_insert on public.day_targets
  for insert to authenticated with check (owner_id = auth.uid());
create policy day_targets_owner_update on public.day_targets
  for update to authenticated using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
create policy day_targets_owner_delete on public.day_targets
  for delete to authenticated using (owner_id = auth.uid());

grant select, insert, update, delete on public.day_targets to authenticated;

-- Backfill: preserve every existing single D-Day as that owner's primary event.
-- Guarded so a re-run never creates a duplicate primary.
insert into public.day_targets (owner_id, title, event_date, is_primary)
select p.id, p.target_label, p.target_date, true
from public.profiles p
where p.target_date is not null
  and p.target_label is not null
  and not exists (
    select 1 from public.day_targets d where d.owner_id = p.id
  );

notify pgrst, 'reload schema';
commit;
