# Essay evaluation stability P0 — 2026-10-29

Status: PARTIAL — local corrections verified; original evaluator/HTTP causes unresolved; Production changes BLOCKED on Owner approval. Branch `codex/essay-evaluation-stability-p0-20261029`, starting from `14bbc5cbf228c5c6ee26a9cb0524084924ce9ecc`. Latest Owner urgent directive and IMG_1292–1295 supersede the earlier device QA handoff for this scope. No Production deployment, evaluation, Credit mutation or History repair is authorized.

## Preservation review before implementation

Per [longitudinal strategy](longitudinal-learning-admissions-data-strategy.md), all seven questions are answered:

1. Existing answer, canonical question, run, checkpoint and timestamp facts remain immutable; observations are derived reads.
2. Original snapshots and pinned package versions reconstruct historical context; a partial result never changes whole-run state.
3. No UPDATE, deletion or backfill of existing learning facts. New functions are read-only projections; failure diagnostics append through the existing fenced checkpoint contract.
4. Identity remains authenticated owner → Credit account → existing run → canonical question ID, never list position.
5. This is Learning-state display and recovery of an existing request identity, not new Decision/Outcome collection.
6. Existing lifecycle/ownership gates apply. No raw answers, Provider response, authentication material or private reviews in diagnostics; on-device request metadata is owner scoped. Existing retention/erasure contracts remain unchanged.
7. Display labels, current state and partial result projections are derived; Ledger/History remain authoritative. No new analytics or storage tables.

## Verified operating evidence

- KHU 2024 mock humanities/physical-education run `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1`, created 18:17:19 KST, remains reserved. Exactly one reserve, no consume/release observed.
- UUID-sorted snapshot index 0 is **논제 2** (`92a9044c-9eaa-58d8-b4e9-365b2e9a02f0`), completed. Index 1 is **논제 1** (`abb351b6-d462-5916-a03a-956c964f6359`), initial attempt plus nine explicit retry generations failed. Success was preserved; these are not nine automatic Provider retries.
- Failed attempts have no Provider receipt, validation-failure or independent-review receipt. Existing Worker catches some input/adapter/identity/telemetry errors without a diagnostic receipt. Absence of a receipt **does not establish that no Provider call or billing occurred**. Specific failure stage/code remains unconfirmed.
- APP History used UUID position as a fallback official number and additionally rendered reserved-run-derived PROCESSING labels under actual session states. These two display defects are confirmed independently of the unresolved evaluator failure.
- SWU root `6ef28b49-12a5-4825-886d-548f0d9897df` completed. No additional run for the same owner/exam was found in the bounded Oct29 query. Frozen and current package digest match `dffdb94b185ba6e316bae052db1d5c1a92259c5cc974476ecc3c86877877a233`. No original client HTTP status/body/request key exists in the inspected evidence; exact submission failure cannot be asserted.
- KHU frozen/current package digest both `55b0f040abda62fbe4919424c1410aa55bd4d8fab055947cbe30bea41560382d`.

Prior evidence: [device QA](app-device-qa-fixes-20261029.md), [HUFS/Konkuk and Owner fixes](app-owner-fixes-20261029.md). Full result UI and commerce Math work remain outside this task.

## Failure classification and limits

| Class | Finding |
| --- | --- |
| A generation | UNCONFIRMED: failed question has no durable Provider response/receipt. |
| B official criteria | Frozen Production package and both exact stored answers pass `prepare_claimed_material`, `package`, and request serialization up to (not including) transport. Each has 1 criterion/4 evidence references. This rules out a reproduced local input failure, not a historical generated-answer mismatch. |
| C exact quote / D independent review | KHU has no corresponding rejection record. Do not transfer HUFS/Konkuk/SWU historical causes to KHU. |
| E Provider/timeout | UNCONFIRMED: early HTTP rejection, incomplete/refusal, malformed response and identity/telemetry errors previously lacked a durable stage. External billing is unknown. |
| F lease/checkpoint | Claim/token exists; original lease is expired by inspection. Nine explicit retry generations each extended the existing dispatch window. q0 success is preserved. Expiry after failure does not prove expiry caused it. |
| G state/cache | Confirmed duplicate PROCESSING projection removed; owner/run single-flight observations and refresh-failure preservation implemented. |
| H identity | Confirmed UUID-order display-label bug. Canonical IDs and stored answers are unchanged. Actual 논제 1 failed / 논제 2 completed. |

Final bounded SELECT: KHU reserved, q0 completed, q1 and q1-retry-9 failed, nine retry rows; reserve exactly 1 (`balance_delta=0`, `reserved_delta=1`), no consume/release. SWU root completed, within 14 days, no children. Candidate API count **0** in Production. No operating change was performed.

SWU: original HTTP dispatch/response code/body, client timeout and rejected payload/request key are NOT VERIFIED. No accepted child run was found. Existing free rewrite checks and parent-relative revisions remain enforced. New best-effort local diagnostics retain only action/time/exam/key/parent/phase/HTTP status/symbolic code, not answer, token or raw response. Lost acknowledgement is looked up by existing key/owner/exam/parent/paid predecessor before any replay; unavailable lookup preserves the key and blocks redispatch. An acknowledged absent request can only replay its same key and exact fingerprint.

## Actual changes

| Files / functions | Change |
| --- | --- |
| `lib/features/essay/shared_history.dart`: `read`, `essayExamQuestionLabel` | Resolve Registry labels for universities represented in owned history; never number UUID positions. Reserved runs do not fabricate per-question PROCESSING. |
| `lib/features/essay/shared_history_page.dart`: `build`, `openWriter` | Remove duplicate reserved-run labels; a partial result cannot initiate another cycle before the whole run completes. |
| `lib/features/essay/exam_session_store.dart`: `ExamSessionStore.refresh/watch` | Shared owner/run read, coalesced concurrent reads, preserve last success on failed refresh, reject completed-question regression, dispose on account change. |
| `lib/features/essay/round_history_actions.dart`, `source_catalog_page.dart` | Shared observations, retained confirmed state, stale retry permission disabled, explicit failed-only retry; existing admission and server retry fence remain authoritative. Partial result links are rollout gated. |
| `lib/features/essay/exam_submission.dart`: `record`, `recoverExamRequest`; `source_catalog_page.dart`: `submit`, `restoreInFlightRun` | Bounded local HTTP metadata and existing-key lookup before parent eligibility/replay; same run restoration after lost acknowledgement. |
| `lib/features/essay/evaluation_report.dart`: `examEvaluationReport` | Reuse existing Native result view for an explicitly completed-question projection while whole run remains reserved. No full result redesign. |
| `tool/essay_lab/live_worker.py`: `execution_failure`, `execution_steps`, `OpenAIResponses.response_steps`; `cloudflare_runtime.py`: `receipt_checkpoint_key` | Append safe binding/input/provider/identity/telemetry failure metadata through existing fenced checkpoints. HTTP 4xx status retained without raw body; 5xx/network ambiguity retains the existing symbolic unknown classification. Unknown transport remains reconciling; no added Provider retry or threshold relaxation. |

Prior retry feedback candidate is retained: only EXACT_QUOTE/INDEPENDENT_REVIEW_NOT_ACCEPTED, same question/previous attempt, whitelisted bounded review reasons as untrusted data; original evidence, exact Unicode quotation, student grounding and signed independent review unchanged. Legacy checkpoints can recover symbolic codes, **not missing detailed reasons**. KHU's unrecorded early failures cannot be repaired by assuming review feedback applies.

## Approval package — NOT APPLIED

- [Install](../supabase/candidates/essay_observation_p0/install.sql), [verify SELECT](../supabase/candidates/essay_observation_p0/verify.sql), [rollback](../supabase/candidates/essay_observation_p0/rollback.sql).
- Three additive authenticated-owner read APIs: `essay_exam_request_status`, `essay_exam_observation`, `essay_exam_question_result`. No tables, RLS changes, activation, reservation, refund, dispatch or historical writes.
- Observation binds generation/checkpoints/official labels in one SELECT snapshot. Partial read requires existing completed + identical reviewed checkpoint + telemetry, exact answer hash, authorized frozen package and matched criterion IDs; strips private local reviews/telemetry. Failed/pending/foreign questions are denied. Whole-run state stays reserved.
- Apply only after Owner approval using the existing deployment owner. Verify authenticated execute=true, anon/service=false and incident facts unchanged. Owner-authenticated read smoke tests require no Provider request.
- `ESSAY_OBSERVATION_V1_ENABLED=true` enables richer state and partial-result UI **only after SQL approval/application**. Default is false. Current unrolled build leaves partial-result actions disabled with a preservation message. Existing-key recovery safely refuses to redispatch if the new lookup is unavailable.
- Worker deployment is a separate approval. Package the current full Production Registry/config with the tested source; do not substitute a subset research manifest. Recheck and pin the actual deployed version immediately before rollout. `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4` is the prior verified Wiki version, not a new live-version attestation.
- An approved future retry is a separate Owner decision. No existing run was restarted; these patches do not prove KHU's next generation will succeed.
- Rollback: restore the prior APP build or revert this branch's code commit; disable observation flag before dropping the three additive read functions. Worker rollback to the version pinned immediately before an approved deployment. Preserve all existing successful checkpoints and Ledger facts. SQL rollback changes no history or Credit data.

## Verification

- Flutter Analyze: PASS, zero issues.
- Full Flutter Test: **1186 PASS / 7 existing SKIP**. SKIP is not PASS; no device/Provider acceptance inferred.
- Worker/strict criteria/review/retry/queue/packaging regression: **74 PASS**, synthetic transports only.
- Isolated PostgreSQL Credit contract: **18 PASS**; concurrent identical requests, one reservation/settlement, free rewrite, immutable history.
- Isolated async surface + new read APIs: PASS; owner/key lookup, reversed snapshot vs canonical labels, partial redaction, missing reviewed checkpoint denial, foreign/anon/service/lifecycle denial, unchanged run/Ledger, rollback; existing 8-concurrent-retry fence and successful-checkpoint preservation PASS.
- Read-only Production projection validation on completed KHU 논제 2: reviewed output equality, evaluation identity, answer hash, criterion UUIDs and usage checkpoint all **true**. This is a SELECT check, not deployment or an authenticated public-API acceptance test.
- Actual KHU frozen inputs and pinned package: PASS to request preparation; stopped at transport, **0 Provider calls**. Private local fixtures excluded from Git.
- Physical iPhone, real retry/rewrite completion, operating partial-result retrieval: NOT TESTED / approval blocked. Original KHU failure code and SWU HTTP error remain unresolved.

## Handoff

Final code commit: `94d9f4d69de3eeef1d18a75ada261e3848402078`. Documentation is committed separately; final local/remote branch equality is checked after push and reported in the Owner handoff.

Signed iPhone QA build **1.0.1(24)**: PASS, `./tool/device-qa --build-name 1.0.1 --build-number 24`, Xcode 48.8s, 36.7MB. Existing `com.legendstudy.app`/signing/Supabase/social URL configuration retained. Source is the code commit above; framework SHA-256 `73aad5741141eee7a63a6737dca5ca967add882d7c7b8bd58affbca0197aca09`. Local artifact `build/ios/iphoneos/Runner.app`, receipt `build/ios/device-qa-receipt.json`. Prior build23 and receipt preserved under `build/ios/qa-preserved-23/`. Observation rollout flag verified OFF because APIs are not installed. **Not installed, not uploaded, no real authentication/evaluation acceptance test.**

Reproduction commands (all non-operating):

```sh
./tool/flutterw analyze --no-pub
./tool/flutterw test --no-pub --reporter expanded
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=.:tool python3 -m unittest tool.test_essay_long_criteria.LongCriteriaTests tool.test_essay_long_criteria.LongCriteriaAsyncTests tool.test_essay_live_worker tool.test_essay_reviewed_runtime tool.test_essay_async_runtime tool.test_essay_material_execution tool.test_essay_session_retry tool.test_essay_queue_continuation tool.test_cloudflare_stage tool.test_mixed_math_checkpoint tool.test_material_runtime tool.test_essay_retry_feedback tool.test_essay_failure_observation
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=.:tool python3 tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin
ESSAY_ASYNC_TEST=1 ESSAY_TEST_OBSERVATION=1 PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=.:tool python3 tool/test_essay_exam_credit.py --pg-bin /opt/homebrew/opt/postgresql@17/bin --surface-only
python3 tool/check_wiki_handoff.py
```

One old restore fixture incorrectly transitioned a completed question back to failed. It now exercises the valid processing → failed → completed sequence; the new stability test explicitly rejects completed-result regression. Concurrent pre-retry reads are drained before the acknowledged retry's fresh observation. Private input/package replay files were removed after the bounded offline preflight. Existing `.fvmrc` and all earlier branches/worktrees are preserved. No store upload or release-branch merge.
