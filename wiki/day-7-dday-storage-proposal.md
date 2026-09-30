# D-Day storage — production applied / JWT and Flutter runtime PASS

## ACL security correction — PRODUCTION VERIFIED / RESOLVED — 2026-09-30

**DAY_TARGETS_SECURITY_FINDING=RESOLVED; PRODUCTION_APPLY=OWNER_APPLIED;
LEAST_PRIVILEGE_END_STATE=VERIFIED.** Owner applied the prepared SQL directly.
Codex reverified Production read-only at2026-09-30 13:55:02 UTC:
anon has no table privileges; authenticated has CRUD only; TRUNCATE/TRIGGER/
REFERENCES/MAINTAIN absent. Table exists/RLS enabled; all4 owner policies,
postgres ownership/service ACL, schema grants and defaults unchanged. No column
ACL or client-role inheritance bypass found. All other43 public relations (42 tables
and1 view) match the historical catalog, including ACLs/policies/structure.
[After evidence](../supabase/verification/day_targets_acl_after_20260930.json).
No Production row mutation or destructive test was performed by Codex.

**SQL application ≠ migration tracking.** Remote ledger still has21 versions:
`20260930000100` is **not registered**, although its exact least-privilege effect is
verified. Tracking discrepancy is reported, not silently repaired. Owner should
reconcile this exact version through the approved migration-history workflow;
no agent repair/update was performed. Provider005 remains NOT_APPLIED/unregistered;
do not use an unfiltered db push to close the tracking gap. Migration SQL is unchanged.
Architecture remains **HEALTHY_WITH_DEBT**; broad default privilege follow-up and
other architecture debt remain open. Owner clarifications and Cross Review A are preserved.

### Preparation evidence (before Owner application)

[Cross Review A](platform-architecture-health-review-a.md)의 HIGH finding을 별도로 재검증했다.
Live PostgreSQL17.6, 2026-09-30 13:33:27 UTC: postgres owner, RLS ON/force OFF,
owner CRUD policies4개. anon/authenticated/service_role 모두 CRUD + TRUNCATE +
TRIGGER + REFERENCES + MAINTAIN. PUBLIC table grant는 없으며 public schema USAGE는 존재한다.
[Sanitized before metadata](../supabase/verification/day_targets_acl_before_20260930.json).

**ROOT_CAUSE: mechanism VERIFIED / historical origin LIKELY.** 현재 postgres/public
default table ACL은 application roles에 ALL을 부여한다. 원 migration의 GRANT CRUD는
additive이고 REVOKE가 없어 default 과다 권한을 제거하지 않는다. 같은 default와 실제
원 migration을 isolated PostgreSQL17에서 재생해 동일 과다 권한을 재현했다. 당시 생성
시점 default ACL audit log는 없으므로 모든 과거 grant 경로까지 확정하지 않는다.
실제 exploit path를 증명하지 않았으며 Production 파괴/공격 테스트는 없다.

### Minimum end state

| Role | BEFORE live | AFTER Production verified |
|---|---|---|
| anon / PUBLIC | anon ALL / PUBLIC none | none |
| authenticated | ALL (8 privileges, including MAINTAIN) | SELECT, INSERT, UPDATE, DELETE only |
| postgres owner / service_role | ALL | unchanged |

`SupabaseDayEventRepository` uses only CRUD and requires currentUser for writes.
Signed-out fetch returns empty without querying DB. `DayEventsController` keeps guest
changes in session memory; auth-loading/errors do not dispatch writes; login never
uploads guest events. Signup/onboarding has no anonymous day_targets write requirement.
Thus anon table grants are unnecessary. Owner four RLS policies and semantics remain unchanged.

[Migration](../supabase/migrations/20260930000100_day_targets_least_privilege.sql)
revokes ALL only on day_targets from PUBLIC/anon/authenticated, then grants authenticated
CRUD. REVOKE ALL includes MAINTAIN on17; no global default ACL, schema, owner, service,
column, data or RLS change. No CASCADE. Short lock/statement timeouts; atomic transaction;
reapplying has identical ACL end state. Existing primary-target atomicity/legacy cleanup
remain separate debts.

### Owner application gate and rollback

**Historical preparation state was MIGRATION_READY_NOT_APPLIED.** Owner has now applied
the SQL and Codex verified it above. AGENTS.md §4 still assigns Production apply to Owner.
The following preflight/rollback instructions remain reference guidance, not a pending
request to reapply SQL. Before any separately approved application, run
[read-only catalog verification](../supabase/verification/day_targets_acl.sql), check no
new role inheritance/column grants or policy drift, and preserve its output. Execute only
this migration under normal migration ownership. Do **not** run an unfiltered `supabase db push`:
older provider005 is still pending and is outside this authorization. Record this migration
in the approved deployment ledger workflow only after successful execution; do not mark
unapplied005 as applied.

After apply, repeat the same catalog verification: effective anon privileges all false;
authenticated CRUD true, other4 false; owner/service ACL and policies identical; unrelated
ACL/defaults unchanged. Production CRUD tests are not needed to destroy/recreate user rows.
Actual owner device/JWT smoke can be separately confirmed through normal safe workflow.

On SQL failure the transaction rolls back automatically; no data rollback is needed. Do not
automatically restore insecure ALL grants as rollback. If a legitimate consumer fails, stop
rollout, inspect exact required operation/role, and obtain Owner approval for a narrow grant.
The before snapshot is evidence, not an instruction to reintroduce excessive privileges.

### Regression and follow-up

Validation results: isolated PostgreSQL17 security regression PASS; live effective privilege
pre-apply preflight recorded both client roles with8 grants and no column grants/client role
inheritance. That historical NOT_APPLIED state is superseded by the Production verification above. Existing Flutter D-Day tests were attempted but
stopped before execution because this local SDK requires native-assets enablement for
objective_c/pdfium_dart. No SDK/global setting or unrelated package change was made;
guest/auth client behavior was reviewed statically. Wiki links, migration scope, secret
scan and frozen/private preservation checks are part of this handoff.

`python3 tool/test_day_targets_acl.py --pg-bin /opt/homebrew/opt/postgresql@17/bin`
creates a disposable local Unix-socket-only PostgreSQL17 cluster, reproduces default ACLs,
applies the original and new migrations, and tests owner CRUD, foreign SELECT/UPDATE/DELETE
isolation, forged-owner INSERT/UPDATE rejection, anon CRUD denial, all4 excess privilege
removal, service CRUD, unchanged RLS/owner/service/unrelated/default ACLs and idempotency.
No Production rows or provider calls. Static migration scope and existing Flutter D-Day
regression are validated separately; no Flutter code/build changes.

**FOLLOW_UP_SECURITY_DEBT:** broad default ACLs for future public tables remain. A read-only
pre-apply scan found day_targets as the only public table with these client excess grants;
post-apply scan finds none. The broad defaults themselves remain unchanged.
Other migrations must explicitly restrict client ACLs. Global defaults and other tables are
not fixed here; a separate approved security review must decide that policy. Architecture
health remains HEALTHY_WITH_DEBT; historical Cross Review A is unchanged.

## Multi D-Day — IMPLEMENTED / Production applied — 2026-09-26

Multi D-Day is now implemented as an owner-scoped event collection
(`public.day_targets`: id, owner_id→auth.users, title, event_date, is_primary),
migration `20260926000100_day_targets.sql`. RLS restricts SELECT/INSERT/UPDATE/
DELETE to `owner_id = auth.uid()`; a partial unique index `(owner_id) where
is_primary` keeps at most one representative per owner. Owner applied the
migration to Production 2026-09-26; the 2 existing single D-Days were backfilled
as primary events (backfill_missing=0, no multi-primary, no null owner), and the
legacy `profiles.target_date/target_label` columns are preserved. The user chooses
one representative (radio); Home shows it (or nearest upcoming as a display-only
fallback) plus a compact upcoming list. Guests remain session-memory only.
Owner reports final device UX acceptance PASS. A full Calendar view remains PLANNED.

### Owner device follow-up — 2026-09-27 (OWNER DEVICE PASS)

First device pass: all tested functions PASS (legacy preserved, weekday date,
add, multiple events, representative select/change incl. a far event, Home
representative, compact list, more/less, edit, relaunch persistence, no overflow)
except **event deletion FAIL** — the delete-confirm modal's 취소/삭제 buttons were
unresponsive on device.

Follow-up applied (code, no DB/schema change):
- Delete-confirm fix: the confirm dialog now pops via its **own** context (was
  the captured sheet context, which could be stale after a rebuild → unresponsive
  buttons). 취소 keeps the event; 삭제 does a confirmed delete; failure keeps the
  sheet open; primary delete falls back to nearest upcoming.
- Representative is now a single strong row `📅 title · date(요일)  D-N` with 설정
  trailing (the separate large hero D-N row was removed); wraps at small/large text.
- D-Day accent uses the clear blue `AppTokens.info` (icon + D-N emphasis), not the
  previous brownish ink; primary text uses `AppTokens.textPrimary` (Deep Navy).
- App title limit reduced to **20 code points** (domain/form/decode); the Production
  `day_targets.title` check stays at 80 (no DB change). Compact list keeps the
  trailing D-N alignment. Date format `YYYY.MM.DD.(요일)` unchanged.

Delete re-check on device: **DELETE OWNER DEVICE PASS** (cancel + actual delete
both work). Final micro-polish (2026-09-27): app title limit 20 → **15** code
points (domain/form/decode-clamp; DB stays 80, no migration); representative D-N
enlarged one point (18 → **19sp**), nothing else changed. Final visual device
check (15-char limit + representative D-N size) is Owner PASS, as supplied in the
Wave1 handoff; all CRUD/representative/persistence/compact/expand-collapse accepted.

### Original direction note (2026-09-25, superseded by the above)

The next product direction is a collection of user-owned events; Home emphasizes
the representative or nearest event; a future Calendar may expose the full
collection. This was planned scope, now realized by the implementation above.

## Final acceptance (2026-09-13)

Product Owner reports production migration, D-Day JWT/REST acceptance and actual
Flutter persistence smoke PASS. Day 7 is COMPLETE; next stage is Day 8 Study.
Repository acceptance code and reported markers were compared in this documentation
closeout; no production verification was rerun or SQL executed by Codex.
Authenticated persistence is implemented; guests remain session-memory only.
Historical SQL/preflight/rollback below are retained for reference, not instructions
to reapply an already-applied migration. Project: stlhijzpjfgwwdgunlsd only.

```text
DDAY_RUNTIME PASS login_preflight
DDAY_RUNTIME PASS home_save
DDAY_RUNTIME PASS container_restore
DDAY_RUNTIME PASS home_edit
DDAY_RUNTIME PASS account_switch
DDAY_RUNTIME PASS home_clear
DDAY_RUNTIME PASS profile_school_preserved
DDAY_RUNTIME PASS fixture_cleanup
DDAY_RUNTIME PASS auth_users_retained
Flutter persistence smoke: PASS
```

Save / container restore / edit / clear, account isolation and profile/school field
preservation passed. Test profile cleanup passed; Auth users were retained.

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
  The D-Day repository sends only target fields (plus id for save), never omitted
  profile/school fields as NULL.
- Guest has no database persistence. Authenticated persistence is implemented and runtime-verified.

## Dedicated repository contract — implemented and verified

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
- No RPC/new RLS/service role required. Implementation lives under lib/features/home/.

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

## Actual JWT / REST acceptance — PASS (owner-reported procedure)

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
is implemented; its separate runtime acceptance is recorded in the final results above.

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
The DB STOP was released; subsequent JWT/REST and Flutter runtime gates have passed.
Dedicated tool/verify_day_target_jwt.py is prepared with hidden interactive password
entry or an external account JSON. Uses owner-specified A/B @legendstudy.com accounts,
refuses preexisting profiles and cleans only its fixtures; no Auth users deleted.
Actual JWT/REST acceptance and Flutter persistence runtime subsequently passed.


## Current acceptance and Flutter implementation

Owner reports D-Day JWT/REST acceptance PASS, fixture cleanup PASS, Auth users
retained. DB STOP and JWT implementation gate are released. The dedicated Flutter
repository/provider/editor are implemented and tested; actual authenticated Flutter
runtime verification PASS is confirmed by the final owner-provided markers above.

### Execute actual iOS Flutter smoke locally

```bash
cd /Users/woojinchang/development/legendstudy-app && python3 -B tool/run_day_target_flutter_smoke.py /Users/woojinchang/legendstudy-local.json
```

Booted simulator default: AEC17AF7-4950-4B41-9520-45A60BB7C918; use --device UUID
if needed. A/B passwords are hidden getpass input. Optional --accounts points to
an existing repository-external JSON with TEST_A_EMAIL/TEST_A_PASSWORD and B fields.
Passwords are transferred once over an unpredictable loopback URL; not written to
files, Dart defines, source or compiled app. Runner suppresses raw process output
and emits only allowlisted stage markers; do not infer PASS from process exit alone.

This is real Flutter/SDK/Supabase integration, with test-only programmatic password
login (no new production password-login UI). It exercises actual Home editor save,
edit and clear; rebuilds the app ProviderContainer against the same live session
and checks restoration; logs A out and mounts B's real session to check isolation;
compares profile name/grade/NEIS fields and cleans only its created profile.
The reported PASS proves state reconstruction, not OS process-restart refresh-token
persistence. Normal product OAuth runtime remains a separate gate.

Both profiles must be absent before writes. If either exists the test refuses to
alter it. Auth users are never created/deleted. Finally cleanup handles normal test
failures; forced process termination/network outage can leave a fixture. Require
fixture_cleanup PASS and auth_users_retained PASS before declaring completion.
If cleanup is unconfirmed, inspect/clean only the known test profile before rerun.

Offline: 107 Flutter tests PASS, analyze PASS, Android/iOS builds PASS; 13 Python
runner/verifier tests PASS. Actual Flutter smoke: PASS (owner-run final report).
