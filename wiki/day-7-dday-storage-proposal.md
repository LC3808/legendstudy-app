# D-Day storage proposal — NOT APPROVED / NOT APPLIED

## Gate and current behavior

2026-09-13: dedicated LegendStudy production REST projection of
`profiles.target_date,target_label` returned HTTP 400 / PostgreSQL 42703.
Both applied repository migrations lack these fields. No SQL or data mutation
was performed. Permanent D-Day storage therefore needs a schema change.
The Home editor currently stores one target only in session memory, clears on
identity changes, and explicitly discloses reset on exit/no account save.

**STOP before production application.** Product Owner approval and execution are
required. This proposal is deliberately outside `supabase/migrations/` so routine
migration deployment cannot apply an unapproved change. After approval assign a
new migration timestamp, preserving both existing applied migration files.
Project: LegendStudy / `stlhijzpjfgwwdgunlsd` only.

## Contract / impact

- `target_date date NULL`, `target_label text NULL`; both NULL or both non-NULL.
- Finite calendar dates only; label trimmed ASCII whitespace, nonempty, at most
  80 Unicode code points. Same whitespace convention as the school migration.
- No CURRENT_DATE constraint: an existing target must remain valid after its date
  passes; UI displays 지난 일정 instead of an active countdown. Future D-n and
  today D-DAY use Korean calendar-day arithmetic, not UTC elapsed hours.
- Existing rows get NULL/NULL without defaults or backfill. No fixture INSERTs.
- Extend authenticated column INSERT/UPDATE only. Existing table SELECT and
  profiles_owner_select/insert/update/delete ownership policies are reused.
  No new policy, no anon grant, no service_role change.
- Existing `id,display_name,grade_level` upserts and NEIS pair updates omit these
  columns and remain valid. School update must preserve D-Day and vice versa.
  Future D-Day repository must PATCH only the pair (or conflict upsert restricted
  to supplied columns), never null omitted profile/school fields accidentally.
- Guest has no database persistence. Authenticated persistence is NOT yet coded.

## Proposed execution SQL

Identical to `supabase/proposals/profile_day_target.sql`. **Do not execute yet.**

```sql
-- PROPOSAL ONLY: requires Product Owner approval; NOT applied.
begin;

alter table public.profiles
  add column target_date date,
  add column target_label text,
  add constraint profiles_target_pair check (
    (target_date is null) = (target_label is null)
    and (target_date is null or isfinite(target_date))
    and (
      target_label is null or (
        target_label = btrim(target_label, E' \t\n\r\f\013')
        and char_length(target_label) between 1 and 80
      )
    )
  );

grant insert (target_date, target_label),
      update (target_date, target_label)
  on public.profiles to authenticated;

notify pgrst, 'reload schema';
commit;
```

## Validation SQL (owner, after approval)

Before application, keep the following count/digest locally; repeat after. It
excludes the new fields and includes existing profile/school/timestamp values.
Use a quiet maintenance window so unrelated profile edits do not invalidate comparison.
The hash is a comparison aid, not a backup. No row content needs to be shared.

```sql
select count(*) as profile_rows,
       md5(coalesce(string_agg(
         (to_jsonb(p) - 'target_date' - 'target_label')::text,
         ',' order by p.id), '')) as existing_profile_digest
from public.profiles p;
```

After application (expect two nullable fields with date/text types, validated pair
CHECK, authenticated INSERT/UPDATE/SELECT true, anon all false; no populated targets):

```sql
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('target_date', 'target_label')
order by column_name;

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_target_pair';

select r.role_name, c.column_name,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'SELECT') as can_select,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'INSERT') as can_insert,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'UPDATE') as can_update
from (values ('anon'), ('authenticated'), ('service_role')) r(role_name)
cross join (values ('target_date'), ('target_label')) c(column_name);

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;

select count(*) as profile_rows,
       count(*) filter (where target_date is not null or target_label is not null) as populated_targets,
       count(*) filter (where (target_date is null) <> (target_label is null)) as invalid_pairs
from public.profiles;
```

Actual JWT/REST acceptance is separate; SQL Editor SET ROLE is not evidence of
ownership isolation. Reuse owner-controlled A/B test users with locally entered
passwords, no secrets in Git/Wiki/log. Before mutations securely snapshot their
profiles locally, and afterwards restore exact originals or delete only test
profiles created by this run. Retain auth users. Check:

1. A legacy profile upsert still succeeds.
2. A simultaneous target date/label save and SELECT succeed.
3. Name/grade/NEIS pair stay unchanged after target update.
4. Ordinary profile/NEIS update preserves target pair.
5. Pair clear (NULL/NULL) succeeds and preserves other fields.
6. Partial pair, empty/untrimmed/>80-character label and infinite date fail CHECK.
7. B cannot read/modify A target through actual JWT/REST; verify A unchanged.
8. Cleanup leaves no fixture residue. Flutter authenticated persistence must be
   implemented and verified separately after approval; current memory UI is not proof.

## Rollback (only if this proposal was actually applied)

First stop any client that depends on these columns and securely back up populated
target values if needed. Rollback destroys target data; does not touch school fields.
Run as owner only after rollback approval. No CASCADE; unexpected dependencies
should fail instead of silently deleting unrelated objects.

```sql
begin;
revoke insert (target_date, target_label), update (target_date, target_label)
  on public.profiles from authenticated;
alter table public.profiles
  drop constraint profiles_target_pair,
  drop column target_date,
  drop column target_label;
notify pgrst, 'reload schema';
commit;
```

## Validation status

pglast static parser PASS for the proposal (5 statements), validation queries and
rollback. Embedded execution SQL exactly matches the proposal file. This does not
substitute for PostgreSQL execution or real JWT/RLS testing.
Production application: NO. No SQL executed, no applied migration modified.
