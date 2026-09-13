# Day 7 school persistence — OWNER REPORTS DEPLOYED / CLIENT ACCEPTANCE PENDING

## Current deployment evidence

On 2026-09-13 the owner reported successful production execution of the exact
prepared migration and verified text/nullable columns, validated CHECK, authenticated
column privileges, no anon access, four unchanged owner policies and zero profiles/
partial pairs/non-null school rows. Owner lifted the implementation STOP. Codex did
not execute production SQL. The historical preflight/proposal below records the
pre-deployment decision; current implementation and remaining JWT/NEIS acceptance
are in current-status.md, database.md and day-7-neis.md.

## Historical stop and evidence

The owner's Day 7 Sections 3/22 require stopping feature implementation when school
persistence needs a schema change. The deployed initial profiles definition and
current client contract contain id/display_name/grade_level/timestamps only.
At the STOP checkpoint, only the immutable initial migration existed in this checkout. A read-only request
for proposed neis_office_code/neis_school_code returned HTTP 400 / PostgreSQL 42703
(undefined column) on the dedicated LegendStudy project. No SQL was executed.

The official [NEIS school dataset](https://open.neis.go.kr/portal/data/service/selectServicePage.do?infId=OPEN17020190531110010104913&infSeq=2)
identifies school information and requires a key for actual use; unauthenticated
responses are limited samples. A read-only schoolInfo sample for 진접고등학교 returned
one row containing ATPT_OFCDC_SC_CODE, SD_SCHUL_CODE, SCHUL_NM, SCHUL_KND_SC_NM,
ORG_RDNMA. This confirms identity field names, not production key exposure approval
or a completed school/meal smoke. Meal API, key exposure and terms review remain pending.

## Minimum proposal

Add two nullable text columns to profiles (no school master or new relation):

- neis_office_code: NEIS ATPT_OFCDC_SC_CODE.
- neis_school_code: NEIS SD_SCHUL_CODE.

Persist only the pair. School name/type/address are refreshed from NEIS by these
identifiers and kept in memory; no duplicated school catalogue or permanent guest
cache. Both NULL means no saved school. Both non-NULL means a selected identifier
pair; the CHECK validates shape only, not existence in NEIS. Accept only a selected
NEIS search result in the later UI; failed lookup must allow reselection.

No new profile is mandatory for existing users. A later school save can upsert
id plus the pair, deriving id from the current authenticated Supabase session.
No owner parameter from UI. Do not implement that repository before approval and
verified deployment. School save/clear must preserve display_name/grade_level;
existing profile edits must preserve the school pair. Tests must verify both.

## Owner preflight — read-only, not executed here

Confirm target project stlhijzpjfgwwdgunlsd, backup policy and no conflicting columns/
constraint before applying. Do not replay the initial migration.

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
order by ordinal_position;

select conname, pg_get_constraintdef(oid)
from pg_constraint where conrelid = 'public.profiles'::regclass;

select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles';
```

## Final prepared migration — owner execution only

Owner approved the two-column direction. Prepared file:
`supabase/migrations/20260913000100_profile_school_selection.sql`.
The owner now reports it applied; the block remains byte-identical to the migration file.
Explicit ADD fails on drift rather than silently skipping incompatible columns.

Official sample rechecked: 진접고등학교 returned office J10 and school 7530932.
Those are examples, not a guarantee of a universal pattern. No code-format regex
is imposed. Maximum 32 characters is an application defensive bound, NOT a claimed
NEIS specification. Values must be nonempty with no leading/trailing ASCII whitespace;
the pair is either fully NULL or fully present. School existence is not DB-validated.

```sql
begin;

alter table public.profiles
  add column neis_office_code text,
  add column neis_school_code text,
  add constraint profiles_neis_school_pair check (
    (neis_office_code is null) = (neis_school_code is null)
    and (
      neis_office_code is null or (
        neis_office_code = btrim(neis_office_code, E' \t\n\r\f\013')
        and char_length(neis_office_code) between 1 and 32
      )
    )
    and (
      neis_school_code is null or (
        neis_school_code = btrim(neis_school_code, E' \t\n\r\f\013')
        and char_length(neis_school_code) between 1 and 32
      )
    )
  );

grant insert (neis_office_code, neis_school_code),
      update (neis_office_code, neis_school_code)
  on public.profiles to authenticated;

notify pgrst, 'reload schema';
commit;
```

## Existing row comparison

Run `supabase/review/profile_school_before.sql` before application and retain the
count/fingerprint. After application, run `supabase/review/profile_school_after.sql`
and compare the same original-column fingerprint. Prevent concurrent profile writes
while comparing. This avoids printing raw profile data; no baseline means no claim
of proven row preservation. New fields should be NULL immediately after migration.

## RLS and compatibility

Existing owner policies remain: SELECT/DELETE USING auth.uid()=id, INSERT WITH CHECK
and UPDATE USING/WITH CHECK auth.uid()=id. No anon privilege, no new policy, no
service-role client use. Existing authenticated table-level SELECT automatically
covers added columns, still constrained by owner RLS. Existing id INSERT/UPDATE
privileges are retained. updated_at continues using the existing trigger.

Old explicit projections/payloads remain valid because new columns are nullable
with NULL defaults. No backfill, no profile/grade/name changes and no school fixtures.
A future clear sets both fields NULL; deleting the entire profile is not school clear.

## Owner validation after application — not executed here

Exact queries: `supabase/review/profile_school_after.sql`. Checks cover two nullable
TEXT columns/defaults, validated CHECK, existing/new column privileges for anon,
authenticated and service_role, unchanged owner RLS, zero partial pairs, original
row count/fingerprint and initially NULL school values. SQL parsing is not execution.

Separately authorize owner-run REST/JWT behavioral checks; catalogue privileges or
SQL SET ROLE alone do not prove RLS. No production fixture writes are authorized here:

- Guest cannot persist; no automatic login. In-memory guest selection is not saved.
- A reads/saves/clears own pair; B cannot read/update A; spoofed owner insert denied.
- One NULL, blank and overlong pairs rejected; both NULL accepted.
- School upsert preserves profile name/grade and vice versa, including a user with
  no profile row. Auth change/sign-out clears prior user's in-memory personal state.

## Rollback — owner approval required

Stop deploying the new client contract first. Dropping columns destroys saved school
selections: export/retain any real preferences under the owner's data policy before
rollback. Existing profile fields and owner policies are preserved. Use a separate
rollback migration after deployment; never rewrite applied history.

```sql
begin;
revoke insert (neis_office_code, neis_school_code),
       update (neis_office_code, neis_school_code)
  on public.profiles from authenticated;
alter table public.profiles
  drop constraint profiles_neis_school_pair,
  drop column neis_office_code,
  drop column neis_school_code;
notify pgrst, 'reload schema';
commit;
```

## Historical resume gate (superseded by owner deployment report above)

The storage direction is approved, and the executable migration is now prepared.
The owner applies it to LegendStudy and returns before/after validation results.
Verify deployment before implementing authenticated persistence. The new file's
existence does not imply deployment. Flutter implementation remains stopped; NEIS
key exposure and meal API verification remain subsequent gates. No production SQL,
write, push, PR or merge was performed. Initial migration and database.md unchanged.


## Static verification of prepared files

`python supabase/review/check_school_storage.py` with review/requirements.txt:
pglast 8.4 (PostgreSQL 18.4 grammar) parses the migration and SELECT-only verification
scripts, checks nullable columns/CHECK/column grants and transaction scope, ensures
owner SQL byte identity and the immutable initial hash, and rejects five unsafe
mutations. Existing initial-schema checker and its 14 tests also pass. No PostgreSQL
execution or production catalogue/JWT behavior is claimed; target remains PG17.6.
Flutter code and dependencies are unchanged; builds/tests were not rerun for SQL-only
preparation. git diff --check and credential scanning pass.
