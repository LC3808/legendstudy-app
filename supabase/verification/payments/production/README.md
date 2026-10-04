# PAYMENT-PRODUCTION-READINESS-1 — review package, 2026-10-04

**PRODUCTION_READINESS: BLOCKED. TEST_E2E: COMPLETE. Production apply/LIVE/deploy: NOT AUTHORIZED.**
This package prepares review and operations; it does not claim only merchant approval remains.
Canonical financial implementation remains [payment-v1](../contract.md), not a new wallet.
LAB implementation/runbook is in its existing `docs/PAYMENT_2_TOSS_INTEGRATION_HANDOFF.md`.

## Source and current Production evidence

- APP payment migration revision `3b3b869297a0884bfb908c87977fa14519f72d91`; Hosted-equivalent verification `43752ce5fa23d44be29edb7cdf6319bc15e0a1ab`; readiness branch starts at `a5afe71` (latest TEST24h mint option). Payment is not in APP main (`d07671e` observed). No canonical SQL changed here.
- LAB TEST fix `5b132b22ff263c0e829b9d8bd1847bfeb37981ab`, final handoff `8422ed7`; both on `codex/payment-2-toss-test`. Source SHA before readiness hardening `794c7a7c62a24c2e29c76a07d55e52a4acaf61d9e5feb17e96bf6a6bfb39389a`. LAB main observed `87ce790` includes newer pricing UX. Payment feature is unmerged; future integration must preserve that pricing work. The readiness branch adds only TEST project/origin pinning, tests and documentation, not LIVE activation.
- [Read-only evidence](read-only-evidence.json): explicit Production project `stlhijzpjfgwwdgunlsd`, PostgreSQL17.6, executor postgres,23 tracked versions. Payment objects/migration absent; `account_private.allowed/lock_subject` absent. Auth/profiles and canonical Credit Ledger present; purchase grant aggregate0. No student row, identity or transaction payload retrieved.
- public owner/grantor remains pg_database_owner. Existing essay_executor ADMIN membership from supabase_admin to postgres has INHERIT=false/SET=false. Finance→authenticator enrollment absent. All nine ADR predecessor function owner/security/search_path/ACL comparisons PASS; managed storage.objects policy authority TRUE. Missing ADR is a known unmet prerequisite, not permission to bypass lifecycle guards.
- Production audit was read-only, not successful apply preflight: `PRODUCTION_DB_PREFLIGHT: OWNER_ACTION_REQUIRED`. No migration repair, ledger update, database mutation, signing change, provider call or deploy performed.

## Exact candidate allowlist and order

[manifest.json](manifest.json) is the three-file review allowlist with SHA-256, not an apply script.
Run `python3 supabase/verification/payments/production/verify_manifest.py` offline.

1. `20261001000300_account_deletion_lifecycle.sql` — prerequisite, separately reviewed ADR-2D; lifecycle stays OFF. SHA `38c86fd79554225fbc6a5a30be791c860e6c89dcaa64ad7e229e3710b9a29d94`.
2. `20261003000100_payment_foundation.sql` — SHA `77b460bf2bf437a8d6dd03d78454ece17c6c4143fe50d7f28b6ea30a51509c75`; default payment mode TEST. Requires successful ADR postflight first.

Never replay Hosted TEST24. Existing23 tracked files, Math candidate files, day-targets/provider005 and other pending files are excluded. SQL installation does not authorize ADR worker activation, hooks, payment finance enrollment or LIVE mode. Older ADR README tracking instructions do not override this task: **no migration repair or manual migration-ledger writes**. Owner must approve a supported exact-version tracking workflow separately before execution; no broad push.

Before approval, rerun [inventory.sql](inventory.sql), [dependencies.sql](dependencies.sql), [adr-security.sql](adr-security.sql), and ADR [ownership catalog](../../account_deletion/ownership_catalog.sql). Compare project identity,23 versions, nine signatures, owners, ACLs, schema grantors and role memberships to this snapshot. Drift requires a new review, not privilege adjustment. Read-only audit today is not a guarantee of later state.

After separately approved ADR apply: verify lifecycle OFF, exact ADR catalog and original ownership/ACL restoration per its Owner package. Then run [preflight.sql](preflight.sql), existing Payment [catalog.sql](../catalog.sql), hash checks, and compare the complete inventory again. Known current ADR absence makes preflight abort intentionally. Do not edit Hosted/Production schema owners.

After separately approved Payment apply: run [postflight.sql](../postflight.sql), [catalog.sql](../catalog.sql), [ownership audit](../ownership.md); verify2 public RPCs/2 private functions,3 payment tables + configuration (before runtime extension), RLS/ACL, original memberships/schema ACL restored, config TEST, payment rows0, purchase grants/postings/spendable delta unchanged from pre-apply baseline. Do not run synthetic orders in Production for this check. Capture aggregate deltas rather than assuming whole wallet0.

Abort on first SQL error, hash mismatch, unexpected existing object, missing predecessor, security drift, uncertain commit, changed mode, new financial row or unexpected grant. Each migration has its own transaction; do not run the next file after failure. An unknown apply outcome requires read-only catalog inspection, never blind replay.

## Rollback and financial recovery

Payment [rollback.sql](../rollback.sql) is only for an empty new install and refuses data/dependencies; isolated failure injection and empty rollback PASS. If Payment fails after ADR succeeds, leave verified ADR installed and disabled; do not cascade-drop dependencies. ADR rollback is separately scoped and must pass its own guards.
Once any payment history exists, preserve orders/operations/events/grants and forward-fix. Never delete/rewrite the immutable Credit Ledger, erase unknown outcomes, restore an old database over provider history, or repeat a provider operation with a new idempotency key. Snapshot pending operations and reconcile against authenticated provider lookup before reopening.

## Verified financial contract (isolated PG17, no LIVE call)

| SKU | KRW | One canonical purchase grant / transaction | Spendable increase |
|---|---:|---|---:|
| 1c | 4,900 | exactly once, retry stable | 1 |
| 3c | 11,900 | exactly once, retry stable | 3 |
| 5c | 17,900 | exactly once, retry stable | 5 |
| 10c | 29,900 | exactly once, retry stable | 10 |

`payment_process(confirm_finish)` atomically calls existing `essay_private.credit_post_grant`; origin purchase, external_reference payment/order UUID, unique grant binding/provider identity, serialized account/order locks. TEST instead records TEST_RECORDED with grant_id NULL and no financial posting. Four concurrent confirms produce one purchase transaction. Injected local failure rolls grant and payment state back together; retry restores one posting.

Expiry is provider-approved paid_at (validated canonical range), converted to UTC +3 calendar months, persisted on order and grant. Month-end checks Jan31→Apr30, Nov30→Feb29 in leap2028, Oct31→Jan31 pass. It is not90days. Existing consumption selects unexpired grants in expiry/created/id order (NULL expiry last), subtracting reservations. Included same-lineage reevaluation adds no consumption; technical failure release/refund comes from canonical billing. G1 and Math regression cover these paths, not new payment-specific evaluation logic.

Refund derives purchase-specific net consume/refund facts; full unused returns actual paid amount. 5c17,900 with2 used returns8,100;10c29,900 with5 used returns5,400. Floor0 creates no debt, no free-bonus cash refund. General refund initiation after expiry is rejected. Provider cash refund and ledger reversal are separate: after provider success only unused purchased units are retired; provider partial money cancellation retires all remaining entitlement from that purchase. Pending cancellation fences consumption/expiry; active reservations block cancellation. Real two-session account-lock competition verifies either consumption wins and reduces refund, or cancellation wins and consumption is denied. Provider rejection restores PAID without debit; local finalize failure remains recoverable/fenced.

## APP / LAB parity and remaining internal gates

| Class | Finding / acceptance needed |
|---|---|
| BLOCKER | Production ADR prerequisite missing; exact three-file package requires separate ADR/Payment review and fresh preflight. |
| IMPLEMENTED | LIVE/TEST server adapters, pinned origin/project/key family/MID, canonical POSTED grant validation. |
| IMPLEMENTED | Shared credit-v1 summary and APP/LAB balance display; real 5→4→4→3 evaluation integration. |
| IMPLEMENTED | Explicit PAYMENT_ENABLED order/confirm/CTA control with lookup recovery while paused; missing config NOT_READY. |
| IMPLEMENTED | Cross-owner support Auth allowlist, bounded preview/audit, cancel and reconciliation. Restricted/detached account after provider success has no-grant full-refund compensation claim and existing cancel recovery. |
| OWNER_CONFIG_GATE | Production finance provisioning, credential renewal/expiry monitoring/revocation drill and hosted matrix; TEST credentials must not be reused in Production. |
| OWNER_POLICY_GATE | Statutory/legal decisions and financial-retention/account-deletion operational acceptance remain separate from general-policy calculation. No age-based automated rule. |
| BASELINE_TEST_DEBT | Five unrelated materials/discovery Flutter tests also fail on unchanged baseline; not a Payment regression, not silently fixed in this scope. |
| POST_LAUNCH | Rich support dashboard and richer trend telemetry, after bounded operational read/recovery is available. |
| OPTIONAL | Automated report formatting beyond the required bounded evidence. |
| EXTERNAL_GATE | Toss/card merchant approval WAITING (no completion evidence provided); LIVE key↔merchant proof and Store commercial review separate. |

No Apple/Google API, external native purchase CTA, second wallet or new pricing policy added. Native reuse of web entitlement still requires separate Store commercial review.

## Verification receipt

Payment117 PASS; Math131+37+63 PASS; Essay Credit84 +static7 PASS; Humanities/HQP102 PASS. Payment bootstrap injected failures, ownership/ACL restoration, empty rollback and refusal with history/dependency PASS. [Payment evidence](../validation.json), [Math evidence](../regression.json), [G1](../g1_validation.json), [HQP](../legacy_validation.json). All new finance examples are disposable local data. LAB receipt and operational activation sequence reside in the existing LAB handoff. TEST E2E COMPLETE is historical accepted runtime evidence; not rerun here. Production read-only audit today is new evidence; Production writes0/LIVE calls0/main merges0.

Bounded [monitor.sql](monitor.sql) is a read-only operator query template for pending operations and grant mismatches after installation; it has not been executed on Production (Payment tables absent). No provider key/PII is selected. It is not an authorization mechanism or replacement for the required controlled support tool.

## 2026-10-04 implementation extension (supersedes internal blocker rows above)
Third ordered candidate: `20261004000100_payment_runtime.sql`; exact SHA is in manifest. Additive `public.credit_summary()` authenticated own read, `public.payment_support(jsonb)` finance-only bounded support preview/audit, `public.payment_compensate(jsonb)` finance-only no-grant refund claim, and private append-only support audit table. No existing migration changed. Postflight: `../runtime_postflight.sql` plus existing payment checks. Expected owners postgres, security definer+empty search_path, EXECUTE authenticated only for summary and essay_finance only for support/compensate (plus postgres owner). No browser/private-table CRUD. Verify runtime support audit0 and unchanged purchase/posting aggregates.

Rollback in reverse order: `../runtime_rollback.sql` only with empty support audit, then original guarded Payment rollback if empty, then separately reviewed ADR rollback. Any support history requires forward fix; no cascade or historical ledger reversal as rollback. Test/LIVE DB configuration still defaults TEST; configuration of LIVE DB mode, server keys and purchase switch remains separately approved activation work.

Credit summary derives canonical grant balances minus reservations, excludes expired or cancellation-fenced grants, and separates purchase/signup/other. Consumption policy is unchanged: earliest expiry first, null expiry last, then creation/id; signup Credits do not expire. APP/LAB read the identical credit-v1 RPC. Support preview is advisory; canonical cancel_begin re-locks/recomputes before execution and persisted claim drives provider amount.
