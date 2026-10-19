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


## Oct18 independent release candidate integration

Status: local integration verified; store/public release HOLD. Branch `codex/release-candidate-20261018`, based on Codex `f62b1ee`; Claude read-only authority `2684cee` (remote matched), APP main `d07671e` untouched. LAB candidate `916b46c` contains latest remote main `8991b51`; DOCS base `d59d2ac` contains main `1664a8c`. No full branch merge.

### Selected integration and preservation

- Claude `9d8bce2`: verifier uses its own Supabase project, fail-closed Apple Sandbox grant allowlist and Production denial; core/index/tests selected. Existing Codex TEST session storage/strict host guard/purchase history/native draft/onboarding retained byte-for-byte. No deployed function changed.
- Claude `0f20c76`: refund notification core/stores/index/tests and migration20261016120000 copied unchanged. This is source integration only. Prior Claude TEST SQL evidence is historical; no DB apply or live refund event in this task. Production notification configuration/deployment/migration/real refund acceptance remain separate gates. Existing grant RPC, Ledger and essay cycle contracts unchanged.
- Claude `3b4e220`: latest1800ms brand frame, Pretendard SemiBold/OFL, navy/orange wordmark and tests selected. Existing native splash already white on both platforms; no redundant background change. Authentication initialization readiness remains tested.
- Claude `2684cee`: encryption declaration false, existing team VUKFS69GB4 and scheme selected. Existing scene/deep-link/privacy/photo/Draft native channels retained; iOS15 minimum preserved instead of unrelated Xcode recommended-OS rewrite.
- Rejected whole-file replacements that would remove Codex purchase history, TEST session isolation, native Draft/onboarding or essay UI. No content-detail/Math/Payment redesign. Claude worktree remains2684cee with its pre-existing untracked supabase/.temp only.
- Sole test repair: account_deletion_test had no native essay-draft purge mock (4 pumpAndSettle timeouts). Added owner-hash/method assertions for that existing channel; no account deletion product logic changed. Focused10 and subsequent full suite pass.

### Validation

- Flutter3.47.6: Analyze PASS; final full suite1076 PASS/7 fixture-dependent skips. Original run1072pass/4failure/7skip exposed the missing test channel. Existing actual first/free results separately6PASS and additional paid result1PASS (including narrow/high-scale rendering). No Provider request.
- Existing LAB: Node22.23.2 lint/typecheck/build PASS,135 static pages;141 testfiles1135tests PASS/3skips. Initial wrapper used Node24 despite PATH; full WEB checks repeated with explicit Node22. Actual stored first/free/additional result fixtures separately checked. LAB source unchanged.
- Edge core29PASS (purchase+Sandbox gates+refund), Deno index typecheckPASS; no network permission granted to core tests, no deployment. Existing shared billing controller grants nothing locally, consumes only after server success/already_processed.
- Android TEST signed release AAB0.1.0+3/com.legendstudy.app PASS77.6MB; existing upload key reused. Saved `/private/tmp/legendstudy-release-candidate-test-v3.aab`; SHA256 b0020834daed5ba68d7395de689fdd10c2698153e1b563796244765b292da4ca. Jarsigner reports jar verified with existing self-signed/no-timestamp and ZIP-reader warnings; Play upload not performed/certified. Production-host HOLD build also prepared (result below).
- iOS release --no-codesign PASS35.9MB, bundle com.legendstudy.app, minimum15.0, encryption false. Artifact `build/ios/iphoneos/Runner.app`. Production public client configuration, essay writes/requests false; no account login or network operation initiated by build. Not an IPA/distribution-signed upload artifact.
- Existing Kotlin/SDKXML warnings and flutter_tts SPM fallback are nonfatal build warnings, not upgraded in this scoped integration.

### Existing E2E / release gates

First/free/additional actual E2E and Owner WEB/APP confirmation remain prior accepted evidence (latest additional balance9); GoogleTEST purchase/grant/restart4/ACK1/consume1/duplicateRPC remain prior accepted evidence. No fresh balance or DB audit claimed. Existing Package17/result/History data untouched; local stored-result checks do not constitute a new service E2E or quality approval.

Release blockers: Apple updated agreement/Paid Apps/tax-bank status and actual StoreKit Sandbox acceptance; refund notification operational configuration/deployment and real lifecycle acceptance; final distribution signing/store build-number availability and integrated device acceptance; WEB latest approved UI deployment and narrowly approved production IAP/essay activation (currentlyOFF). Existing tool/store-release unconditionally turns essay flags on, so this HOLD candidate deliberately used direct Flutter release builds with explicit OFF defines. Do not use the old wrapper as a HOLD build entrypoint.

Owner next approvals: resolve Apple contract in Account Holder account; confirm integrated device login/onboarding/deletion-request-cancel/History and splash; separately authorize any Sandbox purchase/refund test, Production migration/deployment/activation, store upload/submission. None are performed here. No new wallet/engine, DB change, Provider or Credit/store transaction. See essay-lab-ui-ux-v1 Oct18 inventory for22-university expansion evidence and quality plan.

Final build: Production-host Android signed HOLD AAB0.1.0+3 PASS77.7MB; SHA256 cf0273b8c82c88b54b6ccc1939d70c7afa6909188ad94dd391b935964a1f4bc9. Existing upload certificate, jarsigner jar verified (self-signed/no timestamp/ZIP-reader warnings remain). First Production build failed because a concurrent Flutter test regenerated integration_test plugin registration; sequential ordinary release rebuild PASS20.4s, no generated file edited. Use sequential native/test builds in the same workspace. WEB actual stored result tests2PASS. No runtime call, activation or upload.


## Oct18 iPhone TEST-only essay gateway boundary

Owner approved minimal TEST Production-API block after discovering fixed operating LAB URLs. AppConfig.essayApiOrigin now rejects APP_ENV=test before transport/token transmission; Production remains https://lab.legendstudy.com. Catalog, exam quote/submit and existing Math gateway share this boundary. No TEST gateway URL is configured in this candidate; do not invent one or route TEST JWT to production. Native42-university catalog remains bundled; network-backed exam catalog cannot be certified until a TEST source endpoint is provided. Existing TEST Supabase History/results reads are unchanged; optional operating Catalog metadata enrichment is caught and stored metadata remains the fallback. Missing TEST evaluation rows must remain missing, not copied from Production or fabricated.

Analyze PASS;16 focused tests PASS (no-network TEST catalog guard, unchanged Production origin, TEST auth/session, source transport, shared History, Math gateway). No IAP/Ledger/DB/Provider logic changed. Existing account deletion build flag remains absent/OFF; no deletion request permitted during this device readback. Prior full suite evidence remains scoped to ae9296f; this patch has focused regression coverage. iPhone development build/install results recorded below.

Device follow-up: iOS Debug and Profile development-signed builds PASS, Profile46.2MB/teamVUKFS69GB4/bundlecom.legendstudy.app. Compiled defines verified APP_ENV=test and kpqbedylxlyntrrfybpn; privileged codesign verification PASS. Installed and launched on paired iPhone12ProMax via CoreDevice (after Owner unlock). iPhone17ProMax unavailable. No uninstall/data reset. Device login/balance/purchase-history/UI readback still Owner-pending; do not claim screen or authenticated RPC PASS from process launch. No purchase/evaluation/deletion executed. TEST Catalog gateway unresolved; account deletion flagOFF. Actual production answers are not copied. Wiki handoff checkPASS.


## Oct18 Phase1 Production read-only candidate

Latest Owner supersedes TEST-cloning priority: Phase1 existing Production read views; Phase2 Apple IAP/refunds; Phase3 WEB UX; Phase4 submission/public release. No TEST→Production migration or unapproved writes. TEST operating API guard stays. Apple Developer agreement accepted/Account Holder/regional compliance completed per Owner; do not repeat those steps. Paid Apps visibility/StoreKit products/Sandbox E2E remain Phase2.

Authority fetched: APP9c4bd73; LAB916b46c (main8991b51 already included); DOCSed03a11; Claude latestbe51e98. Only Claude committed wordmark plus-size/gap diff selected (verified16 affected tests+Analyze); no other Claude files or branch changed. Existing APP feature code preserved.

Fresh read-only preflight: Cloudflare OAuth auto-refresh via existing wrangler whoami restored read access. Pages ESSAY_EXAM_RUNTIME_ENABLED=false,ESSAY_CONTINUOUS_CYCLES_ENABLED=false; Worker ESSAY_EXECUTION_ENABLED=false; canonical operating deployment433141d6 unchanged. Production Supabase secrets metadata has no IAP_ENABLED; deployed verify-iap-purchase v5 explicitly requires true, so IAP verifier disabled. Secret values not read/displayed. No flags/deployment changed.

Public GET /api/essay/catalog returned essay-source-registry-v1,21source universities/77source exams; APP merges the existing42-university catalog and exact Owner22 ordering. Source exam counts are not a new canonical234-question audit. Review account only (ddc5ae63…) DB SELECT confirms prior completed3 runs and balance9/reserved0. No raw answers fetched/no other user inspected. APP/WEB same RPC/result contract remains; fresh actual device render still requires Owner evidence.

Feature scope audit: HOME material cards/D-Day representative+2 collapsed extra events; materials filters/search/PDF/bookmark/recent; study timer/local records; MY credit/history/goal-major/account lifecycle; essay catalog/question/answer/images/first-free-additional/result/comparison/voice/history already implemented. No new feature engineered. Prior full local regressions remain historical; latest patch only brand/environment affected16 PASS. Existing real first/free/additionalE2E and GoogleIAPTEST are not repeated. Read-only device phase must not submit/delete/bookmark/edit profile/schedule/start new study-save, or buy.

Production candidate uses stlhijzpjfgwwdgunlsd public client config, operatingLAB origin, essay writes/requests false, version0.1.0+4 (distinguishes TEST+3). Existing development signing/keystore only. Account deletion UI may be inspected but operation forbidden. No new iOS purchase-button policy inferred; keep Phase2 pending/avoid purchase path. Android initially no ADB device; physical acceptance pending.

### Phase1 local verification and device handoff (Oct18)

Analyze and16 focused brand/bootstrap/environment/IAP-session tests PASS. iOS Production profile0.1.0(4), bundle com.legendstudy.app, existing teamVUKFS69GB4 signing PASS; installed and launched on iPhone12ProMax. Artifact/config inspection confirms operating Supabase and both essay write/request flags false. Owner review-account screen acceptance pending; installation is not UI PASS.

Android Production release APK0.1.0(4) built PASS (89.0MB), existing upload signing reused. Connected Android has Play0.1.0(2): installed certificate4d9694e8525102cf3f65193bbc8c4061212a43b63d2c15061614a976df6371ac differs from upload certificatec00f4260d5b95a084335576c03bf36b8914a2f33cb3da701403e0adbacfb8ef1. No uninstall/update attempted; TEST app/data preserved. A second device or separately approved Play internal delivery is needed. APK: build/app/outputs/flutter-apk/app-release.apk (ignored build output).

Phase1 PARTIAL: Home/materials/study/MY and essay existing implementation retained; current Production screen acceptance remains unverified on both platforms. Read-only checks cannot certify bookmark/study/profile/delete write flows, which were not executed. Existing essay3 completed records/9Credit verified; no new Provider, Credit, purchase, operating DB change or deployment. TEST boundary retained. Apple agreement acceptance/account-holder/regional compliance Owner-confirmed; do not repeat. Paid Apps/product lookup/Sandbox/refund operating acceptance remain Phase2 gates. WEB UX Phase3 not started.

## Oct18 Owner-approved selective UI integration

Authority: Owner named APP be51e98 (brand), c3ac6ec (onboarding), Unified Wiki4c7065e. Remote refs inspected; no full branch merge. Brand wordmark already equals be51e98 in RC1897c3c: plus0.9x vs prior0.5x (~1.8x), orange/top-right/Pretendard and BrandGate1.8s preserved; no redundant edit.

Only c3ac6ec onboarding UI hunks selected into lib/features/onboarding/presentation/onboarding_page.dart. Original patch context differed because RC has DeviceIntroPage/BrandOnboarding and starts personalization at step1. Those RC contracts retained, including device-intro persistence, auth boundary, existing four questions/copy/save fields. Added300ms fade/slide, step-dependent420ms decorative glow, zero animation durations with Reduce Motion,320ms navigation guard. University42 assets, billing/Ledger/essay/backend/DB untouched. No personalization card or other Claude changes imported.

Related test/onboarding_page_test.dart adds360px/200% cases with Reduce Motion on/off, rapid navigation guard and backward/forward grade retention verified through canonical final save (exactly one profile upsert). Existing brand tests cover360/428 widths and100/200% text, splash timing and single cold-start display. Analyze PASS;36 focused widget/domain tests PASS. Android/iOS build outcome recorded below after completion.

Owner follow-up supersedes prior pending state: iPhone existing results and Credit display confirmed. Android signing diagnosis closed; Production device verification deferred by Owner, existing GoogleTEST app preserved. No Android installation, key change, upload, transaction or Provider call. Latest UI transition feel/splash on iPhone remains Owner acceptance; existing installed+4 predates this onboarding integration.

Build verification: Android release APK0.1.0+5 PASS (89.0MB), existing upload key/config retained. iOS release --no-codesign0.1.0+5 PASS; this is compile validation, not signed Archive/TestFlight acceptance. Production read-only config keeps essay write/request flags false. Existing flutter_tts Swift Package Manager future warning remains nonfatal; no dependency changes. No device installation/store upload. Owner next device checks: splash + scale/alignment, question fade/slide/glow, Reduce Motion, fast taps/back navigation and retained inputs.

## Oct18 final directive — safe-read and release readiness

Authority refreshed: APPe6efb55, DOCS76adc0e; no new UI reintegration. Owner confirms iPhone existing results/Credit; Android Production device QA deferred, GoogleTEST installation untouched. Apple contract/product setup and support page acceptance not repeated.

Read-only boundary finding: ContentDetailPage records recent views after10s foreground dwell or meaningful interaction (touchRecentView); onboarding finish writes profiles; bookmark/study/D-Day/profile changes also write by design. Existing essay flags alone do not make the whole APP read-only. Do not open detail/traverse save actions in Production and claim zero writes. Existing lookup acceptance is limited to approved Catalog/History/results/Credit. Full materials/onboarding/study-save verification remains GAP until safe local review suppression or separately approved writes; no such writes executed here. Functional implementation is not missing merely because writes are withheld.

Local unsigned Archive prepared with build-name1.0/build-number6; emittedCFBundleShortVersion1.0.0/6, bundlecom.legendstudy.app, iOS15. build/ios/archive/Runner.xcarchive204MB. Existing Production read config keeps essay request/writeOFF; this is NOT a fully read-only transport. No IPA exported (no-codesign), no upload. Keychain has one usable Apple Development identity, no usable Apple Distribution identity observed. Signed export/portal certificate provisioning/TestFlight upload remain separate gates. Existing ASC version1.0 must be matched at final export; actual metadata/artifact validated then, no version edit to store here.

Next device review: preserve current data and existing completed onboarding; do not reset Production profile solely to replay onboarding. Latest transition QA is local36PASS; a TEST-only signed device candidate can exercise onboarding after Owner chooses/approves its installation and TEST profile operations. No iPhone install this turn. New Production screenshots/QA cannot be reported from old installed+4.

## Oct18 Production read-only device build preparation

Owner authorizes local preparation only, no installation/replacement. REVIEW_READ_ONLY defaults false and is supplied only by /private/tmp/legendstudy-production-readonly.json; normal store config unchanged. tool/store-release refuses a true review flag. Build target Production only, existing TEST session isolation preserved; OAuth disabled in review config, existing email/password and refresh authentication allowed. Auth session/audit bookkeeping is inherent to the explicitly allowed login, not application data mutation.

Transport boundary: core/network/review_read_only_client.dart, explicitly wired into Supabase bootstrap, separate avatar Storage client, essay catalog/exam/math clients, study/scoring shared transport, school and PDF fetch. No reliance on Flutter callback Zone inheritance. Denied request throws REVIEW_READ_ONLY_BLOCKED and prints only that constant, no URL/token/body. Redirects disabled. Unknown RPCs/Edge functions blocked including GET; only explicit existing read RPCs allowed. Cross-project Supabase rejected. No direct dart:io write transport, Realtime channel write or native push-token registration implementation found in current lib.

| Path | Review behavior |
|---|---|
| Profile creation/update, onboarding/target major | REST writes blocked before send |
| Recent views, bookmarks, D-Day/target university | REST writes blocked, existing SELECT retained |
| Timer/outbox/study/mock submission | HTTP writes blocked; local draft/queue may remain, no false synced success |
| Notifications read marking/token writes | Mutation RPC/REST blocked; list/count reads retained |
| Essay submit/rewrite/reserve/consume | LAB POST and unknown/mutation RPC blocked |
| Purchase restore/verify/ACK/consume | Native IAP controller not constructed; Edge blocked; purchase history SELECT retained |
| Account request/cancel/recovery | All Edge requests blocked; deletion feature flag OFF |
| Avatar upload and storage mutation | Separate Storage transport guarded |

Read scope: existing REST data, Credit summary, essay History/results, application labels, notifications, mock read RPC and LAB Catalog. Approved read RPCs use existing server semantics. Resolver/neis/other Edge calls remain blocked: PDF needing resolver/new signed URL, school search and deletion status can be unavailable. Math multipurpose RPC blocked. Static existing PDF/object GET supported without redirects. External browser/native OS URLs are outside this HTTP guard; do not use external mutation flows during review. No system-wide no-write guarantee for arbitrary future plugins: new clients require this factory.

Local SDK transport-spy tests prove blocked Production-address requests cause zero underlying sends (profile/recent/bookmark/study/day-target/target/token, essay/Ledger/deletion RPC, purchase Edge). Read requests reach spy. No real operating write probe made. Existing deletion/billing/session/study regressions retained. Device network capture/actual read acceptance remains pending installation approval. Local queued changes are not deleted: use screen/read flows only; do not complete timer/onboarding or edit profile, and inspect pending local sync before restoring a normal release build.

Build/check evidence and device outcome recorded in current handoff. Production database, Provider, Credit, Store and existing installed iPhone unchanged. Public HOLD.

Final local evidence: Flutter Analyze PASS;42focused transport/deletion/billing/session/study tests PASS;4review-flag ON tests PASS including native IAP null/factory enforcement; Wiki handoff PASS. Store config rejection confirmed. Development Profile build1.0.0(7),com.legendstudy.app,46.1MB PASS at build/ios/iphoneos/Runner.app. codesign deep/strict verification PASS; embedded iOS Team Provisioning Profile,teamVUKFS69GB4,get-task-allow=true,2devices. No installation. Logs:/private/tmp/rc-readonly-{analyze,test,flag-test,ios}.log. Device traffic/Owner screens NOT_VERIFIED.

## Oct18 approved iPhone installation — in progress

Actual prior install0.1.0(4),developer/container-accessible. Copied Application Support and Preferences into mode0700 local /private/tmp/legendstudy-iphone-preinstall-20261018 (sensitive; never commit contents). Whole Library copy encountered OS saved-state protection; targeted app-data copies succeeded. Found3essay JSON/2images,0active study drafts,1unsynced study record. Native storage/session implementation unchanged since prior candidate; no cleanup/migration invoked.

Installed1.0.0(7) without uninstall/reset. Before first launch all7ApplicationSupport files hash-identical and Preferences semantically identical, despite OS changing container path. Production/REVIEW_READ_ONLY=true build defines verified. Launch failed Locked/CoreDevice10002; Owner unlock requested. No device screens or live traffic PASS claimed.

Found review-filter GAP: authenticated Catalog uses read-only POST; prior guard blocked it before GET fallback. Reviewed LAB catalog handler + existing essay_registered_questions SELECT contract. Narrowly allow exact Catalog POST only; exam POST stays denied. Added regression test. Corrected build1.0.0(8) prepared; outcome below. Deletion2주 copy not reachable with deletion flagOFF; onboarding already-completed local state preserved, not reset. Both remain device UX GAP.

Build8 closeout: Analyze PASS;5review-flag tests PASS;development-signed Profile1.0.0(8)46.1MB build/codesign verification PASS. Updated installed app without delete/reset. Device info confirms1.0.0(8). Draft/study ApplicationSupport7files preserved after final update (hash comparison). Locked-device launch remains unresolved; no screen/voice/Credit/live-write acceptance claimed. Owner unlock and read-only screen report pending. Existing unit zero-send evidence is not device traffic measurement. No purchase/Provider/deletion/DB writes.

## Oct18 functional Production RC stabilization — supersedes read-only QA

Owner authorizes review@legendstudy.com normal per-user bookmark/recent/profile/school/target/study writes. Address typo confirmed by Owner before launch. No shared data/schema/provider/purchase/Credit/deletion operations. Diagnostic REVIEW_READ_ONLY retained/defaultfalse; functional config setsfalse. Added IAP_TRANSACTIONS_ENABLED(defaulttrue) as a separate native-controller gate; functional device config false prevents restore/verify/consume. Normal Store config unchanged. Essay/deletion execution flags remainfalse for this device test.

Production READ-ONLY metadata: profiles/bookmarks/recent_views/study_sessions/day_targets/student_target_universities allRLS=true and authenticated owner predicates present; lifecycle restriction retained. This is policy inspection, not cross-user runtime penetration testing. Before device actions review account: profile1,bookmark0,recent0,study0,D-Day2,target4. No privileged SQL writes. Saved Production session metadata matches approved review identity; distinct TEST session exists but remains isolated (raw tokens never printed).

Analyze PASS;39billing/session/study/deletion tests PASS;5transport/native-gate tests with IAPfalse PASS. Signed development Profile1.0.0(9) built, installed without deletion/reset and launched successfully. Normal user storage now permitted; preexisting local queues preserved. Owner requested to perform PDF/bookmark and1minute study save/restart; actual per-feature and DB postflight pending response. No new UI design.

Local signing inventory has Apple Development only; Apple Distribution/IPA export remains BLOCKER. Android Play TEST install untouched. Actual upload/Store submission remains separate approval; public HOLD.

Functional RC first server readback: review recent_views0→1 after device launch/activity; bookmarks0,study0,D-Day2,target4. This confirms one actual recent-view record, not PDF/bookmark/timer UI or restart acceptance. Owner device report pending. Android normal Production Release AAB1.0.0(9)77.7MB built via existing store-release/upload-key pipeline, not installed/uploaded. Build warns CupertinoIcons font missing; no direct lib CupertinoIcons references; visual impact not yet established. No blanket release-ready claim.

Owner physical acceptance received: PASS for requested material search→PDF→bookmark;timer>=1minute→stop/save;force-close/relaunch→bookmark/recent/study persistence. Independent Production readback confirms bookmark2,recent1,study1 (baseline0/0/0). These scoped flows now DEVICE+DB PASS. Bookmark removal,school save/targets,remaining MY/essay/voice/new UI checks remain pending separate Owner response. No replay of completed Google/essay E2E. AAB jarsigner reports jar verified with self-signed/upload-key trust and JarInputStream/manifest-order warnings; Play ingestion not tested and no upload.

## Oct18 device defect — intended major save

Owner confirms interested-university setting PASS, intended-major setting FAIL. Production read-only evidence: intended_major column exists and review value remains사회·상경 with older updated_at; postgres logs show permission denied for table profiles. authenticated UPDATE(intended_major)=true,INSERT(intended_major)=false;INSERT/UPDATE(updated_at)=false. Existing client upsert sent id,intended_major,updated_at, violating both column contracts. No migration required.

Minimal APP fix: owner-scoped PATCH intended_major only; server profiles_updated_at trigger remains authority. select(id).single requires one updated row to avoid false success for missing/RLS-filtered profile. Null clearing remains supported. No grant/schema/engine change. Analyze PASS;11repository+existing personalization tests PASS (PATCH payload,owner filter,clear,missing row). Development build10/device recheck pending; not marked fixed in Production UX until Owner acceptance.

Build10 development Profile46.1MB/codesign PASS; installed without uninstall/reset and launched on iPhone. Owner asked to select major and navigate away/back; server-value comparison pending response. No DB/schema/ACL modification.

Owner build10 acceptance: intended-major selection and persistence after screen navigation PASS. Read-only Production readback confirms review@legendstudy.com intended_major=자유전공·융합, updated_at=2026-10-18 13:29:43.64993+00 (22:29:43 KST), replacing prior 사회·상경/Oct15 timestamp. Device and DB save verified; no permission/schema changes. Earlier pending statements above are resolved by this acceptance. General public HOLD remains.

## Oct19 latest RC device13 — installed; display acceptance pending

Owner authorizes development build/update without uninstall; existing PASS reused.
Remote RC2f2eb2f verified clean. Actual connected iPhone12ProMax before update was
1.0.0(10),not assumed11. Built Profile1.0.0(13),46.1MB,Apple Development TeamVUKFS69GB4,
com.legendstudy.app;codesign strict/deep PASS. No feature/source change since accepted
organizer implementation5d106af; prior Analyze35tests PASS reused.

Production public config; REVIEW_READ_ONLY=false. Normal per-user save functions retained.
IAP_TRANSACTIONS_ENABLED=false,ESSAY_LIVE_WRITES_ENABLED=false,
ESSAY_EVALUATION_REQUESTS_ENABLED=false,ACCOUNT_DELETION_ENABLED=false for this device
verification only. Store config remains separate. No new purchase/evaluation/deletion action.

Before update protected local backup: ApplicationSupport7files,Preferences1file (including
existing separate auth sessions),Documents empty. Updated without delete/reset. Before first
launch all7files SHA256-identical; Preferences app/auth values unchanged. Only OS StoreKit
SKPurchaseIntentUpdatesLastChecked timestamp changed; no purchase invoked. Raw tokens/data
not logged or committed. Device info confirms installed1.0.0(13); launch succeeded.

Owner asked to check Sep2026G1 Incheon organizer plus original/PDF/saved display and only
errors in existing History/results/MY/school/university/major/timer screens. Device screen
acceptance PENDING; no new full-flow replay. Public HOLD. No Store upload/DB/Provider/Credit.
