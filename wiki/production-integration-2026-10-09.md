# Production integration — 2026-10-09

Current local APP closeout: [Oct10 integration](#local-app-branch-integration--2026-10-10).
The Oct09 Production/backend evidence below is historical; latest Unified Wiki owns subsequent runtime state.

**LEGENDSTUDY_PRODUCTION_INTEGRATION: PARTIAL.** This is an integrated APP candidate plus scoped Production backend/data deployment, not an Essay or IAP launch.

## Authority / implemented

Branch `codex/production-integration` starts from Claude IAP `f642de6` (includes Release `e50e072`), merges Codex Account/Data `418d957`, Admin/Credit `4c87231`, Essay runtime `2657952`. Merge conflicts were limited to combined Wiki status/log. Claude visual work is preserved. LAB `2cd74ed07b819e66145e25af6733b8edcc056637` is unchanged; MY/Admin/credit formatter are not reimplemented.

- Account/profile hydration and existing-profile routing fixes are integrated. Google configuration/ambiguous Android cancellation mapping is preserved. Supabase Google/Apple/Kakao providers are enabled; current real-device provider switching, signing SHA and Google Console configuration remain unverified.
- Brand renders while Supabase initializes; Auth-dependent providers/router mount only after initialization. No extra fixed wait. Canonical brand visuals unchanged.
- Existing privacy/terms/refund URLs are connected and HTTP200 verified. Constructor-only unconfigured test fixtures retain explicit empty configuration.
- Search uses one active parent stream with `published_at DESC, id DESC`, including all active years. Removes exam-first/general append ordering and historical 2010 cutoff. Existing title formatter/source titles preserved.
- Native `/lab/essay/history` joins existing Essay attempts/evaluations and Math history/result RPCs, with owner-scoped providers and account-change checks. Bounded recent50 per source and20 evaluations per item; empty/error distinct. No new History DB or WebView. This is a native read surface, **not completion of the native Math upload/submission/rewrite workflow**.
- Existing Claude IAP client reused. Canonical UUID supplied as Store account binding; Google consumables consumed only after verified grant. Purchase provider is watched through page lifetime and recreated on account switch. Unknown/409 replies do not imply success. Verification/completion failures stay pending, unverified purchases are not finished. Store recovery is implemented but only fixture-tested.

## Production-applied / verified

### Materials

Existing crawler/parser/normalizer and controlled insertion reused for missing source posts1713–1719: **7 active essay content rows,78 active resources**,11 advisory quarantine rows (unknown resource kind/expiring source URLs). Source titles/publication timestamps retained; no duplicate existing posts or broad data rewrite. Public recent search and2026 filter HTTP200 returned actual new rows. Raw scraped HTML/signed attachment URLs are not committed. Resource fetching and future automatic schedule are not verified/implemented here.

### IAP (gated)

Migration `20261009000200_iap_verified_credit.sql` applied once with dependency hash guards and atomic migration ledger. File SHA256 `ff03ee2f928d9bad7b37c388657dc03d95dfb9b3e172b4f1973febdd13a9f849`; RPC body MD5 `c216866a95254f1ce3206db9737d38c2`.

`iap_post_verified_purchase` is postgres-owned SECURITY DEFINER, empty search_path, service_role EXECUTE only (anon/authenticated false). Existing canonical credit_post_grant unchanged. No new wallet/table. Origin purchase, provider-specific reason, hashed transaction reference, account/product binding, replay prevention and UTC calendar3-month expiry from Store purchase time. Original entries immutable. Actual IAP grants **0**.

`verify-iap-purchase` version1 ACTIVE, **verify_jwt=true**, anonymous actual HTTP401. Platform auth plus fresh Auth user verification; server independently checks Store transaction/account/SKU/date/environment/revocation. Apple official signed transaction verification + Store Server API; Google Play Developer API + dedicated principal. Four approved SKUs only. Sandbox never posts spendable Production Credit. Management multipart deployment preserves platform JWT checking; disabling it was rejected by automatic approval review and was not used.

**IAP_ENABLED absent=false**. Store secrets/product registrations/real purchases unverified. **Post-grant refund/revocation reconciliation is NOT IMPLEMENTED**; pre-grant rejection is not a refund lifecycle. Keep gated until that implementation and actual Store acceptance. See [IAP acceptance/config](../supabase/verification/iap/README.md).

Migration010 was already applied and not reapplied. Target005 absent/HOLD. RLS/private storage, Signup, Payment/Toss remain unchanged. No real purchase, manual credit grant or ordinary-user mutation was performed.

## Runtime blockers (not test successes)

- Supabase and Cloudflare management access: HTTP200. Production Pages lacks MATH_PROVIDER_API_KEY, MATH_EXTRACTION_WORKER_JWT, MATH_EVALUATION_WORKER_JWT. math-test has secret bindings, but API cannot export plaintext. No rotation/copy assumption.
- Configured test provider: OpenAI / gpt-5.6-sol. No actual Provider call this task. Billing/balance/rate limit/evaluation cost are NOT_ASSESSABLE; no insufficient-funds diagnosis or top-up request.
- MATH_TEST_ACCESS_TOKEN and ADMIN_TEST_ACCESS_TOKEN return403 bad_jwt, token expired. No valid refresh/password session available. Management/service-role credentials were not used to impersonate a student.
- Current Math first evaluation/included14-day re-evaluation/credit rollback/history real E2E: **not run**. Prior historical hosted smoke remains historical. All four types stay GATED. Humanities published questions/criteria0; no invented content. Econ mixed and Science actual evaluations unverified.
- APP/Web actual authenticated History/Credit equality unverified; native full Math submission flow remains engineering work. No claim that read-only History is full Essay integration.
- Real Store APIs/sandbox/paid purchase0. Cross-platform Store-policy acceptance unresolved. Refund/revocation follow-up is an engineering release gate, not solved by secrets.

## Validation

Flutter3.47.6 stable / Dart3.13.5: final analyze PASS. Full integrated regression:984 passed,2 skipped,7 failures; all7 were outdated policy fixtures (explicit empty URLs / all-active-year policy), corrected and each failing group rerun successfully. Final affected auth/coreUX/discovery/bootstrap/history/lifetime suite21 PASS; search/discovery26 PASS; final billing/lifetime18 PASS (overlapping suites, do not sum). No assertion of a second clean full-suite run.

Deno13 verifier boundary tests PASS; typecheck PASS. Isolated PGlite canonical ledger tests: role ACL, account binding, valid grant, replay, cross-account denial, SKU quantity, calendar expiry, atomic rollback PASS. These use fixtures, **not real Store/provider calls**.

Android debug APK build PASS after final source changes (Linux JDK21/SDK35+36/NDK28.2). No Production dart-defines supplied: compile artifact only. iOS build BLOCKED on Linux/noXcode; no Android device/emulator or iPhone/simulator QA this task. Existing Claude SM-G950N acceptance remains scoped to its earlier commit.

## Preservation review

1. Original source facts and publication dates survive; display title is derived.
2. Store purchase time determines expiry; ledger posting time remains separately recorded.
3. One canonical auth user/account binds Store transaction; provider does not make a second profile.
4. Transactions are immutable, idempotent and distinct from learning/target/application facts.
5. History summaries derive from existing attempts/results; no fake scores or combined incompatible rubrics.
6. Account lifecycle lock/allowed and existing ledger anonymization remain; raw Store receipt/email is not persisted in a new table. Hashed transaction reference prevents reclaim after deletion.
7. New RPC is narrowly service-only; actual refund/revocation and Store-policy gaps are explicit, no new money policy inferred.

## Unavoidable Owner settings (one batch; no SQL/terminal)

1. Cloudflare → Workers & Pages → legendstudy-lab → Settings → Variables and Secrets → Production: supply the **existing authorized** three Math secret values above. Do not rotate or paste into chat. Success: all three bindings present, worker auth and approved real evaluation succeed.
2. Codex environment → Secrets → MATH_TEST_ACCESS_TOKEN: replace only the expired approved test user's **Supabase session access_token** from a fresh genuine login. It is not a management/API/service_role key. Success: GET Auth /user returns200 as that test user. No new management token needed.
3. Apple App Store Connect / Google Play Console: verify four consumable product IDs and approved prices; dedicated Store server credentials belong in Supabase → Edge Functions → Secrets per IAP README. Keep activation OFF until refund/revocation and isolated sandbox acceptance are ready. No paid purchase or Store submission yet.
4. macOS/Xcode signing and approved Android/iPhone devices are required for remaining device/build acceptance. Current Linux compile does not replace that evidence.

Next engineering work: refund/revocation lifecycle within existing canonical ledger policy; complete native Math submission/rewrite wiring, then fresh authenticated Provider/Store E2E. No new Foundation required.


## Local APP branch integration — 2026-10-10

**LOCAL_APP_INTEGRATION: COMPLETE.** Scope is code integration and local validation,
not Production activation, physical OAuth acceptance or Store release.

### Verified refs and preservation

Fetched origin before work; known refs matched actual remote tips:
- Base `codex/production-integration`: `8e89dfce2ce3b2f2af4beca28f068c0bc668ce4e`.
- First merge `codex/essay-growth-ux`: `b0facde42c5df7ee38969b72b89ed2228a2a4c48`.
- Second merge `claude/android-google-login-final`: `c11fc8467bc19bacf7713b377e7269674fb3b870`.
- Separate worktree, branch `codex/local-app-integration`; two no-ff merges,
  no conflicts or duplicate commits. Existing Claude checkout/branch and untracked
  `.fvm/`, `.fvmrc`, `supabase/.temp/` preserved. No reset/clean/force push/deletion.
- Production Dart delta consists solely of the source branches' three Auth UI/provider
  files and five Essay display/history files; no reimplementation.
- Backend contracts, Supabase tree, Payment/Toss/Credit Ledger, IAP client, profile,
  account-linking engine, materials/PDF, timer/D-Day, splash/onboarding, platform
  settings and dependency locks are unchanged from the base. No DB/Production call
  or deployment. APP main and all existing branches remain unchanged.

### Validation and existing failure resolution

Existing SDK reused through `./tool/flutterw`: Flutter **3.47.6**, Dart **3.13.5**.
No SDK reinstall/upgrade or PATH Flutter use.

- Initial integrated full run: **1010 passed, 2 skipped, 4 failed**.
- Clean base8e89dfc, same SDK, the two reported files: **27 passed, same4 failed**.
  All failures were obsolete2010 cutoff/discovery-OR assertions in
  `day6_repositories_test` (2) and `supabase_foundation_test` (2). Oct09 explicitly
  permits every active year. Corrected test assertions to require no year cutoff
  or discovery exclusion, retaining active/type/projection/order/token guards.
  No production query, schema or backend contract was changed.
- Added one actual-router regression: login Guest button → Home → public Materials;
  auth remains signed out; `/lab/essay/history` resolves and keeps private reads gated.
- Final analyze: **PASS, no issues**. Final complete suite: **1015 passed, 2 skipped,
  0 failed**. Existing opt-in skips are live public-search and local Auth JWT/RPC
  tests; neither implies new live-backend verification.
- Focused repaired fixtures/login/router suite: **38 passed**. Existing full suite
  covers Auth/native providers/recovery/linking, login UI/Apple iOS visibility,
  Guest, onboarding, shared Essay History, version-safe growth comparison at
  360px/200% text, Credit, billing/IAP lifetime and navigation.
- Android `build apk --debug`: **PASS**. iOS `build ios --simulator --debug`:
  **PASS**; built bundle ID `com.legendstudy.app`. Existing Android SDK/Xcode reused.
  No Production dart-defines: compile artifacts, not authenticated runtime proof.
- Android login widget capture at360×640 inspected with local Korean font: hero,
  email fields, account links, Google/Kakao and Guest entry visible; Apple absent.
  iOS Apple visibility assertion PASS. No physical-device or audible-voice claim.
- `git diff --check` and Wiki handoff/link/routing check PASS. Existing Android
  toolchain-version/XML and CocoaPods-to-SPM advisory warnings are not build failures;
  native toolchain migration remains separate.

### Remaining / next starting point

Start future APP work from the fetched `codex/local-app-integration` branch, then
consult current Unified Wiki; dated refs above are evidence, not a permanent HEAD.

- **Android Google OAuth:** existing Claude handoff reports missing debug SHA-1
  registration. Console state was not independently re-read here. Owner verifies
  Android OAuth package+SHA-1 and Web client configuration, then actual device login.
  See [exact handoff](android-google-login-finalization-2026-10-09.md).
- **Splash:** existing immediate-brand bootstrap preserved and tested; signed
  device cold/warm timing and final visual acceptance remain separate QA.
- **First-run:** profile-driven authenticated onboarding preserved. Current router
  starts atHome for Guest; device/install-once brand-before-login flow from Oct09
  remains a separate implementation/acceptance gap, not reimplemented in this merge.
- **iPhone QA:** simulator compilation is PASS; physical login/provider switching,
  launch/first-run, materials/PDF and authenticated Essay/Growth/Store QA pending.
- **Essay Voice:** APP TTS absent. Unified Oct09 policy excludes Math voice from
  first release; humanities/economics remain scope, science undecided/gated.
- Native full Math submission/rewrite, Store sandbox acceptance and post-grant
  refund/revocation remain pre-existing gaps; IAP implementation preserved, no purchase.
- No Store submission, production deployment, APP main merge or branch deletion.
  Owner action is required for subsequent OAuth/device/release QA, not to finish
  this code integration. Unified Wiki latest Math E2E evidence supersedes Oct09
  expired-token/missing-secret blockers above; no fresh runtime claim in this task.
