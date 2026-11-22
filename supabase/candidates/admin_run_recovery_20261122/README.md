# Administrator exam recovery — Owner approval candidate

NOT APPLIED. Production DB writes and actual student recovery actions require separate Owner approval under AGENTS.md §4. This package reuses the existing exam runtime, retry and billing contracts. It makes no Provider calls itself.

## Preservation review

1. Request creation, retry admission, recovery preparation, recovery terminal event and actual run completion retain separate meanings and timestamps. Checkpoint execution timestamps do not exist; `last_execution_at` is null and `last_retry_at` is retry admission time.
2. Frozen answers/snapshots, immutable completed checkpoints, durable reviewed/usage evidence, billing decisions and credit ledger entries remain the sources of truth.
3. Existing committed answers, outputs and results are not replaced. A proven pending question may become completed through the existing checkpoint RPC with its original writer/token. Existing finish/retry RPCs perform all run and billing transitions. Recovery evidence appends to the existing immutable action journal.
4. Existing auth.users/admin_users/account lifecycle identity and account→run→billing locking are reused. There is no new student identity, retry engine or ledger writer.
5. Recovery is an operational event, not a new answer, learning judgment, refund or admission outcome.
6. Administrator diagnosis returns bounded metadata. Only the trusted Worker receives frozen private context; answers and lease tokens never enter WEB receipts. No new personal-data collection is introduced.
7. Success derives from actual completion and attributable recovery evidence. Prepared/queued requests do not count as completed; an unrelated later student retry is excluded.

## Execution contract

All A/B/C/D paths use two phases: administrator intent → pure Worker validation → atomic DB revalidation and existing finish/retry. The versioned metadata examples are in `contract.json`.

| RPC | Access and behavior |
| --- | --- |
| `admin_lab_run_recovery(p_run)` | Existing authenticated administrator check; read-only diagnosis. |
| `admin_lab_recover_run(p_run,p_key,p_diagnosis_token)` | Existing administrator permission/lifecycle check; locks and records a prepared or known-blocked intent. No execution or queue here. |
| `essay_exam_recovery_context(p_key)` | essay_worker only; verifies original actor remains an active administrator and returns frozen context. A changed/blocked intent may append its blocked terminal audit; this endpoint is not strictly read-only. |
| `essay_exam_recovery_finish(p_key,p_diagnosis_token,p_result,p_proof)` | essay_worker only; verifies original intent, actor, current artifacts and reservation, then atomically restores proven pending questions and calls the existing finish/retry. |
| `admin_lab_recovery_operations(p_from,p_to)` | Existing administrator check; bounded operational projections. Requires non-null ordered bounds of at most 93 days. |

- A: durable final equals all latest validated question results; complete with Provider calls **0**.
- B: completed and definite failed questions; validate retained outputs first, then existing retry advances only failed attempts.
- C: all questions definite failed; validate exact failed claim/evaluation identities before existing retry. Empty partial result is permitted only for this retry branch, never for completion.
- D: pending questions require durable bound reviewed output, usage and the existing type-specific verification evidence. Restore through the original checkpoint writer. With all results present, complete with Provider calls **0**; with definite failures, restore and prepare only failed retries in one transaction.

Latest immutable reviewed evidence is trusted as proof of the original validation boundary. Worker reuses the existing claim reconstruction, strict output validator and local review finalizer, including frozen parent context for revisions. Math uses the existing Math result guard. No fabricated clock, expired HMAC replay, or alternative evaluation engine is introduced. DB independently compares identities, stored outputs, usage, summary and the context digest; canonical Python hash/material validation stays within the essay_worker trust boundary.

When all N/N results are proven, pending summary/final rows with null payload stay unchanged and deterministic summary aggregation feeds the existing finish. Existing checkpoint payloads must match exactly. The existing checkpoint constraint enforces pending→null payload and is checked by installer preflight. Any summary/final row blocks B/C/D mixed retries.

Unknown or reconciling Provider outcomes without complete durable evidence, missing dispatch/claim, missing question rows, active leases, archived/finalized requests and incompatible reservation states stay blocked. Age or an expired lease is never sufficient proof of interruption.

## Concurrency, permissions and audit

The diagnosis token hashes the run, frozen parent result, checkpoints, retry generations, billing, related ledger and hidden state. Commit rechecks it under the existing account→run→billing lock order. Pure Worker validation holds no long transaction or new lease. A concurrent original Worker write or another recovery invalidates the token; no completed result can settle twice.

The original action key identifies prepared and returned receipts. A deterministic separate terminal action appends success/failure without rewriting history. Same-key replay returns the current canonical completed/queued/blocked receipt. Queued replay can dispatch only while its exact retry key/generation remains latest and its lease is valid; unrelated later completion is not attributed to this recovery.

Known failures return a bounded blocked reason so the audit commits. The restoration/retry/settlement subtransaction rolls back entirely before this audit. Reasons distinguish artifact validation, restoration, retry and settlement failures without exposing raw SQL, answers or Provider text. Authentication/authorization failures raise without disclosing target details. Both Worker phases recheck that the prepared actor is still an administrator and both accounts remain allowed. No JWT impersonation or client-set bypass is used.

Only authenticated administrators may invoke diagnosis/preparation/projections; only essay_worker may invoke context/finish. Private helpers have no client grants. Existing RPC definitions, owners, ACLs and the immutable action trigger are unchanged.

## Operational projections

- `attention_total`: all-time visible reserved requests with no active original/retry lease. This means operator review is needed, not that the Worker is proven stopped. Metadata list is limited to 25 rows.
- `stale_lease_count`: visible reserved requests whose latest recorded lease expired at least 15 minutes ago. Missing lease times are excluded.
- `recover_success`: distinct runs actually completed within `[from,to)`, with a completed recovery terminal event or an accepted recovery retry whose request key/generation equals the final latest retry. This is a projection of completion, not a fabricated completion audit.
- History uses recovery event time; success uses run completion time. `recent_error` is one confirmed diagnostic from current question attempts; its occurrence time is unknown.
- `billing.reserved` is the current ledger reserved total. `reserved_total` is historical reserve. `consistent` distinguishes valid reserved/settled/released states; `recovery_eligible` is the stricter reservation prerequisite.

## Files and validation

`preimage.json` and `auth_preimage.sql` contain read-only production source/schema evidence, with no student answers or credentials. `functions.sql` plus `build_package.py` generate the guarded `install.sql`. `manifest.json` records exact preimages and locally compiled postimages. `postcheck.sql` checks new and preserved function source/owner/ACL; `rollback.sql` validates the installed postimage before removal. `result.json` is the isolated test receipt.

The local harness uses PostgreSQL 17, a NOSUPERUSER/BYPASSRLS function owner, real authenticated/anon/essay_worker roles and captured production RPC/auth definitions. It connects only to `/private/tmp` port 55441 and asserts its private synthetic cluster directory before any reset. Run `python3 supabase/candidates/admin_run_recovery_20261122/test_postgres.py` only after starting that isolated cluster.

Coverage includes A/B/C/D, mixed restore→retry atomicity, Math, pending aggregate preservation, actual SQL receipts through the Worker adapter, original retry races, concurrent administrators, idempotency, expired/forged JWT metadata, ordinary-user/private-context denial, revoked actor/lifecycle, review/output corruption, unknown Provider blocking, existing credit source preservation, zero-credit completion, settlement rollback, truthful KPI attribution and source-only rollback. Grant tests use synthetic Apple/purchase origins and verify the original source grant and reservation are retained. They are not Apple/Toss payment E2E tests. The harness does not reproduce unrelated production payment triggers or invoke real payments, Providers or students.

## Approval, installation and rollback

CLI generated candidate name: `20261122064411_admin_run_recovery_20261122.sql` in an isolated temporary migration workspace. It is not an applied production migration and must not be promoted as applied history before deployment evidence exists. Candidate target project: `stlhijzpjfgwwdgunlsd`.

After Owner approval, verify exact installer SHA256 against `manifest.json`/`result.json`, fresh source/ACL/constraint preimages and preserved-data hashes. Apply `install.sql` as one migration, run `postcheck.sql`, then deploy the matching Worker/WEB adapters and perform metadata-only permission checks. Any actual recovery of an existing student request remains a separate explicit action. No backfill or student-data update occurs in the installer.

Rollback Worker/WEB adapters first, then run guarded `rollback.sql`. It drops only the new functions. If no recovery audit exists it restores the original action constraint; otherwise the expanded immutable recovery vocabulary is retained. Code rollback must never delete recovery evidence or reverse real completed results/ledger entries. Existing finish/retry/checkpoint and payment functions remain unchanged throughout.
