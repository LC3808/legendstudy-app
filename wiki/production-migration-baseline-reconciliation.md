# Production migration baseline — ADOPTED / LEDGER VERIFIED

> Current status: [Product applied with security blocker](essay-lab-production-apply.md). All3 applied; ledger16/no pending. Historical checkpoint below is preserved; product remains disabled.


## Authorized baseline write and dry-run — 2026-09-28

**BASELINE_WRITE: PASS · MIGRATION_LIST: PASS · DRY_RUN: PASS.**
**BASELINE_ADOPTED: YES · MIGRATION_LEDGER: INITIALIZED / VERIFIED.**
**READY_FOR_PRODUCT_APPLY: YES (technical gate); PRODUCT APPLY: NOT AUTHORIZED / NOT APPLIED.**

Owner/ChatGPT explicitly authorized only the13 historical versions listed below. They were recorded with
one supported explicit-version `migration repair --linked --status applied` invocation, repairAll=false.
No direct history INSERT, old migration SQL replay, reverted repair or automatic repair retry occurred.
This adopts current Production state as the official managed baseline; it does not prove historical CLI execution.

Pre-write verification: linked LegendStudy, history still absent, all16 pinned migration hashes unchanged,
canonical counts/fingerprints unchanged and Product19 tables/28 functions/private schema absent.
After repair, actual history was read: exactly13 approved versions, no unexpected versions, no Product
versions. Every name matched its pinned filename; stored statements parsed to the same SQL AST as the
pinned repository file. Application catalog snapshot (excluding the intentionally changed history-presence
flag) and canonical counts/fingerprints were identical before/after.

Then `supabase migration list --linked` showed13 exact local/remote matches and3 local-only versions.
Only after that PASS, `supabase db push --linked --skip-vault --dry-run` ran. Actual output: dryRun=true,
exactly the3 Product files, seeds=[], roles=[]. skip-vault excluded vault updates. No non-dry push ran.
Final read-only verification after dry-run again showed exactly13 historical entries, absent Product
objects and unchanged canonical counts/fingerprints.

| Canonical relation | Before | After |
|---|---:|---:|
| universities |5|5|
| essay_exams |21|21|
| essay_exam_resources |134|134|
| resources |10556|10556|

Actual pending / dry-run planned, and **not applied**:

- 20260928000100_student_essay_product.sql
- 20260928000200_essay_entitlements.sql
- 20260928000300_essay_server_operations.sql

[Sanitized write/list/dry-run result](../supabase/validation/migration_baseline/write_result.json).
No credential, personal UUID/email, student content or raw DSN in the result. Only migration history
schema/metadata changed under authorization; no application schema/data, Product migration, student seed,
AI, payment or UI work. Owner SQL required:NO. Owner iOS edits preserved.

Four focused write-result tests and Wiki/diff/secret checks PASS. Previous1569 schema comparisons and
adoption invariants were reused; before/after catalog snapshots verify this operation's noninterference.
The remaining product rollout gates are privacy/provider/backup retention, actual AI provider adapter,
and worker credentials/reconciler deployment. Technical apply readiness does not close those gates.

**STOP after dry-run. Next: Owner/ChatGPT reviews this output and separately authorizes Product apply.**

---

# Historical adoption approval — before authorized write

## Owner final adoption check — 2026-09-28

**BASELINE_ADOPTION_READY: YES.** Current Production state can be adopted as the historical
chain through20260927000200. **13 baseline candidates;3 Product versions remain pending.**
Actual history write, repair, list, db push/dry-run and Product apply were not performed.
The next controlled baseline write requires separate authorization.

Owner supporting context: “초기 LegendStudy Production DB 변경은 주로 Supabase SQL Editor를 통한
Owner 수동 적용으로 운영되었으며, 따라서 Supabase CLI migration ledger가 존재하지 않는다.”
Ledger absence is consistent with that workflow; this is not individual migration execution proof.
Further pursuit of historical CLI execution proof stops. Earlier UNKNOWN findings below remain a
historical evidence boundary, superseded for current-state adoption by this Owner decision and narrow check.

Existing1569/1569 structural comparisons, semantic divergence0, Foundation state equivalence and canonical
5/21/134/orphan0 evidence were reused without another schema audit or canonical-data query.
Only three data-correction current invariants were queried, using BEGIN READ ONLY/ROLLBACK and aggregate
counts. No IDs, emails, tokens or private row contents returned. [Current sanitized result](../supabase/validation/migration_baseline/adoption_result.json).

| Migration | Intended current invariant | Violation count | Result | Replay effect | Baseline safe |
|---|---|---:|---|---|---|
|20260917000200|Pending notifications have scheduling metadata; processing/claim fields are consistent|0|PASS|NO_OP|YES|
|20260926000100|No eligible legacy profile remains without a target; no duplicate primary target per owner|0|PASS|NO_OP|YES|
|20260927000100|Profiles with grade/school information do not lack an onboarding marker|0|PASS|NO_OP|YES|

Replay effect describes **only the original data-correction statement at this observed snapshot**.
No replay was executed; full historical DDL replay is still prohibited. Notification backfill NULL matches0;
terminal sent/failed NULL schedules are legitimate later lifecycle states, not invariant violations. The
unconditional old NULL backfill could be risky on such rows later; today no such rows match. D-Day titles
need not equal legacy titles after legitimate user edits, so no equality condition was invented.
These predicates assess current adoption safety, not historical affected populations or exact timestamps.
Foundation20260927000200: STATE_EQUIVALENT YES / BASELINE_SAFE YES / execution proof remains NO.

### Exact controlled baseline-write plan — prepared only

After separate approval, Codex/operator verifies the linked LegendStudy project and the approved file
hashes, then uses the supported CLI history initializer/explicit-version repair path already inspected.
Do not ask Owner to execute SQL. Do not directly INSERT history. Never omit the version list.

```sh
supabase migration repair --linked --status applied 20260912000100 20260913000100 20260913000200 20260914000100 20260914000200 20260917000100 20260917000200 20260923000100 20260923000200 20260925000100 20260926000100 20260927000100 20260927000200
supabase migration list --linked
supabase db push --linked --skip-vault --dry-run
```

These commands were **not executed**. After repair, inspect the history metadata read-only: exactly13
approved versions/names and file statement metadata match the frozen inventory; all3 Product versions
remain absent. The CLI history initializer and row repair use separate transactions: if either fails,
stop and inspect actual history rather than assuming rollback across both. Keep product writers disabled.
Run list verification only after a successful approved repair. Run dry-run only if list/history verification
passes; it must show exactly the following pending versions, otherwise STOP:

- 20260928000100
- 20260928000200
- 20260928000300

Do not use include-all/include-seed/include-roles. skip-vault avoids unrelated vault updates.
**STOP after dry-run; no Product migration apply.** Privacy/provider/retention and actual student rollout
remain separate gates. No old data correction or application schema change belongs in the baseline write.

Ordered baseline versions:

```text
20260912000100
20260913000100
20260913000200
20260914000100
20260914000200
20260917000100
20260917000200
20260923000100
20260923000200
20260925000100
20260926000100
20260927000100
20260927000200
```

Validation:4 focused adoption tests PASS; Wiki/diff/secret/Owner-file preservation checks. The1569
structural comparison and previous18 tests are historical evidence and were not rerun for this narrow task.

---

# Historical reconciliation checkpoint — before Owner adoption context

**BASELINE_READY: NO · READY_FOR_BASELINE_WRITE: NO · READY_FOR_PRODUCT_APPLY: NO.**
2026-09-28; starting package8ed425f. No migration was executed, including local replay. Production schema/history remain unchanged.

## Recommendation
Use Supabase CLI **explicit-version migration repair** only after a separate Owner-approved baseline
decision. Current approved history-write list is **empty**. Never replay old SQL, repair all versions,
create/INSERT history manually, or run db push/dry-run now. No Owner SQL action is required.

All13 historical migrations have matching current schema projections. Ten have no unresolved historical
data effect and are **state-equivalent baseline candidates**, not proven migration executions. Three
include mutable historical backfills whose original affected population/time cannot be reconstructed.
All3 new Essay Product versions remain CONFIRMED_NOT_APPLIED.

Execution-proven here requires independently verifiable version-specific deployment/history evidence.
Existing Owner-applied Wiki acceptance is preserved as supporting provenance, not revoked, but is not
silently converted into a recovered execution receipt. State equivalence does not prove that a file ran.
Consequently evidence grade UNKNOWN applies to all13 historical versions; the10 equivalent candidates
are a subset of that13, not an additional disjoint count. CONFIRMED_APPLIED:0.

## Per-version inventory and decision
[Machine manifest](../supabase/validation/migration_baseline/manifest.json) includes filenames, source hashes,
classification, DDL/functions/triggers/RLS, dependencies, evidence and recommended history status.

| Version | Purpose | Class | State equivalent | Execution proven | Grade / action |
|---|---|---|---|---|---|
| 20260912000100 | Initial content/profile/bookmark/recent/quarantine schema | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260913000100 | Profile NEIS school selection | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260913000200 | Profile single D-Day fields | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260914000100 | Study session facts and interval validation | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260914000200 | Versioned mock scoring schema/RPC/RLS | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260917000100 | Feedback/admin/outbox schema | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260917000200 | Feedback lease/retry worker and scheduling backfill | MIXED | UNKNOWN | NO | UNKNOWN / hold history write |
| 20260923000100 | Study total inclusion flag | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260923000200 | Private profile avatar bucket and owner policies | MIXED | YES | NO | UNKNOWN / hold history write |
| 20260925000100 | Resource resolver quota/RPC | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260926000100 | Multiple D-Day targets and legacy backfill | MIXED | UNKNOWN | NO | UNKNOWN / hold history write |
| 20260927000100 | Profile personalization and onboarding backfill | MIXED | UNKNOWN | NO | UNKNOWN / hold history write |
| 20260927000200 | University/Essay canonical foundation | SCHEMA | YES | NO | UNKNOWN / hold history write |
| 20260928000100 | Essay student product tables | SCHEMA | NO | NO | CONFIRMED_NOT_APPLIED / pending |
| 20260928000200 | Essay credit entitlement ledger | SCHEMA | NO | NO | CONFIRMED_NOT_APPLIED / pending |
| 20260928000300 | Essay server operations/leases/idempotency | SCHEMA | NO | NO | CONFIRMED_NOT_APPLIED / pending |

## Exact unresolved data effects
- **20260917000200:** next_attempt_at backfill for then-NULL notification rows. Worker retries/rescheduling
  later change that value; current row presence or function identity cannot prove the historical UPDATE.
- **20260926000100:** legacy profiles.target_date/target_label copied into primary day_targets only when
  no target existed. User edits/deletions and changed legacy fields prevent exact reconstruction. The
  previous Owner-reported two-row backfill remains supporting historical evidence, not a new row audit.
- **20260927000100:** onboarding_completed_at set for then-existing grade/school profiles. Later onboarding
  and profile edits cannot recover original eligibility or timestamp. Owner migration PASS remains recorded.

Do not rerun these backfills. Closing these gaps needs version-specific deployment evidence or an explicit
Owner decision accepting a documented state baseline despite unreconstructable data history. Such a
decision must remain distinguished from proof that the old UPDATE/INSERT executed.

## Foundation20260927000200 precision review
**STATE: UNKNOWN; STATE_EQUIVALENT: YES; EXECUTION_PROVEN: NO.**
148 structural/permission checks in the original comparison, plus ownership/grant-option/index-count checks
in the final1569-check package:3 tables,42 columns,32 PK/FK/UNIQUE/CHECK constraints,7 indexes,
3 enabled triggers,3 policies, RLS enabled/FORCE false, no unexpected columns/policies/triggers,
parent composite FK and published-resource predicates all match. Defaults, nullability and types match.
Existing set_updated_at function body/signature is independently matched in the initial migration scope.

Production service_role also holds REFERENCES/TRIGGER/TRUNCATE/MAINTAIN. This is not hidden drift:
observed Supabase default ACL grants those rights, and foundation revokes only PUBLIC/anon/authenticated
before granting service_role CRUD. Applying its SQL in that observed default environment produces those
rights. Clients have SELECT only. Default ACL history itself is not independently proven.

## Comparison method and limits
- Production catalog read in BEGIN READ ONLY/ROLLBACK through existing LegendStudy CLI query connection.
  No auth.users/profile/answer/notification row contents were read. Avatar fixed bucket config only:
  private,PNG,1048576 bytes. Function bodies are hashes; one pure Study helper was compared privately.
- **1569 offline structural assertions match**, including tables/columns/generated expressions, constraints,
  indexes, RLS/policies/triggers, schema-lifetime grant/revoke projection, function signatures/default args,
  security/config/ownership and grants. These are static snapshot comparisons, not runtime RLS tests.
- Function bodies:22 exact trimmed hashes; Study helper lexical tokens identical despite whitespace.
  Four catalog deparse differences (numeric widening, inferred NULL type,24-hour interval rendering)
  were explicitly reviewed/frozen. Parser-added literal casts and IN/ANY/BETWEEN forms are normalized;
  no changed business-expression values are accepted.
- Later profile columns, Study inclusion and notification constraint replacement are accounted for by
  the ordered repository projection. A historical migration does not own subsequent legitimate extensions.
- DIVERGENCES:0 observed semantic differences in inspected migration-owned schema/configuration.
  Unknown backfill effects are uncertainty, not proof of divergence or proof of applied state.
- Current Supabase defaults are part of the reconstructed state environment; this is not a full audit
  of platform auth/storage schemas or proof of their historical configuration.
- Before/after canonical counts5/21/134 (resources10556) and all fingerprints identical. Existing
  orphan0 result is preserved from accepted preflight; no personal data fixture or mutation was used.

## Recommended baseline mechanism — future approval required
Installed CLI help and embedded vendor implementation were inspected locally; no migration command ran.
`migration list` lists local/remote versions. `migration repair --linked --status applied <explicit versions>`
initializes supported history schema/table/columns via its initializer, then transactionally upserts
version/name/statements metadata. It does **not** execute stored migration SQL. Initialization and row
updates are separate transactions, so failure can leave an empty initialized catalog. Inspect outcome,
do not infer all-or-nothing across that boundary. Never omit versions: this CLI has an all-history repair
path that can truncate/rebuild history. Never use --status reverted as a shortcut here.

Future sequence, **not authorized/executed now**:
1. Resolve3 data-effect unknowns and explicitly approve state-equivalent baselining for the10 candidates.
   Freeze reviewed migration hashes and the exact version allowlist; every earlier ordering-affecting
   version must have a documented decision. Partial marking does not make the chain safe.
2. Recheck backend identity/history absence and canonical baseline. Operator invokes supported repair
   with only the approved explicit historical versions; no direct SQL INSERT and no migration replay.
3. Read back history versions/names and compare stored statements to pinned files; no Essay Product
   version may be marked applied. Handle a partially initialized history catalog through reviewed tooling.
4. Only after history reconciliation is complete, separately authorize `supabase migration list --linked`
   and `supabase db push --linked --skip-vault --dry-run`. Expected pending exactly:
   **20260928000100,20260928000200,20260928000300**. Unexpected pending versions: STOP.
5. Product apply remains a separate approval and the existing preflight/checkpoint plan still applies.

Candidate state-only allowlist (not approved): 20260912000100, 20260913000100, 20260913000200, 20260914000100, 20260914000200, 20260917000100, 20260923000100, 20260923000200, 20260925000100, 20260927000200.
Unknown data-effect exclusions: 20260917000200, 20260926000100, 20260927000100.
Pending exclusions: 20260928000100, 20260928000200, 20260928000300.

## Validation and stop
[Offline package](../supabase/validation/migration_baseline/README.md) /
[CLI semantics](../supabase/validation/migration_baseline/cli_semantics.json).
8 focused tests,1569 catalog comparison assertions, existing10 promotion/preflight tests, Wiki/diff and
secret/private-identifier checks. Owner iOS changes preserved. No migration list/repair/push/dry-run,
Production DDL/DML, student seed, AI or UI work. STOP for Owner/ChatGPT review.
