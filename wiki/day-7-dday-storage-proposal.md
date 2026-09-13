# D-Day storage — owner reports applied / JWT verification pending

Home UI through 058c3e6 is owner-approved. The owner requested the final migration
stage; production execution remains owner-only. No deployment approval is inferred
from a prepared file. No SQL or production data changes were made by Codex.

2026-09-13 read-only REST evidence from the proposal stage: target_date/target_label
projection returned 42703. Re-run the preflight below immediately before applying.
Project: LegendStudy / stlhijzpjfgwwdgunlsd only. The Home editor remains session-only.

Final migration: `supabase/migrations/20260913000200_profile_day_target.sql`.
The original `supabase/proposals/profile_day_target.sql` is retained as historical
proposal input, not a second migration to execute. SQL statements are identical;
only the proposal-status comment is omitted in the final migration.
Existing initial and school migrations remain byte-identical.

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

## Dedicated repository contract — design only, not implemented

- `fetchCurrentTarget() -> DayTarget?`: no caller-supplied user ID. Signed out returns
  null. Signed in SELECT only id,target_date,target_label WHERE id=current auth user.
  Missing row or NULL pair returns null; network/auth errors must not become success.
- `saveCurrentTarget(date, label)`: require authenticated user, normalize label,
  validate finite date/1–80 code points, serialize date as YYYY-MM-DD (no UTC timestamp).
  Single-object upsert on id containing EXACTLY id,target_date,target_label. For
  an existing profile, merge only supplied columns; for a missing row, insert the
  minimal profile. Do not serialize a whole UserProfile or copy cached school/name data.
- `clearCurrentTarget()`: authenticated PATCH WHERE id=current user with EXACTLY
  target_date:null,target_label:null. Existing profile is retained. No profile means
  idempotent no-op, never creation of an empty profile or deletion of a profile row.
- Both operations request representation/select and verify the resulting pair;
  do not mark saved on transport failures. Resolve auth identity at invocation and
  discard stale UI results if the user changes before completion.
- Existing profile upsert includes only id,display_name,grade_level; school upsert
  includes only id,neis_office_code,neis_school_code. Keep these payloads unchanged.
  The updated_at trigger may advance on client writes; business fields must not.
- No RPC/new RLS/service role required. No Flutter persistence code changes now.

## Migration SQL — one transaction, owner execution only

```sql
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

## Before application

Confirm the Dashboard project ref is stlhijzpjfgwwdgunlsd (current_database alone
cannot identify a Supabase project). Stop if either target column or profiles_target_pair
already exists, or if RLS/profiles ownership policies/grants differ from repository.
Expected existing profile fields include id,display_name,grade_level and both NEIS
codes. Keep row count/digest and policy/grant results locally, then compare after
application before allowing any client writes. Concurrent writes change the digest.

```sql
-- Run on LegendStudy stlhijzpjfgwwdgunlsd only. Keep results locally.
select current_database(), current_setting('server_version') as server_version;

select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
order by ordinal_position;

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid = 'public.profiles'::regclass
order by conname;

select relrowsecurity, relforcerowsecurity
from pg_class where oid = 'public.profiles'::regclass;

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;

select grantee, column_name, privilege_type
from information_schema.column_privileges
where table_schema = 'public' and table_name = 'profiles'
  and grantee in ('anon', 'authenticated', 'service_role')
order by grantee, column_name, privilege_type;

select count(*) as profile_rows,
       md5(coalesce(string_agg(
         (to_jsonb(p) - 'target_date' - 'target_label')::text,
         ',' order by p.id), '')) as existing_profile_digest
from public.profiles p;
```

## After application — catalog only

Expected: target_date/date and target_label/text, both nullable YES/default NULL;
profiles_target_pair exists and is validated. Authenticated SELECT/INSERT/UPDATE
true for both; anon false; service_role privileges unchanged. RLS remains enabled,
profiles ownership policy definitions unchanged. Before client tests, populated_targets
and invalid_pairs are 0; existing row count/digest match preflight.

```sql
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('target_date', 'target_label')
order by column_name;

select conname, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_target_pair';

select r.role_name, c.column_name,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'SELECT') as can_select,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'INSERT') as can_insert,
  has_column_privilege(r.role_name, 'public.profiles', c.column_name, 'UPDATE') as can_update
from (values ('anon'), ('authenticated'), ('service_role')) r(role_name)
cross join (values ('target_date'), ('target_label')) c(column_name);

select relrowsecurity, relforcerowsecurity
from pg_class where oid = 'public.profiles'::regclass;

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles'
order by policyname;

select count(*) as profile_rows,
       md5(coalesce(string_agg(
         (to_jsonb(p) - 'target_date' - 'target_label')::text,
         ',' order by p.id), '')) as existing_profile_digest,
       count(*) filter (where target_date is not null or target_label is not null) as populated_targets,
       count(*) filter (where (target_date is null) <> (target_label is null)) as invalid_pairs
from public.profiles p;
```

## Actual JWT / REST acceptance — not yet run

Use owner-controlled A/B users, passwords entered locally without shell history.
Obtain each access token through POST /auth/v1/token?grant_type=password with the
public project key. Keep passwords/tokens only in memory or secured external local
files; never print tokens or commit credentials. No service_role key.
Base URL: https://stlhijzpjfgwwdgunlsd.supabase.co.
Each REST request uses apikey:<public key>, Authorization:Bearer <A or B JWT>,
Content-Type:application/json. These are placeholders, never literal credentials.
GET projection: id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label.
Use A's actual auth uid in the examples below; B must use its own JWT.

Prefer test accounts with no profile rows. Verify this with each owner's JWT and
stop if a preexisting profile would be altered; choose owner-created clean test
accounts instead. Register only profiles created by this run for cleanup, including
uncertain network outcomes. No generic delete or auth-user deletion.

| Test | REST operation and expected evidence |
|---|---|
| Legacy profile | A POST /rest/v1/profiles?on_conflict=id, Prefer:resolution=merge-duplicates,return=representation; body id,display_name,grade_level. 2xx and owner SELECT; then save a valid school pair with existing school payload. |
| Save | Same POST with only id,target_date:"2026-10-06",target_label:"중간고사". 2xx; GET exact pair; compare name/grade/NEIS unchanged. Repeat with another label/date to verify replacement. |
| Profile preserves target | Legacy name/grade upsert only; SELECT pair unchanged. |
| School preserves target | NEIS-only upsert; SELECT target/name/grade unchanged. |
| Clear | PATCH /rest/v1/profiles?id=eq.<A_UID>, Prefer:return=representation; body target_date:null,target_label:null. 200 and one returned owner row; all other business fields unchanged. Repeating clear succeeds. Missing-profile clear returns [] as no-op. |
| Partial pair | From NULL pair send only non-NULL date, then only non-NULL label; both fail SQLSTATE 23514 (normally HTTP 400). With saved pair, setting either side alone to NULL also fails. SELECT verifies no changes. |
| Invalid label | Submit complete pairs with empty/ASCII-whitespace-only/leading-or-trailing-whitespace/81-code-point labels; 23514. Test 80-code-point trimmed label succeeds. |
| Invalid date | Complete pair using infinity/-infinity fails 23514; impossible calendar date fails PostgreSQL date parsing (not necessarily 23514). |
| Past date | Complete pair using 2000-01-01 succeeds: no >=current_date CHECK. This verifies a past date stays valid, not an active countdown. |
| Cross-user | B GET A profile returns []; B PATCH A pair with return=representation returns [] (HTTP success alone is not ownership success). B POST on_conflict=id with A id must fail RLS (normally 403 / 42501). A GET verifies unchanged. |
| Missing profile save | After deleting only this run's A fixture, save with the three-field D-Day payload creates a minimal profile; name/grade/school remain NULL; verify and clean up. |

Cleanup in a finally block: DELETE /rest/v1/profiles?id=eq.<own_uid> with the
corresponding owner's JWT, only for profiles confirmed absent before this run.
Verify own GET returns []; retain Auth users. Do not reuse tool/verify_school_jwt.py
as D-Day evidence: it tests the school contract only. SQL Editor SET ROLE is not
an alternative to these real JWT/REST checks. Flutter authenticated persistence
remains unimplemented and must be separately verified after migration acceptance.

## Rollback — owner only, after rollback approval

Stop dependent clients first. Securely export target data if populated; rollback
permanently removes those two fields. Keep profile/school/name/grade rows intact.
No CASCADE: unexpected dependencies must fail rather than remove unrelated objects.

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

## Static validation

pglast parser: migration, preflight, catalog and rollback PASS. Embedded SQL/file
identity and existing migration byte equality checked. No CURRENT_DATE constraint,
new RLS policy, anon grant, DML, or secret value in the migration. git diff --check
PASS. Static checks are not production execution or JWT/RLS acceptance evidence.

References: [PostgreSQL CHECK semantics](https://www.postgresql.org/docs/17/ddl-constraints.html),
[PostgREST REST/upsert](https://docs.postgrest.org/en/v14/references/api/tables_views.html).


## Owner application report / implementation gate released

Owner confirms production execution of the final migration and all supplied
pre/post queries: two nullable date/text fields, pair CHECK, profile_rows 0→0,
unchanged digest, populated_targets=0 and invalid_pairs=0. Codex did not apply SQL.
The DB STOP is released; next gate is actual JWT/REST PASS before Flutter changes.
Dedicated tool/verify_day_target_jwt.py is prepared with hidden interactive password
entry or an external account JSON. Uses owner-specified A/B @legendstudy.com accounts,
refuses preexisting profiles and cleans only its fixtures; no Auth users deleted.
Actual execution and persistence runtime remain pending, not PASS.
