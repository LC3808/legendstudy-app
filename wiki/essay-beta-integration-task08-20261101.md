# TASK08 — Owner pre-release integration

Status: **PARTIAL / HOLD — not READY FOR OWNER REVIEW**. Local administrator review is available; the shared APP/WEB evaluation test environment is incomplete. No production deployment, SQL, Auth, Worker, Credit, History, Provider call, payment or device install was performed.

## Baseline and preservation

APP: LC3808/legendstudy-app, `codex/essay-evaluation-stability-p0-20261029`, baseline `48e79c4`, code `72d53a0`. WEB: LC3808/legendstudy-lab, `codex/web-app-release-20261024`, baseline `a4e16c4`, code `068c07c`. Baseline local/origin matched. Existing untracked `.fvmrc`, Claude Analytics, previous builds and production configuration preserved. Final documentation SHA is in Git history, not a permanent current-HEAD assertion.

Canonical policies: [TASK07](essay-beta-release-readiness-task07-20261101.md), [beta](essay-beta-daily-v2.md), [Analytics](analytics-v1-implementation-20261030.md), [longitudinal preservation](longitudinal-learning-admissions-data-strategy.md). Owner review precedes a separate production approval.

Seven preservation-review answers: (1) original fact timestamps retained; (2) exam/parent/package context retained; (3) no existing fact UPDATE; (4) identity continues through existing auth/account IDs; (5) no new Learning/Decision/Outcome fact store; (6) synthetic local accounts only, no student answer copy; (7) derived reporting scopes and unknown cost are explicit, raw receipts/versions retained.

## TASK01–07 integration inventory

| Task | APP commit | WEB commit | Dependency / current verdict |
|---|---|---|---|
| 01 notices | 3d562dc | fb7f7df | notices_v1; native list/detail/bell and WEB admin present; local draft save smoke PASS |
| 02 beta | cb3c6c5, 9b91169 | c5300df | essay_beta_daily_v2; production enable pending; daily KST and expiry automated |
| 03 Analytics | d7dba9f, 72d53a0 | d5cd458 | analytics_admin_reporting_20261030; GA4 off, actual reception BLOCKED |
| 04 beta admin | c87a1a2 | 4aaf963 | essay_beta_admin_v1; settings editor capability separate from admin read |
| 05 feedback | 4ba0a4e | 38d2d81 | essay_feedback_v1 + existing feedback table; live deployment pending |
| 06 monitoring | 16a6191 | a4e16c4 | essay_operations_v1; local real RPC read PASS (synthetic facts) |
| 07 readiness | 48e79c4 | baseline unchanged | documented HOLD retained |

These commits are already ancestors, not remerged. Candidate presence is not production deployment evidence. Current production deployment/Worker IDs were not reverified in TASK08; TASK07 recorded Cloudflare authorization HTTP401. Production migration/version claims remain the dated TASK07 observations.

## SQL dependencies and validation

Order: existing auth/account/credit/exam/feedback contracts → `notices_v1` → `essay_beta_daily_v2` → `essay_beta_admin_v1` → `essay_feedback_v1` → `essay_operations_v1` → `analytics_admin_reporting_20261030`.

Feedback requires existing `20260917000100_feedback_operations.sql`; do not replay a historical migration blindly in production. Run each package precheck against actual schema, inspect owner/ACL/signatures, then install/verify only after approval. Analytics now requires modern runs, payment currency and operations receipt views. The integration harness is a synthetic schema test, not proof of production enum/type compatibility.

- Local PostgreSQL17 port55439 database `task08_integration` only.
- `BETA_TEST_DB=task08_integration python3 supabase/candidates/essay_beta_admin_v1/test_runtime.py`: PASS30 plus concurrency/reservation/completion/rewrite and rollback-disable assertions.
- `python supabase/candidates/beta_integration_task08/test_integration.py` (psycopg environment): PASS19 groups. Guarded task08_* DB names; three-question run counts once, legacy mirror dedup, amount/currency/refund/cost assertions, seven report read-only fingerprints, 21 role denials, analytics rollback/fact preservation/reinstall.
- No table/function name collision occurred in this fixture. Existing report RPC replacements are intentional. Analytics private views and derived SELECTs do not write credit/history/run facts.
- Base tests exercise time boundaries and concurrent claims with injected time. Beta settings remain disabled. The synthetic campaign is not the Owner launch configuration.
- Cutoff: 2026-11-11 00:00 KST; no carry; beta rewrite minimum of 14 days and beta end. Signup/paid policy unchanged. Launch start remains Owner decision.

Rollback: disable feature flags before removing APIs. Reverse dependency order using reviewed package rollback files; preserve all grant/attempt/ledger/history facts. For beta with in-flight reservations use disable-only/reconciliation procedure, never delete transactions. Analytics rollback removes derived RPC/views, no CASCADE/fact updates. Integrated analytics removal/reinstall tested; full production rollback is not claimed.

## Analytics contract changes

`analytics_private` combines legacy and modern exam-level projections. One run is one request regardless of checkpoint count. Exact mirrored IDs excluded. Modern parent lineage participates in completion loop. Question latency and legacy reprocess success remain explicitly legacy scoped; completed-after-modern-retry is separate.

Revenue is LIVE KRW gross by paid_at, successful CANCEL refunds by completed_at (all reasons), including later-refunded original orders in gross. Other currencies counted separately without FX. Credit release is not a cash refund. USD ACTUAL and ESTIMATED receipt totals are separate; UNKNOWN remains null, not zero. Undated receipts use run-cohort scope and are excluded from calendar daily cost. GA4 is not a transaction source. Flutter Analytics labels reflect these scopes.

## Local WEB review

URL: http://127.0.0.1:4308 (this Mac only; no remote Preview URL).
Project: `/Users/woojinchang/development/legendstudy-release-20261024`.
Launcher: `/Users/woojinchang/.codex/legendstudy-task08-local/start-web.py`.
Local Supabase: http://127.0.0.1:54321, Docker PostgreSQL54322; config `/tmp/legendstudy-task08-supabase`. Restart with `supabase start --workdir /tmp/legendstudy-task08-supabase --exclude studio,logflare,vector,imgproxy,supavisor,edge-runtime`, then launcher. No evaluation gateway/Worker runs here.

Local QA auth is opt-in and accepts only exact loopback WEB4308 and Supabase54321 origins. Production origin validation unchanged. Page banner explicitly says synthetic isolated review. Analytics disabled. No production credentials copied. Accounts and random passwords are in mode0600 private file `/Users/woojinchang/.codex/legendstudy-task08-local/test-accounts.json`; never commit it.

- owner@task08.example.test: local admin and explicit settings-editor capability.
- student@task08.example.test: ordinary local user.
- Actual local Auth sign-in + admin beta/Analytics RPC200 and student RPC403 PASS.
- Chrome UI: Owner email login, beta settings read, notices draft save, operations five-tab shell and summary read PASS.
- `TASK08 격리 검수 안내` is a local draft only. Existing `Beta QA` is synthetic published notice.
- Screenshot: private local `notices-qa.png`.
- Full notice publish/read sync, feedback submit/admin lifecycle, Safari/mobile and real-device flows NOT_TESTED in TASK08; prior isolated assertions remain separate evidence.
- No catalog/real evaluation gateway means first evaluation/rewrite E2E BLOCKED. Synthetic receipt times are boundary-test data, not production latency benchmarks.

## APP build

1.0.1(33), signed iOS release `com.legendstudy.app`, source72d53a0, codesign deep/strict PASS.
Artifact: `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-task08-test-33/Runner.app`.
Receipt adjacent `receipt.json`; App.framework SHA256 `20392e114c44cd9d9e4a5dc45d8c23c2c33355c1522775386e110e011ddb5fba`.
Compiled defines checked: APP_ENV=test; ObservationV1=true; live writes=false; evaluation requests=false; Analytics=false. Existing TEST project kpqbedylxlyntrrfybpn (not production). Existing social production settings were not modified; this isolated build does not establish social login readiness.

This APP uses the existing remote TEST project, whereas WEB uses local synthetic Supabase. Therefore they are **not a shared full Owner acceptance environment**. No claim of cross-platform sync. Evaluation gateway is fail-closed in TEST. Do not use this build for real evaluation. Install later via Xcode Devices/Apple Configurator to a provisioned device; no installation or TestFlight upload performed. Build32 and older artifacts preserved. Android release APK build and apksigner verification PASS: `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/android/qa-task08-test-33/app-release.apk`. Version1.0.1/code33. No device install or Play upload. Build emits existing Kotlin/SDK/font warnings; visual device validation remains required.

## Automatic verification

| Check | Result | Evidence |
|---|---|---|
| Flutter analyze | PASS 0 issues | /tmp/task08-app-analyze-final.log |
| Flutter full tests | PASS1306, SKIP7 | /tmp/task08-app-test.log |
| Final Analytics tests | PASS23 | /tmp/task08-app-analytics-final.log |
| WEB TypeScript | PASS | /tmp/task08-web-typecheck.log |
| WEB lint | PASS, 5 existing warnings | /tmp/task08-web-lint.log |
| WEB full tests | PASS1461, SKIP4 | /tmp/task08-web-test.log |
| WEB production build | PASS | /tmp/task08-web-build.log |
| SQL base / integration | PASS as scoped above | /tmp/task08-db-base.log, /tmp/task08-integration.log |
| iOS signed release build | PASS | /tmp/task08-ios-build.log |
| Real Provider/payment/device/GA4 | NOT_TESTED/BLOCKED | no authorization/configuration; not replaced by mocks |

## Owner checklist and remaining gates

Local WEB now supports limited admin review: login as Owner, inspect notices/beta/usage/failures/feedback/operations; login as student and confirm admin denial. Draft/save only synthetic records. Record role, URL, action, expected/actual and screenshot. Do not interpret local synthetic counts as actual usage.

Before full Owner APP/WEB review: provide a shared isolated Supabase schema/catalog/fixture result gateway and reachable private URL, build both clients against that environment, verify notices/read state/feedback and actual mock evaluation flow end to end. Current fail-closed TEST APP is not that environment. No production DB workaround is authorized.

Remaining: remote preview hosting authorization; shared test gateway/environment; full user E2E and mobile browsers; actual iOS/Android/OCR/TTS/IAP; GA4 configuration/reception; production-compatible SQL precheck; Owner launch start and final review. These are acceptance gaps, not evidence of a production defect. TASK07 HOLD remains.

Production plan only: after environment completion and Owner acceptance, request separate SQL/deploy approvals, record actual deployment/version rollback targets, apply in dependency order with features disabled, verify role/ledger invariants, deploy approved clients, then separately enable beta. No automatic production action from this report.

Local evidence logs are preserved under `/Users/woojinchang/.codex/legendstudy-task08-local/evidence/`. Wiki handoff check PASS (current-status11980 bytes). Historical APP1-A restore evidence remains in [its feature record](essay-group-1a-20261025.md).
