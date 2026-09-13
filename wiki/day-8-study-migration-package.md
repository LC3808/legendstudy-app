# Day 8 Study — Product Owner 실행 패키지

설계 승인 완료. **Production 미적용.** 대상은 LegendStudy / `stlhijzpjfgwwdgunlsd`입니다.
아래 각 단계는 파일 전체와 동일한 단일 SQL 블록입니다. Dashboard 프로젝트를
확인하고 1번 결과가 예상과 일치할 때만 2번, 그 다음 3번을 실행합니다.
4번 rollback은 데이터 손실을 수반하므로 필요할 때 별도 판단 후에만 실행합니다.
Migration과 proposal mirror를 둘 다 실행하지 마세요.

예상 결과·권한·실제 JWT acceptance·집계 계약은
[최종 저장 계약](day-8-study-storage-proposal.md)에 있습니다.
Catalog 검증은 실제 사용자 JWT/RLS 검증을 대신하지 않습니다.

## 1. 적용 전 read-only SQL

원본: [study_sessions_preflight.sql](../supabase/verification/study_sessions_preflight.sql)

```sql
-- READ ONLY. Owner: confirm Dashboard project stlhijzpjfgwwdgunlsd first.
-- Expected: no proposed objects; three auth roles; auth.users/auth.uid exist.
begin transaction read only;
set local timezone = 'UTC';
select current_database(), current_user, version();
select to_regclass('public.study_sessions') as must_be_null,
       to_regprocedure('public.study_active_milliseconds(jsonb,numeric)') as must_be_null_function,
       to_regclass('auth.users') as auth_users,
       to_regprocedure('auth.uid()') as auth_uid;
select rolname, rolbypassrls from pg_roles
where rolname in ('anon','authenticated','service_role') order by rolname;
select has_schema_privilege(current_user, 'public', 'CREATE') as can_create,
 has_table_privilege(current_user, 'auth.users', 'REFERENCES') as can_reference_users;
-- Generated expression primitives must be immutable (provolatile = i).
select oid::regprocedure as function, provolatile from pg_proc
where oid in ('pg_catalog.timestamptz_mi(timestamptz,timestamptz)'::regprocedure,
              'pg_catalog.extract(text,interval)'::regprocedure);
-- Capture privately, then repeat exactly after deployment. No profile contents printed.
select count(*) as profile_rows,
       md5(coalesce(string_agg(to_jsonb(p)::text, '' order by id), '')) as profile_digest
from public.profiles p;
select column_name, data_type, is_nullable from information_schema.columns
where table_schema='public' and table_name='profiles'
order by ordinal_position;
select conname, convalidated, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.profiles'::regclass order by conname;
select grantee, column_name, privilege_type from information_schema.column_privileges
where table_schema='public' and table_name='profiles' order by 1,2,3;
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname='public' and tablename='profiles' order by policyname;
-- Baseline for all existing public tables: compare the same ordered metadata after.
select c.relname, c.relrowsecurity, c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid), '|' order by k.conname), ''))
  from pg_constraint k where k.conrelid=c.oid) as constraint_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
 and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects',
 'resources','profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname;
commit;
```

## 2. Migration 전체 SQL

원본: [20260914000100_study_sessions.sql](../supabase/migrations/20260914000100_study_sessions.sql)

```sql
-- Owner-approved Day 8 contract; production application pending.
-- Completed sessions only; cancelled/running/paused records remain local.
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
    duration_seconds >= 1
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
grant insert (id, mode, title, subject, planned_duration_seconds,
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
```

## 3. 적용 후 catalog SQL

원본: [study_sessions_catalog.sql](../supabase/verification/study_sessions_catalog.sql)

```sql
-- READ ONLY; only after approved owner deployment. Not JWT/RLS acceptance.
begin transaction read only;
set local timezone = 'UTC';
select column_name, data_type, is_nullable, column_default, is_generated, generation_expression
from information_schema.columns where table_schema='public' and table_name='study_sessions'
order by ordinal_position;
select conname, contype, convalidated, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.study_sessions'::regclass order by conname;
select indexname, indexdef from pg_indexes
where schemaname='public' and tablename='study_sessions';
select relrowsecurity, relforcerowsecurity from pg_class
where oid='public.study_sessions'::regclass;
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname='public' and tablename='study_sessions' order by policyname;
select grantee, column_name, privilege_type from information_schema.column_privileges
where table_schema='public' and table_name='study_sessions' order by 1,2,3;
select r, has_table_privilege(r, 'public.study_sessions','SELECT') as can_select,
 has_table_privilege(r, 'public.study_sessions','UPDATE') as can_update,
 has_table_privilege(r, 'public.study_sessions','DELETE') as can_delete,
 has_column_privilege(r, 'public.study_sessions','id','INSERT') as can_insert_id,
 has_column_privilege(r, 'public.study_sessions','duration_seconds','INSERT') as can_insert_duration,
 has_column_privilege(r, 'public.study_sessions','user_id','INSERT') as can_insert_owner,
 has_column_privilege(r, 'public.study_sessions','created_at','INSERT') as can_insert_created,
 has_function_privilege(r, 'public.study_active_milliseconds(jsonb,numeric)','EXECUTE') as can_derive
from unnest(array['anon','authenticated','service_role']) r;
select proname, provolatile, prosecdef, proconfig from pg_proc
where oid='public.study_active_milliseconds(jsonb,numeric)'::regprocedure;
select count(*) as study_rows from public.study_sessions; -- expected 0 before acceptance
select count(*) as profile_rows,
 md5(coalesce(string_agg(to_jsonb(p)::text, '' order by id), '')) as profile_digest
from public.profiles p; -- must match preflight; repeat preflight profile catalog queries too
-- Pure calculation example: 60 s active, 60 s paused, 60 s active = 120000 ms.
select public.study_active_milliseconds('[[0,60000],[120000,180000]]'::jsonb,180000)
 = 120000 as interval_example_pass;

select column_name, data_type, is_nullable from information_schema.columns
where table_schema='public' and table_name='profiles'
order by ordinal_position;
select conname, convalidated, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.profiles'::regclass order by conname;
select grantee, column_name, privilege_type from information_schema.column_privileges
where table_schema='public' and table_name='profiles' order by 1,2,3;
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname='public' and tablename='profiles' order by policyname;
-- Baseline for all existing public tables: compare the same ordered metadata after.
select c.relname, c.relrowsecurity, c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid), '|' order by k.conname), ''))
  from pg_constraint k where k.conrelid=c.oid) as constraint_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
 and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects',
 'resources','profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname;
commit;
```

## 4. Rollback SQL — 평상시 실행하지 않음

원본: [study_sessions_rollback.sql](../supabase/verification/study_sessions_rollback.sql)

```sql
-- OWNER APPROVAL REQUIRED. DESTRUCTIVE to Study history; never run automatically.
-- Stop Study writes/retries on clients first; export/back up study_sessions.
-- Confirm no downstream dependencies. Intentionally no CASCADE.
begin;
drop table public.study_sessions;
drop function public.study_active_milliseconds(jsonb, numeric);
notify pgrst, 'reload schema';
commit;
-- No auth users, profiles, existing policies, migrations or Day 7 data touched.
```
