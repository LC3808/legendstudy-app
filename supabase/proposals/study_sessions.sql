-- PROPOSAL ONLY, NOT DEPLOYED. Product Owner approval/application required.
-- Keep outside migrations until approved; suggested future filename:
-- 20260914000100_study_sessions.sql (reconfirm timestamp before promotion).
begin;

-- Pure bounded validation/derivation, no table access or elevated privileges.
create function public.study_active_milliseconds(p_segments jsonb, p_span_ms numeric)
returns bigint
language plpgsql immutable security invoker
set search_path = ''
as $$
declare
  segment jsonb;
  start_ms numeric;
  end_ms numeric;
  previous_end numeric := 0;
  total_ms bigint := 0;
begin
  if p_span_ms is null or not (p_span_ms between 0 and 86400000)
     or p_segments is null or jsonb_typeof(p_segments) <> 'array' then
    raise exception 'Invalid study interval payload' using errcode = '23514';
  end if;
  if jsonb_array_length(p_segments) > 256 then
    raise exception 'Too many study intervals' using errcode = '23514';
  end if;
  for segment in select value from jsonb_array_elements(p_segments) loop
    if jsonb_typeof(segment) <> 'array' then
      raise exception 'Invalid study interval shape' using errcode = '23514';
    end if;
    if jsonb_array_length(segment) <> 2
       or jsonb_typeof(segment -> 0) <> 'number'
       or jsonb_typeof(segment -> 1) <> 'number' then
      raise exception 'Invalid study interval shape' using errcode = '23514';
    end if;
    start_ms := (segment ->> 0)::numeric;
    end_ms := (segment ->> 1)::numeric;
    if start_ms <> trunc(start_ms) or end_ms <> trunc(end_ms)
       or start_ms < previous_end or end_ms <= start_ms
       or end_ms > p_span_ms then
      raise exception 'Invalid study interval bounds' using errcode = '23514';
    end if;
    total_ms := total_ms + (end_ms - start_ms)::bigint;
    previous_end := end_ms;
  end loop;
  return total_ms;
end;
$$;

create table public.study_sessions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  mode text not null,
  status text not null,
  title text,
  subject text,
  planned_duration_seconds integer,
  started_at timestamptz not null,
  ended_at timestamptz not null,
  active_segments jsonb not null,
  duration_seconds integer generated always as (
    (public.study_active_milliseconds(
      active_segments, extract(epoch from (ended_at - started_at)) * 1000
    ) / 1000)::integer
  ) stored not null,
  created_at timestamptz not null default now(),
  constraint study_sessions_mode check (mode in ('study', 'mock_exam')),
  constraint study_sessions_status check (status in ('completed', 'cancelled')),
  constraint study_sessions_time_bounds check (
    isfinite(started_at) and isfinite(ended_at)
    and ended_at >= started_at
    and ended_at - started_at <= interval '24 hours'
  ),
  constraint study_sessions_title check (
    title is null or (title = btrim(title, E' \t\n\r\f\013')
      and char_length(title) between 1 and 80)
  ),
  constraint study_sessions_subject check (
    subject is null or (subject = btrim(subject, E' \t\n\r\f\013')
      and char_length(subject) between 1 and 40)
  ),
  constraint study_sessions_mode_fields check (
    (mode = 'study' and planned_duration_seconds is null)
    or (mode = 'mock_exam' and title is not null
      and planned_duration_seconds is not null
      and planned_duration_seconds between 60 and 43200)
  ),
  constraint study_sessions_duration check (
    duration_seconds >= 0 and (status <> 'completed' or duration_seconds >= 1)
    and (mode <> 'mock_exam' or public.study_active_milliseconds(
      active_segments, extract(epoch from (ended_at - started_at)) * 1000
    ) <= planned_duration_seconds::bigint * 1000)
  )
);

create index study_sessions_owner_started_idx
  on public.study_sessions (user_id, started_at desc, id desc);

alter table public.study_sessions enable row level security;
revoke all on table public.study_sessions from public, anon, authenticated;
revoke all on function public.study_active_milliseconds(jsonb, numeric)
  from public, anon, authenticated;
grant execute on function public.study_active_milliseconds(jsonb, numeric)
  to authenticated, service_role;
grant select, delete on table public.study_sessions to authenticated;
grant insert (id, mode, status, title, subject, planned_duration_seconds,
  started_at, ended_at, active_segments) on public.study_sessions to authenticated;
grant select, insert, update, delete on table public.study_sessions to service_role;

create policy study_sessions_owner_select on public.study_sessions
  for select to authenticated using ((select auth.uid()) = user_id);
create policy study_sessions_owner_insert on public.study_sessions
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy study_sessions_owner_delete on public.study_sessions
  for delete to authenticated using ((select auth.uid()) = user_id);

notify pgrst, 'reload schema';
commit;
