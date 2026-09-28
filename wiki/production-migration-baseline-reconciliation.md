# Production migration history baseline reconciliation — READ ONLY / NOT READY

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
