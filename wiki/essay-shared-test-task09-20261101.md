# TASK09 — shared TEST backend and Owner review

2026-11-01. **PARTIAL / HOLD — not READY FOR OWNER REVIEW.** Real evaluation Gateway/E2E and beta runtime remain blocked. Continues [TASK08](essay-beta-integration-task08-20261101.md), preserving its policy and seven preservation-review answers. No new storage semantics or evaluation/Credit system introduced.

## Version and boundary

APP baseline `26248ef229894093038ca51ed53eae7af4cdf933`, branch `codex/essay-evaluation-stability-p0-20261029`; WEB baseline `0b345417fe6f973d5f567686b87bb49230c43c05`, branch `codex/web-app-release-20261024`. Final documentation commits are discoverable in Git, not fixed current HEAD claims. Existing `.fvmrc` preserved. Supabase CLI `.temp` and local credentials are untracked and excluded.

Shared backend: existing **legendstudy-iap-sandbox**, `kpqbedylxlyntrrfybpn`, URL `https://kpqbedylxlyntrrfybpn.supabase.co`. Production `stlhijzpjfgwwdgunlsd` was not mutated. No production Worker/WEB/Auth/Credit/History changes, Provider calls, payments or store submissions.

## Completed and verified

| Scope | Result / evidence |
|---|---|
| TEST schema | Admin gate, notices, reviewed Registry/package/API prerequisites, checkpoints/history, feedback installed; candidate README records order |
| Ownership | Owner-preserving local schema replay verified provider-body preservation and limited postgres EXECUTE; no SET membership remains from adapter |
| TEST Auth | Separate synthetic Owner and student login via API; Owner Chrome email login PASS |
| Notice | Owner save/list PASS; student admin403, guest blocked; publication and APP-channel read → WEB unread0 via RPC |
| Feedback | Student TEST bug submission PASS; same idempotency key same row; changed payload conflict; Owner list PASS; student403/guest denied |
| Browser | Owner notices detail and feedback listing/statistics visible; one TEST display-error report; no real evaluation reference attached |
| Existing TEST Credit | Original 2 rows retained, fingerprint `641595bc1e0e618c2846a0a62f5b550d`; one normal TEST signup_bonus_v1 +3 created by existing login flow; no paid/beta use |
| Preview restriction | All routes, login, admin, API and assets401 without code; valid host-bound8h cookie200, no-store/noindex, Supabase roles still enforced |
| WEB automatic | TypeScript and production build PASS (143 routes); focused lint PASS; full tests1471 PASS/4 SKIP, 205 files PASS/3 skipped |
| Local DB | Real-admin-gate notice test PASS: missing/expired/mismatched JWT, scheduling, expiry, channels/read state, denial, rollback |

Initial TEST Preview deployment used production API-only `_routes.json`, leaving static pages ungated. Detected by unauthenticated HTTP200, replaced with all-route restriction, then old TEST deployment deleted. No production deployment replaced. Current deployment `095d922a-7301-48ac-b23f-2063b7d30518`. Separate TEST prepare script never changes production `public/_routes.json`.

## Owner access (limited review only)

Preview: https://legendstudy-task09.pages.dev

1. Enter private Preview code stored locally in `/Users/woojinchang/.codex/legendstudy-task09-test/preview-access-key.txt`.
2. Log in with synthetic TEST Owner or student credentials in `/Users/woojinchang/.codex/legendstudy-task09-test/test-accounts.json` (0600). Do not use production credentials, paste secrets in Wiki, or share these files publicly.
3. Owner: `/admin/notices/` can view/edit the TEST notice; `/admin/essay-feedback/` → 조회 shows the TEST report. Student: notices/read state and non-evaluation feedback only. RPC verifies student administrator denial; student browser flow NOT_TESTED.
4. No evaluation/paid checkout/beta use should be attempted. Registry is empty; an available UI route does not establish feature readiness.

APP existing signed iOS1.0.1(33): `/Users/woojinchang/.codex/worktrees/app-final-integration-20261028/legendstudy-service-app-20261022/build/ios/qa-task08-test-33/Runner.app`.
Android1.0.1(33): same repository `/build/android/qa-task08-test-33/app-release.apk`.
Build source72d53a0; preserved unchanged. Both target same TEST Supabase, but writes/evaluation remain disabled and APP TEST Gateway fails closed. **Not a full TASK09 acceptance build.** iOS uses existing Bundle ID and would replace the installed app; no device installation performed. Do not represent API channel tests as APP device synchronization.

## Remaining blockers and next work

1. **TEST schema predecessor gap:** canonical old-beta allocator install requires `math_session_submit` and session tables missing from this sandbox. Exact definition checks stop installation. Need reconstruct/review full canonical predecessor DDL/ownership/RLS, replay on ownership-equivalent local clone, then shared TEST. Never use test stubs or bypass financial guards. Daily-v2, admin-beta, Analytics reporting and operations integration not installed here.
2. **Gateway:** no isolated TEST Worker/queue/provider configuration deployed. Existing APP guard rejects TEST evaluation. Production-bound WEB/Gateway host configuration needs scoped TEST configuration review. Verified Registry/packages must be seeded separately without personal answer/history copying. No synthetic results used to claim E2E.
3. **Provider approval:** no actual call made. Only after Gateway/package ready, calculate concrete run/model/token/call budget and request Owner approval. No blanket cost estimate asserted.
4. **APP build:** existing33 preserved; enable allowed TEST writes and scoped Gateway in a new build only after backend prerequisites verified. Physical iOS/Android, OCR, Draft/result sync NOT_TESTED.
5. **Analytics:** Firebase/GA4 real receipt remains BLOCKED; existing31-event contract unchanged. Owner Firebase config/project connection needed; do not create a project. SQL aggregates not installed in shared TEST.
6. **Payment:** TEST/LIVE/IAP contracts unchanged; Sandbox purchase/store availability NOT_TESTED. No transactions performed.
7. Real beta1/day, midnight/no-carry, failure restore, min14days/2026-11-11 00KST rewrite expiry and shared APP/WEB quantities: prior isolated TASK08 evidence retained, **shared TEST E2E BLOCKED**.

## Recovery and handoff

Preview can be disabled/its access secret rotated without production impact. Retain local build33 and all prior artifacts. Do not drop the reused sandbox: it has preexisting IAP/Credit data. Review canonical rollback dependency order and preserve audit data before any TEST schema rollback. No production rollback needed.

Implementation: APP `supabase/candidates/task09_shared_test/`; WEB `cloudflare/test-preview-access.ts`, its10 tests, `functions/_middleware.ts`, `scripts/prepare-private-test-preview.mjs`, TEST-only root banner. UI runtime source identical to verified build apart from subsequent documentation. Credentials never committed.

Owner final release approval remains pending. This report distinguishes working notice/feedback Preview from unfinished full-service acceptance environment.
