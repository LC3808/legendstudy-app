# Essay evaluation stability P0 — 2026-10-29

Status: Production read RPC verification and approved Worker deployment PASS (20:25 KST); Observation V1 iOS25 QA build now ready; installation/retry acceptance still pending. Original evaluator/HTTP causes remain unresolved. See the operating closeout below. Historical predeployment status follows. Branch `codex/essay-evaluation-stability-p0-20261029`, starting from `14bbc5cbf228c5c6ee26a9cb0524084924ce9ecc`. Latest Owner urgent directive and IMG_1292–1295 supersede the earlier device QA handoff for this scope. At the initial implementation stage, Production deployment, evaluation, Credit mutation and History repair were not authorized. The later explicit Owner deployment authorization below supersedes only the deployment gate.

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

## Approval package — historical predeployment state

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


## Production verification and deployment — 2026-10-29 20:25 KST

Owner explicitly assigned Codex the operating verification/deployment and clarified the SQL order: **install → verify → rollback → install**. The final install was already present when Codex connected. No SQL reinstall, rollback, migration, RLS change, APP build or evaluation was executed by Codex. Existing [quality and scope decisions](decisions.md) and the seven preservation answers above remain unchanged.

### Read RPCs — PASS

All three exact signatures exist in LegendStudy `stlhijzpjfgwwdgunlsd`: `essay_exam_request_status(uuid,uuid)`, `essay_exam_observation(uuid)`, `essay_exam_question_result(uuid,uuid)`. Every `pg_proc.prosrc` body matches the approved install file byte for byte. All use owner `postgres`, SECURITY DEFINER and empty fixed search_path. Authenticated EXECUTE=true; anon/service_role=false. Existing lifecycle gate and account owner checks remain in every body.

Ran all four SELECT statements in verify.sql. Production functional probes used SELECT calls with transaction-local auth claims and the actual authenticated database role; this tests live SQL authorization, **not a browser login/JWT transport or iPhone test**. Owner request-key lookup returned the existing KHU run. Observation returned official **논제 1 failed / 논제 2 completed**, generation9. The completed-question API returned exactly one answer/result for 논제2, with run state still reserved and local review/telemetry fields absent. Failed 논제1 returned PT409. A different active account returned PT404 for observation/result and found=false for request lookup. Anonymous and service role execution returned 42501.

Supabase advisor reports the intentional authenticated SECURITY DEFINER exposure of these APIs; the explicit owner/lifecycle predicate and denied anon/service grants are verified rather than removing the intended API. No broader advisor remediation was performed. [Advisor explanation](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

### Data invariance — PASS within this execution window

Pre/post deployment hashes are identical for both complete run rows, frozen snapshots, results, all checkpoints, retry requests, the owner's run history and full owner Credit ledger. This comparison begins after Owner's final install; it does not claim a pre-install byte snapshot existed.

- KHU `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1`: reserved, 논제1 failed, 논제2 completed, original failure plus9 explicit retry generations preserved. Exactly one reserve (balance0/reserved+1), no consume/release/refund. Lease expired; no active retry lease. Same owner/exam run count1.
- SWU `6ef28b49-12a5-4825-886d-548f0d9897df`: completed, existing result preserved; one reserve and one consume (net1 Credit used), same owner/exam run count1, no accepted follow-up run observed. Original rejected submission HTTP cause remains unknown.
- No new evaluation, retry, claim, refund, reservation release or Provider call was issued. Neither incident was repaired by changing its stored state.

[Redacted verification receipt and invariant hashes](../tool/cloudflare_essay/p0-production-verification-20261029.json) contains no answer text, authentication material or Provider output.

### Worker deployment — PASS

Actual predeployment API version: `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4` at100%; fetched before upload, not inferred from Wiki. New version **`a462a9a8-4842-4bf9-84d7-7dc9210cedba`**, deployment **`15f1d547-bd9b-4549-976e-19663864c2df`**, **2026-10-29 20:25:25 KST / 100%**. Source bytes pinned to approved Git `2af8f6706a0346721815faaf5ec52ec1b5bfccac` (code94d9f4d; prior retry feedback included).

Downloaded the complete existing Production72-module bundle. Replaced only `essay_lab/live_worker.py`, `essay_lab/reviewed_runtime.py`, `essay_lab/cloudflare_runtime.py`; added `essay_lab/retry_feedback.py`. **69 existing modules unchanged, 3 changed, 1 added =73**. This preserves the full Production Registry, prompts, evaluator contracts, entry/queue handlers and SDK. New diagnostics append through existing lease/writer fences; bounded same-question prior validation feedback does not alter acceptance thresholds, Provider dispatch count or settlement. Unknown transport still reconciles. Existing successful checkpoints are not retried.

All14 bindings preserved;5 secret bindings inherited without reading/replacing their values. Compatibility date2026-10-13, Python flags, CPU30000ms, runtime/handlers, placement, tags, tail/log settings, queue settings and disabled workers.dev/preview unchanged. Only version/deployment descriptive annotations changed as expected. Deployment guard initially detected that expected annotation change after upload; field-by-field comparison confirmed no operating setting drift before activation.

Independent postdeployment API read confirmed100%; re-downloaded all73 modules and matched names/MIME/SHA256 against the exact intended bundle. Ran **74 tests again against the downloaded Production Python modules**, all PASS with synthetic transports only. Predeployment74 tests and isolated PostgreSQL async/Credit/read-API/security/rollback suite also PASS. Old version remains retrievable. No real Provider, evaluation endpoint, queue probe or forced queue retry was used; live evaluation acceptance is NOT TESTED. APP and WEB retain their shared Backend and unchanged Gateway/Credit/History contracts.

### APP activation and rollback

`ESSAY_OBSERVATION_V1_ENABLED` is a compile-time Dart flag, currently false in the preserved local build config and iOS24 build. RPC prerequisites are now verified. Existing-key recovery can use its installed RPC; richer observations/partial-result actions require a **new APP build** with the flag true. No flag/build/store change occurred in this task.

After separate build authorization, copy the existing private config to another ignored local config, set only `ESSAY_OBSERVATION_V1_ENABLED=true`, then run `./tool/device-qa --config <that-local-config> --check` and `./tool/device-qa --config <that-local-config> --build-name 1.0.1 --build-number <next-unused-number>`. Preserve existing identifiers/signing/settings, record source SHA and run real device read-only acceptance before any separately approved retry. Do not publish config secrets or submit to stores automatically.

Worker rollback target is the **live-pinned previous version `451b8cae-f603-48e9-9ca9-8ccc16b4e3d4`**. POST the existing Cloudflare script deployments endpoint with `{"strategy":"percentage","versions":[{"version_id":"451b8cae-f603-48e9-9ca9-8ccc16b4e3d4","percentage":100}]}`, then independently verify active version/settings. Do not run rollback for healthy deployment. This changes no DB data.

RPC rollback uses only the existing rollback.sql after disabling the APP flag (currently already OFF); because it is compile-time, any future enabled deployed APP must first be replaced/disabled appropriately. Never run install/verify/rollback as a normal three-step installation. No rollback was necessary or executed.

Remaining: KHU 논제1 retry needs separate Owner approval; historical failure reason cannot be reconstructed from missing receipts. SWU original HTTP failure remains unresolved. APP flag-enabled rebuild/device acceptance and real evaluation acceptance are not performed. Git follow-up contains deployment evidence/Wiki only; existing `.fvmrc` preserved, no release merge.


## Observation V1 iOS QA build 25 — 2026-10-29

Owner subsequently approved APP-only Observation activation, full regression and signed iOS **1.0.1(25)**. This supersedes the OFF/build-pending statement for the new QA artifact only. Default config remains unchanged. No operating SQL/Worker/Credit/History mutation, existing-run retry, Provider call, device installation or store submission occurred.

- Dedicated ignored `config/observation-v1-qa.local.json` copies the existing private config and changes only `ESSAY_OBSERVATION_V1_ENABLED=true`. Existing `config/store-rc.local.json` and `.fvmrc` are preserved. No credentials committed.
- `tool/device-qa::verify_observation_define` checks the base64 Flutter `DART_DEFINES` in Generated.xcconfig against the selected config and records the verified flag in the receipt. Compiled Observation/Google/Apple/Kakao=true. Existing Bundle ID `com.legendstudy.app`, signing team, native URL schemes and entitlements match preserved24.
- No production UI source rewrite. Existing shared observation store, canonical labels, completed-only result actions and server-authorized failed-only retry are enabled. Whole reserved run remains reserved; failed refresh preserves confirmed success. Request-key recovery performs its read lookup before any replay.
- Updated three APP test files to exercise the selected flag path and the formerly disabled result action. Added all-five-state preservation, completed partial-result RPC, failed-result denial and pre-request account mismatch checks. Existing restore/duplicate-submit/Credit consent/native UI/OCR/growth tests remain in the full suite.
- Live read-only DB functions rechecked: same KHU run restored by key; **논제1 failed / 논제2 completed** in official order; 논제2 completed_question projection. Previous operating ACL/foreign/anon/failed-result tests remain PASS. SQL role/claims verification is not real iPhone Auth/HTTP acceptance. Post-read run/snapshot/result/checkpoint/retry/history/ledger hashes still match the earlier Production baseline.
- Production Worker stays `a462a9a8-4842-4bf9-84d7-7dc9210cedba`; no deployment in this APP task.

### Verification and artifact

Flutter **3.47.6 stable**. Analyze **0 issues**. Full Flutter suite with Observation=true: **1188 PASS / 7 existing SKIP / 0 FAIL**. Focused ON25/OFF25 PASS; Python build-config4 PASS. The initial ON run exposed the old OFF-only disabled-button assertion; the fixture now checks the expected state in both modes, followed by a clean full rerun. Skipped optional fixtures/live checks are not counted as PASS.

Build source SHA: **`9188c9bd9aaa242efdea59a4e7f0813affd5f7cd`**, same P0 branch. `./tool/device-qa --config config/observation-v1-qa.local.json --build-name 1.0.1 --build-number 25`; Xcode47.9s, signed artifact36.7MB; codesign deep/strict verification PASS. Build tool records source SHA before compilation; following documentation commits do not change the built APP.

Stable install artifact:
`/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-observation-25/Runner.app`

Receipt: same directory `device-qa-receipt.json`; [committed sanitized receipt](../tool/observation-v1-qa-build-20261029.json). App.framework SHA256: `bcce277563d9dcca5f95079d59e9c14a9cc16b3cd9314ecdd016cf703cd61363`. Standard `build/ios/iphoneos/Runner.app` also contains25.

Preserved24:
`/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-preserved-24/Runner.app`

Preserved24 receipt/hash verified unchanged (`73aad5741141eee7a63a6737dca5ca967add882d7c7b8bd58affbca0197aca09`). Install25 with Xcode Devices and Simulators on an already provisioned device. No IPA/store upload is implied. Real iPhone result navigation, resume and social authentication remain **NOT TESTED**. Do not tap retry or submit an evaluation without the separate Owner approval for that operation.

Rollback the APP by reinstalling preserved24 (flag OFF), or rebuild using the unchanged default config and a new appropriate build number. No DB function drop, Worker rollback or data repair is needed for an APP-only rollback. Existing failed KHU question and SWU historical HTTP cause remain unresolved; this is observability activation, not successful re-evaluation evidence.

Build warning: existing flutter_tts Swift Package Manager adoption warning is nonblocking; no dependency upgrade was made.


## Owner-authorized recovery attempt — 2026-10-29 20:56 KST

**Actual recovery: FAIL; preservation: PASS.** This section supersedes the earlier “no retry performed” status for this later Owner directive only. Existing product/ownership/Credit preservation decisions above remain unchanged. Owner authorized one KHU retry, and at most one further retry **after fixing the cause**. SWU submission and additional Worker/DB/RPC deployment were not authorized.

### Existing KHU run and actual execution

- Same run `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1`, exam `51e7299e-0ae7-5e6d-9d37-a46718be76bb`. Before execution, generations 10–12 already existed and each recorded `PROVIDER_REJECTED`, stage `provider`, HTTP **429**. This does not establish the cause of older generations without diagnostics.
- Used the signed-in Owner's official WEB **다시 시도 · 0 크레딧** action, not SQL impersonation or direct state edits. One request created generation **13** at `2026-10-29T11:56:49.185520Z`, attempts `{"1":13}`. Snapshot index1 is official **논제1** (`abb351b6-d462-5916-a03a-956c964f6359`); index0 is **논제2** (`92a9044c-9eaa-58d8-b4e9-365b2e9a02f0`).
- `q1-a13-execution-failure`: `PROVIDER_REJECTED / provider / http_status=429 / provider_call=possible`; `q1-retry-13` is failed. The deployed adapter makes one HTTP request and raises on429 without an automatic retry. This task therefore attempted **one Provider generation request**, obtained no successful evaluation response/usage receipt and made **zero independent-review requests**. Provider billing is not established by this receipt. No second recovery attempt was made.
- Failure occurred before exact-quote validation and independent review; no input-validation failure or checkpoint-write failure was recorded for this attempt. HTTP429's quota/rate-limit subtype is **unconfirmed**: the deployed adapter retains status but not the Provider error body/code. Do not label this as an inaccurate-quote or reviewer-rejection case. No quality checks were removed.
- Owner-scoped `essay_exam_observation` returns generation13, run **reserved**, 논제1 **failed**, 논제2 **completed**, `retry_allowed=true`. Contract eligibility does not mean the Provider fault is fixed; retry2 is withheld.
- All **7** existing `q0`/`q0-*` checkpoint payload hashes are unchanged, including q0 `aaeeaf44823695d0dd3d0f24b0e096d6`, q0-reviewed `e462a0333948e3bc2a9783d819bbb0d5`, usage `844849d7cdfd45f66ebae0a49e574d8e`. No completed question was reevaluated.
- Run row hash `104f7d4e9dcf200727f1ed8494a9a0fd`, frozen answer hash `5d3eb9db1e9e886d14bd03ddc2a77003`, owner History hash `bd60a973a047828fbb3f199c2d7d78ed`, owner Ledger hash `489c7b005bd994072909fcf1e4a62836` are unchanged. Same exam has one run. Only authorized retry/claim/failure checkpoint facts were appended.
- Credit remains exactly **one reserve (+1 reserved, 0 balance delta)**, no consume/release/refund/new Credit. Required completion/one settlement was **not achieved**.

### SWU diagnosis and bounded APP fix

- Existing run `6ef28b49-12a5-4825-886d-548f0d9897df` remains completed; frozen answers/result/checkpoints/History hashes unchanged, one reserve and one consume, same exam one run. No SWU submission or Provider request.
- Read-only transaction invoking the current `essay_exam_quote` with this exact owned parent and its frozen canonical question set returned `essay-exam-quote-v1`, **included / 0 credits**. Both canonical IDs are `a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6`, `d0862954-4d0d-5811-9b48-5dc8e319634d`. Current preflight/package/parent/14-day/free-use checks pass. This is not a successful HTTP submit or Worker acceptance test.
- Read-only device inspection confirms iPhone12ProMax already has **1.0.1(25)**. No matching SWU availability/quote/submit diagnostic files were found in its native draft directory; no matching registered-exam parent pending file was found. Do not infer that no request ever happened: older builds or alternate catalog keys may lack this evidence. No app data was overwritten and no reinstall was performed.
- Traced APP parent-relative revision + exact frozen set -> quote -> durable key -> submit; WEB gateway validates parent, revisions, session readiness and source consent. Original failing HTTP status/body/key is unavailable. The Owner symptom's **historical root cause remains unconfirmed**; request revision/payload at that moment cannot be reconstructed from current state alone.
- Reproduced a separate diagnostic defect: HTTP409/503 symbolic server codes were overwritten by generic `REQUEST_UNCONFIRMED` in `ExamSubmissionGateway.request()`. Preserve the safe server code while retaining the unconfirmed phase and pending key; no retry, reservation or submission policy changes. Tests cover one HTTP request, retained key/code/status, and no answer/token leakage. This improves evidence, **not a claim that SWU submission is repaired**.

### History display fix

- `SharedEssayHistory.read()` metadata composition appended Registry's complete official title as `session`, duplicating university/year/kind/track. `essayHistoryExamTitle()` in `exam_presentation.dart` now normalizes only display fields. `shared_history.dart` uses it with resolved university (stored university fallback).
- KHU `2024학년도 모의논술 · 인문·체육계`, SWU `2026학년도 수시논술 · 인문사회계열`, Konkuk `2023학년도 수시논술 · 인문사회Ⅰ`; distinct HUFS T2 / Kwangwoon1교시 remain. Registry, official IDs/order, answers, rounds, dates and states unchanged. Existing writer-title rendering is untouched.
- Changed APP files: `exam_presentation.dart`, `shared_history.dart`, `exam_submission.dart`; tests: `exam_presentation_test.dart`, `essay_stability_p0_test.dart`. No Worker, Gateway, SQL or Auth configuration changes.

### Verification and remaining work

Code commit: `53ec2d2583c92d7db0529f8f241b07d9b37bfa7b`. Flutter Analyze **PASS / zero issues**; full Flutter **1190 PASS / 7 existing SKIP**, Observation flag ON; focused presentation/status/rewrite tests **28 PASS**. Worker synthetic regression **74 PASS**. Isolated PostgreSQL Credit **18 PASS** and async retry/observation suite **PASS** (8-concurrent-key single generation, successful checkpoint preservation, exactly-one settlement, free rewrite, owner/read security, rollback). Production completion and settlement **FAIL/not achieved**; SWU real submit and device validation of these new APP changes **NOT TESTED**. Existing builds24/25 and untracked `.fvmrc` are preserved. No new build/store submission in this task. The display/diagnostic fixes need a subsequent QA build before device validation.

The remaining operational blocker is Provider HTTP429; inspect the active Provider project's billing/quota/rate-limit evidence before choosing a fix. Current logs cannot distinguish these causes. Changes to Provider limits/billing or another Worker deployment are outside this directive's authorized operation. If bounded Provider error subtype instrumentation is required, prepare/test that separate change for approval; do not add automatic retries. One further KHU retry remains within the Owner cap only **after cause correction**, never as a blind repeat. SWU real submission still requires separate approval.

Rollback: revert only this task's APP code commit on the working branch; retain installed build25 until a new approved QA build. Do not delete retry13 or alter History/Ledger to undo an operational attempt. Worker remains `a462a9a8-4842-4bf9-84d7-7dc9210cedba`; no DB/RPC rollback is indicated.


## Funded Provider recovery attempt — 2026-10-29 21:17 KST

**Recovery FAIL; Provider access restored for this attempt; successful data preserved.** Owner reported a $100 API credit top-up and authorized exactly one further KHU failed-question retry. No other exam/run, Worker deployment, schema change, manual Credit adjustment or new run was authorized.

Before execution, directly observed **$99.81** available in the OpenAI **LegendStudy Lab** organization's Billing overview. Its Default project `proj_7wSRdnxAdgzOTB8sxWGzmuTw` lists active `legendstudy-release`; Owner explicitly confirmed this is the key stored in the Worker's `ESSAY_PROVIDER_KEY`. Cloudflare's secret value itself is not readable. Live Worker **a462a9a8-4842-4bf9-84d7-7dc9210cedba / 100%**, all73 module hashes and existing settings/bindings matched the approved deployment. Provider/model remained **openai / gpt-5.6-sol**. No credential or billing settings changed by Codex.

The same KHU run `4e26b5b6-e605-4c87-a6ad-ce5ed70c31f1` was reserved with canonical 논제1 failed, 논제2 completed, reserve1 only, retry_allowed true. Generation13's lease expired at `12:11:49Z`. The official signed-in WEB **다시 시도 · 0 크레딧** button was executed **once**, creating generation **14** at `2026-10-29T12:17:52.668162Z`, attempts `{"1":14}`. No second request, queue redispatch or manual state change.

### Result and failure evidence

- Provider generated a response successfully; **no HTTP429 or other Provider execution failure recorded** for generation14. One generation receipt, model gpt-5.6-sol, input **12,897** tokens, output **5,530** tokens, latency **67,409 ms**. `cost_amount` is null; no monetary cost is inferred. Independent review was not started. Exact successful HTTP status was not persisted; there is no Provider HTTP error body for this attempt.
- `q1-a14-validation-failure-7c4c69b8bae0a883e5d06ab3ff04cfebfa9ee082837d623b39677fac4b860f28` records **EXACT_QUOTE**. `live_worker.py` validates integer/in-bounds student-answer offsets and exact equality of `answer[start:end]` with the generated quote. This attempt failed **student-answer quotation/offset validation**, not the official-criteria length gate, HTTP429, or independent-review rejection. Which quote/offset failed cannot be recovered from this symbolic receipt alone.
- `q1-a14-validation-feedback` preserves `question-retry-feedback-v1 / EXACT_QUOTE`; `q1-retry-14-usage` and failed `q1-retry-14` are durable. No checks were weakened. Current observation: **generation14 / reserved / 논제1 failed / 논제2 completed / retry_allowed true**. Despite contract eligibility, no further retry is authorized in this directive.
- All **7** original 논제2 (`q0`/`q0-*`) payload hashes match the pre-retry snapshot. Frozen answers, run row, owner History and Ledger hashes remain the same as generation13 verification above. Other-run History and other-decision Ledger aggregates also match. Same exam has exactly one run. Only authorized generation14 retry/claim/usage/failure facts were added.
- Credit: original **reserve1** remains, balance delta **0**, consume/release/refund **0**. Successful one-Credit settlement was **not achieved**; additional student Credit charge **0**. Provider API billing is separate from student Credit.
- Signed-in WEB shows **1/2 complete / 재처리가 필요해요**. Owner-scoped APP observation RPC returns the same canonical failed/completed state; question-result RPC returns only the preserved 논제2 result (`completed_question`, result_count1). APP physical navigation was not performed, and no complete two-question result exists.

### Handoff

No APP code/build/install, Worker, DB schema/RPC or Auth change. Seoul Women's University untouched. No store submission. The old HTTP429 did not recur after funding, which is consistent with the Owner's balance explanation but does not retroactively prove its exact subtype. Remaining recovery work is the student-answer quotation/offset failure: inspect/reproduce the validation issue without weakening quality, then obtain the appropriate approval for any Worker deployment and another real retry. The one retry authorized here is exhausted. Never undo generation14 by editing History or Ledger; preserve the existing reservation/result. Documentation-only handoff check required; no new code regression suite needed.


## SWU free rewrite routing fix — 2026-10-29

**Root cause confirmed for the 21:27 device failure; APP fix/tests PASS; operating free submission NOT TESTED / awaiting Owner approval.** This new evidence supersedes the earlier unknown-cause status for this specific later request only. It does not identify the older “server not responding” event.

### Exact operating evidence

Read-only iPhone25 native diagnostics: availability at `12:26:59.554162Z` returned HTTP200. **quote** at `12:27:01.295148Z` returned **HTTP422 / ADDITIONAL_CYCLE_UNAVAILABLE**, `parentId=null`, no request key. There was no submit diagnostic and no new SWU run. This is a quote rejection before evaluation submission/key creation, not a Provider failure. The installed25 diagnostic did not capture previousPaidRunId or full payload. Its presence is established by the only Gateway branch returning this error and the APP `_additional` route; the exact predecessor is reconstructed from the owned run and its local draft namespace, not claimed as a captured raw HTTP body.

Actual Production Pages project `legendstudy-lab` / `lab.legendstudy.com` has `ESSAY_CONTINUOUS_CYCLES_ENABLED=false`, `ESSAY_CREDIT_SOURCE_ENABLED=true` (Cloudflare API read only). Shared Gateway `functions/api/essay/exam.ts` rejects non-null previousPaidRunId when paid continuous cycles are disabled. Meanwhile DB history returns `continuous_cycles_supported=true` (DB capability) and `free_rewrite_available=true`. APP's upper result button previously used the first flag alone and always called `openWriter(true)`, selecting `_additional=true`, parentId=null and previousPaidRunId=root. **Available free eligibility was ignored by that prominent entry.** The lower existing “다시 써보기” action used false, so the two entries had inconsistent billing routes. No server flag was enabled to bypass this.

SWU parent remains `6ef28b49-12a5-4825-886d-548f0d9897df`, exam `6679b5ff-d797-53c9-8a2a-424375d7210c`, completed03:41:38Z, parent_id null. Canonical questions `a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6` / `d0862954-4d0d-5811-9b48-5dc8e319634d`, original revisions **1/1**. Device has edited TEXT drafts in this parent's **additional** namespace, revisions **9/17**, lengths **1682/1660**, both hashes differ from original answers. No corresponding included/rewrite drafts were found. Student text is not committed or printed in the report.

A current read-only transaction calls the existing quote contract with exact parent+question set: **included / 0 Credit**. The 14-day limit, one-free-use eligibility, owner, frozen canonical set and runtime preflight pass. Corrected free requests retain that parent, omit previousPaidRunId, and use existing parent-relative revision conversion (**2/2** for these two changed bodies), not local edit counters9/17. No actual submit or new run was issued to verify this.

### Minimal changes

Code commit **9929b95febda9360fdfa6b240f41bf41264c060e**:

- `lib/features/essay/shared_history_page.dart`: `EssayFollowupAction` shows **다시 써보기 · 무료 재첨삭** when free eligibility exists. `_Result.build/openWriter` refreshes owner History and prefers the newly confirmed included entitlement even if the initial button was stale. Existing explicit paid confirmation remains for ineligible users; the server still decides final rights.
- `lib/features/essay/exam_rewrite.dart`: `recoverIncludedEssayDraft` copies stranded TEXT edits from the same parent's additional namespace only into an empty included namespace. It retains the source, refuses image drafts, existing destination edits, ineligible/paid routes and any unresolved paid-request key. Existing `examRewriteAnswers` still enforces exact question set and original-relative revisions.
- `lib/features/essay/source_catalog_page.dart`: `SourceCatalogPage.loadCatalog` invokes recovery after owned History catalog validation, checks active owner, and restores both canonical questions before writing/review. `ExamSubmissionPanelState.submit` rejection copy identifies unavailable paid followups rather than implying a generic submit failure. Existing quote/consent/idempotency Gateway flow unchanged.
- `lib/features/essay/exam_submission.dart`: `record` also retains safe previousPaidRunId to distinguish free/paid routing in subsequent diagnostics. No student text/token added.
- `test/device_qa_second_test.dart`, `test/essay_stability_p0_test.dart`: free-over-paid action, stranded draft recovery/source preservation, no destination overwrite, unresolved-key refusal, free/paid payloads, parent/canonical/revision, exact HTTP422 quote code/predecessor and no submit.

### Verification, preservation and release boundary

Flutter Analyze **PASS / zero issues**. Full Flutter with Observation ON: **1193 PASS / 7 existing SKIP**. Focused suite before the final diagnostic test:26PASS; final diagnostic test included in full suite. Isolated PostgreSQL Credit **18 PASS**; async/observation contract suite **PASS**, including included rewrite, exactly-once settlement, duplicate keys, original-result preservation and result retrieval through synthetic Provider transport. These are isolated acceptance tests, not Production submission. No Worker code changed, so its prior74PASS is not reported as newly run here.

SWU before/after run hash `198f944d1a45904f25490271b5ba5322`, snapshot `042f9a6a3c3418644430884bb233b936`, result `1e596b01ba5b48f17b8c14a07d360041`, checkpoints `653029d0f5726874086079c6ed79a778` unchanged. Same exam one run; original reserve1+consume1 retained, no new Credit operation. Device reads only; no draft migration executed on the actual iPhone, no new build/install, Provider call, DB/RPC/Worker/Auth change or store submission. Existing builds and `.fvmrc` preserved.

Separate observation while comparing the existing incident records: KHU now has **generation15** created12:23:28Z and completed12:24:23Z, one reserve/consume. This was **not executed by this Codex task**; the initiator is not established by the inspected records. Consequently the whole-account History/Ledger hashes differ from earlier snapshots; only the SWU-specific unchanged hashes are asserted here. The earlier g14 failure report remains valid at its observation time. No KHU follow-up action was taken.

Remaining: create/install a QA build containing this code, then obtain explicit approval for **one actual free SWU rewrite** using the preserved two revised answers and original parent. Until then, server submission acceptance/new child round/Provider completion/device result navigation remain NOT TESTED. Paid followup deployment remains separate: DB capability is not proof that the Gateway feature flag is enabled. No APP-specific evaluation bypass was introduced. Rollback by reverting this APP code commit and retaining the installed25 build; copied local drafts should be retained, not deleted.
