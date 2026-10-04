# APP-RELEASE-CLOSEOUT-1 — 2026-10-04

**BLOCKED for Store submission. Local fixes verified; no Production mutation or upload.**
APP baseline: payment implementation e8c3b4e; closeout changes are on
`codex/app-release-closeout-1`. Payment code and canonical migrations are unchanged.
Unified authority: legendstudy-docs CURRENT_STATUS, AI_CONTEXT and 2026-10-04 Daily;
ADR-2D, Auth acceptance, mobile policy audit and actual repository were consulted.
A separate APP-RELEASE-1/J5 report was not found in these checkouts; this does not
pretend to replace an unseen report. Existing Owner device/UI acceptance is retained.

## Five baseline failures

All five reproduced before Payment at 8881eee (26 pass/5 fail in the three files).
No test was deleted or skipped. Production code did not need reversal.

| Test | Root cause / correction | Production impact / release blocker |
|---|---|---|
| day6 repositories: parent type query empty | Expected old projection without canonical discovery exam join; assert join, 2010 cutoff and discovery OR | stale assertion; test gate fixed |
| same: query 영어 100%_ | Same, with repeated OR parameters; preserve wildcard escaping assertion | stale assertion; test gate fixed |
| day5 content badges large text | Unknown exam intentionally says 시험 자료, not guessed 모의고사 | stale label; accessibility assertion retained |
| Materials guest journey 1× | Finder used raw source title after canonical display-title cleanup | stale finder; navigation, failure, return/scroll assertions retained |
| same 2× | Same title mismatch | same; large-text journey retained |

First corrected full suite:933 PASS/2 pre-existing opt-in skips. After lifecycle
changes:935 PASS/2 skips, plus one added owner-switch test (10 deletion tests PASS).
Final full suite:936 PASS/2 existing skips; final analyze: no issues. The existing skips were not introduced or changed here.

## Account deletion: code and runtime are different gates

ADR-2D remains canonical: request → restriction → fixed336h → personal/storage/
provider/finance/Auth/verification stages, retries, restore manifest and30-day receipt.
No migration was changed. Existing local112 lifecycle+17 ownership evidence is reused;
not a claim of new Hosted/Production execution.

Changes:
- Router observes owner-scoped lifecycle state; pending/erasing/erased, unavailable
  status and lookup failure cannot enter personalized routes when enabled.
- Deletion/status/Auth recovery routes remain available; flag-OFF/guest unaffected.
- Cancellation can call existing `/account-deletion-worker/reauth` email challenge
  before canonical cancel. Password stays transient, cleared before transport.
- Pending status also retries owner-local cleanup on re-entry; explicit cleanup retry,
  bounded requests and logout. A→B clears acknowledgement, password, deadline/error.
- Existing server resolves subject from JWT; no target-user parameter or client admin key.

**Still BLOCKED:** Production ADR-2D/apply, Edge functions, scheduler/watchdog,
restore checkpoint, provider obligations, email reauth configuration, cross-provider
reauth, admission hookup and actual lifecycle acceptance. Settings entry is discoverable
(MY → Settings → 탈퇴 요청), but default ACCOUNT_DELETION_ENABLED=false means no
production-ready deletion claim. Privacy erasure must not wait indefinitely for revoke.

Apple transport `apple-revoke.ts` posts only to Apple's fixed revoke endpoint, disables
redirects, bounds timeout, sanitizes errors and returns false for absent material.
Deno52 PASS includes two new transport tests. **It is not wired as successful worker
revocation:** current native sign-in exchanges ID token with Supabase and does not
supply a retained, server-bound Apple refresh/access token. Worker still reports unknown.
Required before activation: reviewed server-only verified identity/token capture or
fresh authorization-code exchange, bounded retention/retry through336h, correct App ID
vs Services ID credential, and real Apple revoke E2E. Never put client-secret/.p8 in App.
This missing connection is an internal integration blocker as well as an Owner credential
gate, not something an Owner checkbox alone can resolve.

LAB: independent `codex/app-release-deletion-web` starts latest main3370dad. Real
`delete-account` request/status adapter, checkbox confirmation, timeout, sanitized
failure, idempotent server retry, late-owner isolation and logout; no fake receipt.
Default NEXT_PUBLIC_ACCOUNT_DELETION_ENABLED=false.141 web tests PASS including4 new;
typecheck/lint/static export PASS. No deployment. Public backend is not active,
therefore ACCOUNT_DELETION_WEB remains BLOCKED. Enable only after backend and policy
acceptance; this public build flag is not authorization (server JWT/RPC enforce it).

## Feature release matrix (FREE_LAUNCH candidate)

ACTIVE means implemented route, not unconditional provider/production certification.

| Surface | State | Scope / dependency |
|---|---|---|
| HOME | ACTIVE | real profile school/grade, D-Day/schedules, NEIS meal, study totals, guest/empty states |
| MATERIALS | ACTIVE | guest search/filter/detail; external source/open PDF; auth bookmarks/recent |
| LEARNING | ACTIVE | timer, local records/cloud completed history, mock attempt/scoring where canonical keys exist |
| 내신 advanced analysis | COMING_SOON | honest unsupported copy; no fake analytics |
| 모의고사·수능 | ACTIVE | materials and implemented mock record/score summaries; not admissions prediction |
| LAB | ACTIVE | native hierarchy and catalogue; no native purchase CTA |
| 인문논술 | ACTIVE catalogue; DISABLED writes/evaluation in default build | ESSAY_LIVE_WRITES_ENABLED / ESSAY_EVALUATION_REQUESTS_ENABLED require actual approved runtime; no fixture route installed |
| 수리논술 | DISABLED pending Math closeout | Claude result is dependency; no change to Math authority |
| MY | ACTIVE | profile/avatar/school/grade, saved/recent, policies/support/logout; deletion separately gated |
| Community | HIDDEN | no launch community/moderation backend |
| 입시/합격예측 | HIDDEN | not shipped |
| Achievement/Level | HIDDEN | no award/level implementation promoted |
| Digital purchase / ad removal | DISABLED | no IAP/Play Billing; no native Toss CTA; LIVE not enabled |

No unrestricted in-app browser: url_launcher uses externalApplication; pdfrx is a
specific material viewer. Auth uses provider browser/native SDK flows, not a general
web browser. Private essay/feedback user content exists; public community UGC does not.
AI evaluation implementation exists behind flags; do not claim active in FREE_LAUNCH.

## Privacy/data map — implementation facts for J5

Collected below means transmitted by implemented authenticated features when enabled;
local-only does not mean server-collected. Linked=account unless specified. Sharing
column describes recipients, not an automatic legal/Console classification.

| Data | Collected/stored/linked | Purpose / recipients | Retention and deletion |
|---|---|---|---|
| account ID, email, provider identity | Auth + SDK session, linked | login/security; Supabase and selected Google/Apple/Kakao | account lifecycle; provider revocation separately open |
| profile name, school, grade | profiles, linked | personalization; Supabase |336h erasure after request; backup gate |
| D-Day/schedules | profile/personal state, linked | Home; Supabase | account erasure |
| study duration/history | local owner document; completed account records sync | learning progress; Supabase | guest device-only, no automatic guest merge; account local/server cleanup |
| mock result/answers | local owner state + server attempts/answers when synced | scoring; Supabase | account erasure |
| bookmarks/recent views | account tables | save/history; Supabase | account erasure |
| avatar | selected image, private Storage + owner cache | profile; Supabase | Storage API cleanup + local cache invalidation; no automatic social photo import |
| essay answers/evaluations | canonical essay tables/storage when flags active | learning/AI evaluation if activated; actual evaluator processor requires rollout review | lifecycle erasure including dependent HQP; no indefinite analytics copy |
| math answers/evaluations | Math canonical implementation, release dependency | Math pipeline only if separately activated | Math closeout + ADR inventory; no new ACTIVE claim |
| credit/payment facts | shared canonical balance/ledger; native read, no purchase | entitlement history; Supabase; Toss only Web provider | finance-restricted retention/detachment; legal schedule/operational apply review still required |
| feedback/support content | user submitted text and selected diagnostics | support; Supabase/notification delivery | privacy lifecycle and approved operational retention; free text may identify user |
| device/session metadata | SDK auth/network; local boot/elapsed clocks and notification state | authentication, timer integrity, focus/local reminders | no app device fingerprint/tracking; local boot ID stays device-side; provider network logs need Owner retention confirmation |
| analytics/crash/ads/remote push | no dedicated SDK/activation found in pubspec/native code | none asserted; OS/platform diagnostics are separate | no invented SDK collection |

Dependency inventory: supabase_flutter2.15.4, google_sign_in7.2.0,
sign_in_with_apple8.2.0, url_launcher6.3.2, image_picker1.2.3, pdfrx2.6.5,
http1.6.0, crypto3.0.7, Riverpod/router/Flutter UI. Inspect locked transitive SDK
privacy manifests again with final signed archive; package presence is not proof of
all vendor backend retention practices. ADS:NOT_ACTIVE; remote push not configured;
local mock completion notifications are implemented.

**Apple input draft:** linked Contact Info/email (and profile name), Identifiers/user ID,
User Content/photos, other user content (answers/support), Usage/app interactions and
learning records; select purpose App Functionality. No tracking or advertising SDK found.
Purchase History only for actual enabled entitlement/history disclosure after final scope
review; no card number is held by native App. Do not mark all data “not collected”.
**Google draft:** personal info/email/name/user IDs, photos/avatar, files/user content as
applicable, app activity/interactions (saved/recent/study), other learning content. HTTPS
transit; owner-access controls. Do not claim deletion available until public/app lifecycle
works. Service-provider exception to “shared” must be checked against actual contracts,
not inferred simply from SDK name. Owner chooses target age and submits Console answers.
**Package BLOCKED for final submission:** backend retention, active AI processor details,
provider metadata and public policy reconciliation remain; this map is a code inventory.

## Public policy mismatch — release blocker

Public GET checks were attempted but rejected by the network endpoint/tool; no fresh
public200 claim. Latest LAB main `src/lib/legal-documents.ts` explicitly says school,
grade, grades, essay answers/evaluations are NOT stored server-side. Native implementation
stores several of these. It also describes browser-only drafts and deletion via support,
not current ADR336h behavior. These are APP-scope publication blockers; do not silently
reuse LAB-only wording as App policy. Existing stated customer-support3years and
contract/payment5years must be reconciled with canonical erasure/retention execution;
no statutory conclusion or policy rewrite was invented. Pricing is untouched.

## Permissions, brand and build

iOS photo-library usage description maps to user-selected avatar; no camera/microphone,
location/ATT/contacts usage declaration. Local notification permission is runtime.
Android INTERNET, POST_NOTIFICATIONS and ACCESS_NOTIFICATION_POLICY serve network,
mock completion and explicitly requested study-focus/DND. No camera/broad-storage/
location/ad-ID permission in source manifest. Merged release audit found transitive androidx.biometric permissions; unused USE_BIOMETRIC/USE_FINGERPRINT are explicitly removed. Final signed artifact requires Owner review. iOS adds app-level SystemBootTime reason35F9.1 for timer;
no tracking flag. Built resource inclusion verified separately.

Display name:레전드스터디+; official English:LegendStudy Plus; bundle/package:
com.legendstudy.app. Existing official launcher/splash assets preserved. Version0.1.0+1
unchanged: Console history is unknown, so Owner must choose unused build number.
iPad support is declared (device family1,2) but iPad acceptance/screenshots unverified.
Android Flutter targetSdk36; AAB release compile PASS, upload signing absent (unsigned).
iOS release --no-codesign compile PASS; no Team/distribution provisioning confirmed.
These are compile artifacts without final public runtime defines, NOT install-ready RCs.
No development/preview endpoint found on release user routes; synthetic Essay routes
are not installed. Auth diagnostics are kReleaseMode-disabled; owner-check debug-only.
Required runtime defines include approved SUPABASE public config, redirect URLs,
PRIVACY_POLICY_URL, TERMS_URL and only verified provider/lifecycle feature flags.
Never pass server secrets via dart-define. No version/signing/key rotation was guessed.

## Auth and device evidence

Existing Owner login/session evidence is preserved; new provider device E2E was not run.
Local tests cover cancel/error/SDK restore/late owner/duplicate identity handling, not
real Google/Apple/Kakao Console state. Apple client-secret expiry date and Google secret
rotation status are UNKNOWN; request only dates/status, never key values. Kakao shared
identity is still separately unverified. Two physical iPhones were discoverable; device
selection/Owner interaction awaited. No Android hardware detected. Both deviceE2E
NOT_VERIFIED. Simulator/widget/render tests are not physical-device evidence.

Owner short device checklist (synthetic accounts only; deletion after authorized rollout):
1. Install signed RC; cold start guest; Home empty/meal/schedules and all5 tabs.
2. Materials search/filter/detail/PDF/external return, offline/invalid URL; bookmark and
   recent require login. A logout→B must not show A profile/avatar/saved/recent.
3. Timer start/pause/resume/end; background/foreground/interruption/restart; save offline
   then retry, duplicate tap, A→Guest→B. Guest records stay guest; clock rollback/reboot
   must not invent elapsed time. Local controller tests already cover these contracts.
4. Profile/school/grade/D-Day, mock record and LAB navigation; no mock fixture or buy CTA.
5. Login/logout/restore/cancel/error per enabled provider; confirm duplicate identities
   in Owner Console without exporting personal IDs. Small-screen2× text + keyboard.
6. Approved deletion lifecycle: failure/retry, pending restrictions, fresh cancel before
   deadline, due erasure, Storage/Auth verification, Apple revoke, local cleanup/logout.

## Reviewer package / Store handoff draft

Owner creates a durable Production email/password synthetic reviewer; no OTP dependency,
no real student data, valid through review. Store Console secure reviewer fields only;
never repository/Wiki. Do not use the isolated Payment TEST buyer/gateway as reviewer.
Suggested sample: synthetic profile/grade, harmless D-Day, one legitimate saved public
material, recent view, short study record/mock result; LAB catalogue access. No artificial
paid grant, no activation of AI/purchase solely for review. Empty states must also work.

Reviewer notes (FREE_LAUNCH draft, finalize only after blockers close):
“LegendStudy Plus is an education app. Guest users can browse/search learning materials
and use the local study timer. Sign in with the supplied email/password for profile,
saved/recent materials and account learning history. Tabs are Home, Materials, Learning,
LAB and MY. Materials open approved PDFs or the external browser. LAB includes implemented
mock-score summaries and essay catalogue; unavailable advanced analysis is labelled.
Math availability follows the submitted RC configuration. There is no in-app purchase or
Toss purchase button in this build. Account deletion is MY → Settings → 탈퇴 요청; web
request URL is supplied once deployed. Deletion has a disclosed14-day grace period.”
Do not submit this paragraph claiming working deletion until ProductionE2E passes.

Screenshot candidates: real Home, Materials, Timer, Learning record/mock, MY. LAB/Essay
only actual ACTIVE catalogue with synthetic user state; exclude coming-soon analyses,
Math before its closeout, and paid/evaluation states not active in RC. No screenshot
production performed. Rights facts: repository ingests metadata/source links; app fetches
specific external PDF bytes for viewing/cache. This is more than only an external link,
and is not a conclusion that content rights are owned. No unlimited in-app browser.

Store reconciliation: A17/B12 privacy drafts above but blocked; A18 system TLS/crypto
present, Owner export-compliance response required; A23 version/history gate; A24 iPad
unverified; A25 privacy choices/deletion URL blocked; B13 web backend/deploy gate;
B14 no ads; B18 permission inventory; B26 unsigned AAB compile; B27 com.legendstudy.app;
B28 target36. Education, Organization, D-U-N-Sverified, copyright2026주식회사코파카바나,
no12×14 personal-account requirement remain Owner facts. No new Store account/DUNS.
Original Manus Store report has no repository URL; this is an update handoff, not its rewrite.

## Remaining gates and next actions

Internal: finish Apple verified-token lifecycle connection; social reauth/cancellation;
final signed artifact SDK/privacy review; policy/retention reconciliation. Owner:
ADR2 production apply/deploy/scheduler/admission/restore approval; credentials metadata,
reviewer account, signing/build numbers, physical devices, Console privacy/age/rights/
export choices. Math closeout is external dependency. Public deletion and policy deploy
need separate approval. Code compile success does not remove these gates.
APP_RELEASE_CODE_READY:NO; ANDROID_RELEASE_READY:NO; IOS_RELEASE_READY:NO;
STORE_SUBMISSION_READY:NO. No Production writes, Edge deploy, Store upload, Toss calls,
main merge or Payment code changes. Commit/push only.

Official references (checked2026-10-04):
- [Apple revoke](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple)
- [Supabase Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple required reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)
- [Google deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
