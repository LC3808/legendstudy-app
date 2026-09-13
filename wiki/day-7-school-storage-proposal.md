# Day 7 school persistence proposal — NOT APPROVED / NOT APPLIED

## Stop and evidence

The owner's Day 7 Sections 3/22 require stopping feature implementation when school
persistence needs a schema change. The deployed initial profiles definition and
current client contract contain id/display_name/grade_level/timestamps only.
Only the immutable initial migration exists in this checkout. A read-only request
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

## Proposed new migration SQL — approval required, not executed

After approval, record this as a NEW timestamped migration. This document is not a
migration file and does not claim deployment. Explicit ADD fails on drift instead
of IF NOT EXISTS masking an incompatible prior change.

```sql
begin;

alter table public.profiles
  add column neis_office_code text,
  add column neis_school_code text,
  add constraint profiles_neis_school_pair check (
    (neis_office_code is null and neis_school_code is null)
    or (
      neis_office_code is not null and neis_school_code is not null
      and neis_office_code = btrim(neis_office_code)
      and neis_school_code = btrim(neis_school_code)
      and char_length(neis_office_code) between 1 and 32
      and char_length(neis_school_code) between 1 and 32
    )
  );

grant insert (neis_office_code, neis_school_code),
      update (neis_office_code, neis_school_code)
  on public.profiles to authenticated;

notify pgrst, 'reload schema';
commit;
```

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

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and column_name in ('neis_office_code', 'neis_school_code');
-- Expect two nullable text columns.

select convalidated, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.profiles'::regclass
  and conname = 'profiles_neis_school_pair';
-- Expect one validated pair constraint.

select role_name, column_name,
  has_column_privilege(role_name, 'public.profiles', column_name, 'SELECT') as can_read,
  has_column_privilege(role_name, 'public.profiles', column_name, 'INSERT') as can_insert,
  has_column_privilege(role_name, 'public.profiles', column_name, 'UPDATE') as can_update
from (values ('anon'), ('authenticated')) as r(role_name)
cross join (values ('neis_office_code'), ('neis_school_code')) as c(column_name);
-- anon: false/false/false; authenticated: true/true/true (RLS still applies).

select relrowsecurity from pg_class where oid = 'public.profiles'::regclass;
select policyname, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'profiles';
-- RLS true and original owner policies unchanged.

select count(*) as partial_pairs from public.profiles
where (neis_office_code is null) <> (neis_school_code is null);
-- Expect zero.
```

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

## Resume gate

Owner reviews/approves this proposal, applies a new migration, and returns deployment
and validation results. Verify those before implementing authenticated persistence.
If the owner instead authorizes guest-only school/meal work first, explicitly scope
it separately. No Day 7 feature code, production SQL/write, key embedding or new
migration file has been created by this proposal task. Day 6 link_status remains
unchanged. Day 7 is not complete; do not describe Day 8 as unconditionally ready.
