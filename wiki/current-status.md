# Current Status

## 2026-09-23 — Owner device second final UX corrections (current)

- Photo unavailable root cause: a default-false App compile-time gate, not a
  bucket probe or RLS failure. Removed that stale gate; authenticated own-object
  pick/replace/delete uses existing private repository and ownership protection.
- PROFILE_AVATAR_STORAGE: OWNER APPLIED; PROFILE_AVATAR_RLS: VERIFIED by Owner SQL.
  Private profile-avatars, PNG, 1MiB, exact auth.uid()/avatar.png, four owner-only
  operations. App photo upload/replacement/deletion device E2E NOT VERIFIED.
  Server account-deletion deployment remains a separate OPEN release gate.
- Default new login lands HOME; trusted in-app protected navigation explicitly
  requests stack return. Arbitrary returnTo URLs are not accepted. Provider flows
  and session restore unchanged.
- Meals now find the first lunch/dinner date within D..D+6, D being the next day
  after today's eligible meal expires. Breakfast excluded from Home, retained in
  full selected-date detail; 14/19 KST, resume and date-boundary refresh retained.
- Vertical study bars: oldest left, newest right, proportional height, zero is
  zero; dynamic actual maximum (all-zero safe). Seven daily weekday slots, eight
  compact weeks and six months fit one screen without horizontal scrolling.
  MY uses section dividers and two outlined CTAs, Trend first.
  LAB entries and detail routes are independent: /lab/school-scores and existing
  /lab/scores. Unsupported internal grades remain honestly unavailable.
- Profile and school/grade Save await successful persistence then pop once; errors
  stay in place. Photo pending/failure blocks partial profile save. School search
  results sit directly under input; selected school is a draft until Save, followed
  by optional grade. Partial school success/grade failure stays open for retry.
- Settings keeps Profile edit / Basic information / Study settings; no account
  management heading above outlined logout, then policy/info and deletion.
- MEAL_OWNER_E2E: PASS (Owner iPhone acceptance after d7008bd). Meal code unchanged.
- Owner study inclusion migration APPLIED PASS: total_sessions=0,
  excluded_sessions=0, invalid_non_mock_exclusions=0. No new DB/Storage migration.
- Validation: Flutter 3.47.5 / Dart 3.13.4; 657 PASS / 1 existing skip;
  analyze, Android debug and iOS simulator builds PASS. Detailed render/security
  results (47 render cases) and policy evidence: [final policy audit](mobile-policy-audit.md).
- New MOBILE_UI_OWNER_E2E: NOT VERIFIED. Existing Owner Auth/session acceptance
  retained; policy/deletion/Store, Apple revoke/renewal and Google rotation OPEN.
  Production mutation 0; push NO. Owner iOS modifications preserved.

## 2026-09-23 — Owner Production Auth checkpoint

Owner reports App and LAB Email / Apple / Google / Kakao Production E2E PASS.
Apple Native App + LAB shared identity PASS; Web Services ID and Native App ID
coexist in the provider and native ID-token exchange passes. Google Native App
and LAB/App shared identity PASS. Kakao LAB/App shared identity NOT VERIFIED:
login success alone does not establish equal canonical auth.users.id.

LAB now uses Kakao OIDC + Supabase signInWithIdToken, with OIDC ON,
account_email required, profile_nickname/profile_image OFF. Cloudflare Pages
Functions performs token exchange. Owner confirms Production PASS after LAB
commit b4360b7: workerd rejected redirect:"error" before dispatch; redirect:"manual"
plus application rejection of 3xx resolves it. This is historical LAB evidence,
not this App repository's HEAD. No LAB code or provider settings changed here.

Earlier Kakao handoff pending statements are historical and superseded by this
Owner acceptance. Existing Email/session restore/MY school/grade device PASS
remain valid. Apple deletion revoke / secret renewal, Google credential rotation,
account deletion, policy and Store readiness gates remain OPEN; login acceptance
is not Store release acceptance.


Last reviewed: 2026-09-22

## 2026-09-22 Kakao iOS browser handoff — fix ready, device acceptance pending

- Owner: Kakao authorization/email-only scope/Supabase exchange/session creation
  PASS; browser X reveals authenticated App. Overall Kakao App E2E remains NOT
  VERIFIED until automatic handoff passes. Existing scope/consent/allow-list unchanged.
- Source trace identifies iOS platformDefault HTTPS as SFSafariViewController, with
  no auth-success dismissal integration. Kakao iOS alone now uses official SDK
  externalApplication; no sheet remains over Home. Actual new device result pending.
- Built plist custom/Google schemes expanded correctly. Existing Owner Info.plist/
  project.pbxproj edits byte-preserved. app_links 6.4.1/UIScene warning not treated
  as proof of failure; no native configuration or plugin change.
- Simulator token-free direct links resolve to LegendStudy+ OS Open confirmation;
  completion beyond confirmation NOT VERIFIED (Simulator UI binding unavailable).
  [Source audit, diagnostic procedure and evidence limits](auth-native-owner-acceptance.md#kakao-ios-browser-handoff--2026-09-22-current).
- Full 558 PASS/1 existing skip; analyze, iOS simulator/Android debug builds and
  secret/diff checks PASS. Email/Apple/Google/recovery regressions retained.
- Owner Apple and Google **LAB/App shared identity PASS** now recorded alongside
  their Production login PASS; Email/session restore PASS preserved. Apple revoke/
  renewal, Google rotation and other independent release gates remain OPEN.
  Production mutation 0; no push.

## 2026-09-22 Kakao scope correction / Owner Auth update

- Owner reports **Apple and Google App Production E2E PASS**. These supersede
  earlier Apple-blocked/Google-pending records below; Email/session restore PASS
  retained. Shared identity and operational release gates are not newly closed.
- Owner's final Kakao URL included disabled nickname/image scopes and duplicate
  account_email, causing KOE205. Source trace: server hardcoded defaults plus
  additive `scopes`; Flutter SDK itself adds no Kakao defaults.
- Kakao alone now uses official SDK `queryParams: {'scope': 'account_email'}`.
  Consent stays email-only; no provider console/native SDK/custom OAuth change.
  [Source evidence and Owner recheck](auth-native-owner-acceptance.md#kakao-koe205-scope-correction--2026-09-22-current).
- Full **558 PASS / 1 existing skip**; analyze, Android debug/iOS simulator builds,
  secret signature scan and diff check PASS. Owner iOS edits preserved.
- URL-generation seam passes on iOS/Android, retaining PKCE/callback and excluding
  profile scopes/duplicate email. Hosted final redirect and Kakao App E2E remain
  **NOT VERIFIED**; Owner retry required. Production mutation 0; no push.

## 2026-09-22 Home compact cards and inline meals — local verification complete

- D-Day/Study/Meal share 4px vertical card padding (was 8), 6px card gaps (was 8)
  and a clearer warm-neutral border. Content-driven height and minimum 48px
  actions retained. Configured school has no Home setup CTA, including semantics;
  only resolved unset school offers setup. MY school/grade behavior unchanged.
- Meal tap expands/collapses **inside Home**, with chevron and expanded semantics.
  Selected day's actual breakfast/lunch/dinner and today/tomorrow switch are inline;
  collapsed preview remains two lines and excludes breakfast. Unused imperative
  detail page removed after verifying no other references/deep-link route.
- Pure KST 14/19/midnight selection, raw queries, resume/revisit refresh unchanged.
  Prior Owner meal-policy PASS is preserved; **new compact/inline device review
  remains Owner action**. Bottom tabs and Home route remain during expansion.
- Full **556 PASS / 1 existing skip**; analyze, Android debug/iOS simulator builds,
  credential signature/log inspection and diff checks PASS. 360×640/428×926,
  1×/2× actual Flutter raster reviewed, including long menus and scroll to last
  meal. Four new Home route/render tests; 18 final Home/Study render tests PASS.
- No new P0/P1 found in this scoped render review. Prior P2 filter semantics/long
  content titles remain outside scope. No new physical-device or Apple E2E claim.
  Existing Owner iOS configuration changes preserved; Production mutation 0.

## 2026-09-22 Apple native failure — historical diagnosis (Owner now reports PASS)

- Owner iPhone Profile Apple attempt ends in generic failure. **App Apple E2E is
  BLOCKED / DIAGNOSIS REQUIRED**; actual failure stage/root cause not yet known.
- Added opt-in, non-Release, allowlisted Apple stage diagnostics and 7 native tests
  (native suite 11 PASS). No speculative Auth/provider/signing fix. Existing Owner
  native edits preserved. [Owner reproduction and interpretation](auth-native-owner-acceptance.md#apple-failure-diagnosis--2026-09-22-current).
- Email App/session restore/MY school/grade device PASS and LAB Web Apple PASS remain
  valid. Apple/shared identity E2E and operational gates remain open. Production
  mutation 0; no push.

## 2026-09-21 End-of-day canonical checkpoint

### Implementation and toolchain

- Starting checkpoint: branch `codex/day-7-school-neis`, HEAD `2fea4f2`
  (`fix: align meal preview and MY settings with device feedback`). Today's
  related implementation commits are `3199b25` (MY configured school/grade),
  `683915d` (Flutter/dependency maintenance), and `2fea4f2` (meal progression,
  Home LAB banner removal, MY Settings). Existing uncommitted iOS Owner edits and
  local artifacts are preserved; this checkpoint changes documentation only.
- Canonical development toolchain: Flutter **3.47.5 stable**, Dart **3.13.4**,
  SDK `/Users/woojinchang/development/flutter-3.47`, invoked through
  `./tool/flutterw`. The old shell PATH still selects Flutter 3.32.0 / Dart
  3.8.0 first; Owner global PATH was not changed.
- Ten safe dependency updates; no major migration. Supabase/app_links,
  Riverpod/go_router, lint major updates and iOS CocoaPods-to-SPM migration are
  deferred. Existing CocoaPods integration was retained to preserve working builds.

### Latest verified implementation and Owner E2E

- Latest automated results: `flutter analyze` PASS; `flutter test` **545 PASS / 1
  existing skip**; iOS simulator and Android debug builds PASS; credential/secret
  scan and `git diff --check` PASS. These supersede the earlier 508/513 test counts.
- Owner iPhone Profile E2E: `EMAIL_AUTH_APP_PRODUCTION_E2E: PASS`,
  `APP_SESSION_RESTORE: PASS`, `MY_SCHOOL_CONFIGURED_VALUE_DEVICE_E2E: PASS`,
  `MY_GRADE_CONFIGURED_VALUE_DEVICE_E2E: PASS`, and
  `MY_SETTINGS_DEVICE_E2E: PASS`. Existing LAB email/password account login,
  Home return and authenticated MY state were confirmed. LAB/App `auth.users.id`
  equality was not checked. The disconnected Debug home-screen relaunch message
  is a Flutter Debug tooling limitation, not a restore failure.
- Meal Home policy is KST-aware: breakfast excluded; 00:00–13:59 today's lunch;
  14:00–18:59 today's dinner when available, otherwise tomorrow; 19:00 onward
  tomorrow lunch first. Detail retains all meals served that date. Boundary,
  resume, revisit and raw-data reevaluation are covered. Owner iPhone result:
  `MEAL_TIME_AWARE_DEVICE_E2E: PASS`.
- `HOME_LAB_BANNER_REMOVED: YES` (Home promotion only; LAB remains available in
  MY). MY gear opens Settings; account operations, app info and legal links live
  there. `MY_SETTINGS_DEVICE_E2E: PASS`.

### Auth and release gates

- LAB Web production E2E remains PASS for Email, Google, Kakao, Apple and lifecycle.
- App Email production E2E is PASS. Google, Kakao and Apple App production E2E
  are **NOT VERIFIED**. Architecture targets one shared `auth.users.id`; actual
  LAB/App identity comparison is **NOT VERIFIED** for Email or social providers.
  This is Shared Account, not Shared Session.
- `APPLE_ACCOUNT_DELETION_REVOKE`, `APPLE_SECRET_RENEWAL_GATE`, and
  `GOOGLE_CREDENTIAL_ROTATION` remain OPEN. `ACCOUNT_DELETION_PRODUCTION_READY: NO`,
  `POLICY_PRODUCTION_READY: NO`, `STORE_RELEASE_READY: NO`.
- Next Owner sequence: Apple Native Login on iPhone → verify the same Apple
  identity in LAB/App → Google App login/identity → Kakao App login/identity →
  compare Email LAB/App identity → A/logout/B owner isolation. Close providers one
  at a time. See [Auth acceptance](auth-native-owner-acceptance.md).
- Remaining P2 polish candidates: filter selection semantics, long titles, nested
  screen bottom spacing/accessibility and one final mobile UI/UX pass after feature
  work. UI foundation is sufficient; avoid repeated polish before then.
- No code, database, Supabase, OAuth console, native configuration, dependency or
  production environment was changed in this documentation checkpoint. No push.

## 2026-09-21 iPhone Profile Owner acceptance and UX follow-up

- **Owner-reported Production/device PASS:** Email App Auth, App session restore,
  MY configured school and grade. These supersede the earlier pending statements
  below for those exact checks. No claim for social login or shared identity E2E.
- Fixed meal root cause: previous code/test contract kept all today's meals until
  17:00 and never ended dinner. Home now excludes breakfast; before 14:00 lunch,
  14:00–18:59 dinner if present else tomorrow, from 19:00 tomorrow lunch then dinner.
  KST 14/19/midnight timer, resume/revisit re-evaluate raw data; tomorrow loading/error
  no longer masquerades as empty. Tap opens dated full meal detail including breakfast.
- Home LAB banner removed only; MY LAB entry and external-link foundation preserved.
  MY gear → Settings → back; app version/policies/logout/deletion reused there,
  configured school/grade unchanged. Deletion/policy Production readiness still NO.
- Local full **545 PASS / 1 existing skip**, meal/Settings policy focused **31 PASS**,
  analyze, Android debug/iOS simulator builds PASS. 360/428px 1×/2× meal detail and
  360px/2× Settings raster reviewed. Owner confirmed meal and Settings UX on iPhone.
- [Root cause, policy and evidence](day-10-b-home-polish.md#owner-profile-follow-up--2026-09-21).
  Existing iOS edits preserved. Production mutation 0; no Auth implementation change.

## 2026-09-21 Toolchain maintenance — VERIFIED

- Canonical SDK is now **Flutter 3.47.5 stable / Dart 3.13.4**, at the existing
  flutter-3.47 path. Use `./tool/flutterw`; old PATH Flutter 3.32 and global shell
  settings are preserved. [Baseline, dependency decisions and migrations](flutter-toolchain.md).
- Ten preferences/URL-launcher compatible updates retained in pubspec.lock;
  constraints unchanged. Supabase/app_links, Riverpod/router migrations deferred.
  CocoaPods-to-SPM-only cleanup and coordinated Gradle/AGP/Kotlin upgrades deferred.
- Final intended graph: analyze PASS, **513 PASS / 1 existing skip**, Android debug
  and iOS simulator builds PASS; MY 360px/2× render retained. No new UI rewrite.
- SDK automatic broad pub upgrade was caught and removed before final regression;
  only the ten reviewed updates remain. Owner iOS edits byte-preserved/uncommitted.
- Profile/release physical E2E NOT VERIFIED; exact config command in README.
  No schema, Production mutation or push. MY fix/audit below remains current.

## 2026-09-21 MY school/grade display — FIXED / LOCAL VALIDATION PASS

- MY static setup copy hid configured values. It now reads canonical school/profile
  providers and separates label/value/설정 or 변경; loading and retryable failure
  are distinct from unset. Grade save invalidates the MY read provider.
- Full 513 PASS / 1 existing skip; analyze, Android debug/iOS simulator builds PASS.
  360×640/2× MY raster checked. [Root cause and core UI audit](core-app-improvements.md#my-configured-state-and-core-mobile-audit--2026-09-21).
- OAuth/session code unchanged. iOS disconnected Debug home-screen relaunch warning
  is not a restore failure; Owner iPhone Profile session restore is PASS.
- Existing Owner iOS native configuration edits preserved outside this change.
  No Production mutation or push. Policy release gate and audit P2 follow-ups remain.

## 2026-09-21 App Auth/native/shared-account — CODE READY / SOCIAL + IDENTITY E2E PENDING

- Google native Android/iOS and Apple native iOS ID-token exchange now use the
  existing Supabase session/events. Kakao and Android Apple keep browser PKCE;
  Kakao requests account_email only. Native Kakao SDK is NOT implemented.
- Local official-source Google/Kakao marks and SDK Apple mark replace text-only
  buttons; shared 52px minimum geometry, responsive scaling, global UI busy guard.
  Direct login → Home; protected login → original route without automatic save.
- Owner-reported LAB Web Auth (Email/verification/recovery/Google/Kakao/Apple/
  session) PASS on 2026-09-21 is preserved. App Email login/session restore PASS;
  Google/Kakao/Apple App E2E and App↔LAB user-ID equality remain NOT VERIFIED.
  Shared account is not shared session.
- Debug opt-in Owner checker performs GET-only identity comparison, outputs only
  match status, clears input and is absent in profile/release. No UUIDs recorded.
- Full **508 PASS / 1 existing skip**, new native/shared tests **7 PASS**, iOS
  offline rendered journey **9 PASS**, analyze PASS. 360×640/2× plus real iPhone
  simulator keyboard/social/recovery renders reviewed; no observed overflow.
  Android debug/iOS simulator builds PASS; credential/diff checks PASS.
- Owner gates: real client IDs/signing/provisioning, Google/Kakao/Apple E2E,
  identity match, physical A/B isolation; custom provider label/typography
  brand review. Apple revoke/secret renewal and Google secret rotation OPEN.
- Acceptance now tracks Code → Console → Device → Shared identity independently.
  Email App login and session restore are PASS. Next Owner stage: Apple Native Login
  on iPhone, Apple shared identity, Google, Kakao, Email identity, then A/B isolation.
  UI Foundation Complete; no repetitive polish in this phase.
- Deletion deployment/flag/Play URL, final App-reviewed policy/support URLs and
  operational credential gates remain open. Cross-provider linking is deferred;
  shared identity acceptance is required before Analytics implementation.
- [Exact setup and E2E checklist](auth-native-owner-acceptance.md). No LAB edits,
  console changes, schema/deployment or Production mutation. RELEASE READY NO.

## 2026-09-20 Product/platform canonicalization — DOCUMENTED ONLY

- [Product family/B2B](product-architecture.md) and [App/Web boundary](product-platform-boundaries.md)
  are canonical. LAB = multi-service Web Intelligence / Deep Work Platform;
  Essay is one module. Teacher/School and Portfolio are future roadmaps only.
- One auth.users identity/canonical dataset and one Analytics engine for B2C
  and batch/cohort B2B; scoped organizational authorization remains unimplemented.
  Evidence-based teacher drafts require review; security is requirements/targets,
  not a verified infrastructure or marketing claim.
- Priority: Auth Production → App/Web boundary → LAB authenticated IA/UX →
  Core release → Academic Record/Analytics → Essay → Teacher/School.
- Existing Auth release gates unchanged. Current app LAB copy remains essay-oriented;
  later copy/IA alignment needed. No code, DB, Production or B2B implementation.

## 2026-09-20 Auth/account lifecycle — CODE READY / PRODUCTION ACCEPTANCE PENDING

- Existing Auth reused. Signup verification redirect is centrally configurable;
  missing config retains Site URL fallback. Added email-forgotten guidance and
  existing support navigation with Back; safe configured policy links only.
- Expired/malformed SDK initial sessions now remain Guest until valid refresh.
  New-password owner changes clear fields and discard stale completion; no
  account lookup, identity database, LAB session sharing or Materials feature change.
- Full **501 PASS / 1 existing skip**, SDK **5 PASS**, UI **3 PASS**, native iOS
  offline journey **3 PASS**; 360×640/2× and real keyboard renders reviewed.
  Analyze, Android debug/iOS simulator builds, credential and diff checks PASS.
- Production config/E2E unverified. Owner gates: signup/recovery redirect and
  mailbox/device tests, OAuth console/identity acceptance, actual policy URLs,
  deletion deployment/flag/Play web URL; Apple revoke remains HOLD.
- Session restore evidence uses real SDK with in-memory storage/mock HTTP; no
  physical-device or Production persistence claim. Account identity remains
  dedicated `auth.users.id`; LAB's real auth configuration was not inspected.
- Production mutation **0**. [Canonical Auth evidence and Owner matrix](auth-recovery.md#account-lifecycle-completion-review--2026-09-20).

## 2026-09-20 Materials inline bookmark — IMPLEMENTED / LOCAL VALIDATION PASS

- Search results now expose 48px save/unsave controls with selected semantics,
  optimistic state, per-item busy guard and safe failure rollback. Tile navigation
  stays separate. Guest prompt pushes existing Auth and returns without auto-save.
- Detail/list share one owner-scoped store using existing bookmark writes/RLS.
  Membership reads coalesce into ID batches of at most 100, not N+1 or a truncated
  saved-list shortcut. Pagination loads only unseen IDs; account changes discard
  old state/responses. Same-owner token refresh preserves in-flight operations.
- Full **493 PASS / 1 existing skip**, new focused **11 PASS**, native iOS local
  journey **2 PASS**, analyze and Android debug/iOS simulator builds PASS.
  360×640 and iOS 1×/2× long-title/rollback renders reviewed. Credential/diff PASS.
- Query, six filters, pagination and scroll retained across login cancel/success;
  list↔detail saved state verified. No Production account/write test claimed.
  No schema, delivery resolver, Auth-provider, ingestion or LAB app-code changes.
- Details: [personal state](day-9-c-personal-state.md#materials-inline-bookmark--2026-09-20).
  Existing Auth/policy/deletion gates remain; **RELEASE READY NO**. Mutation 0.

## 2026-09-20 LegendStudy LAB app entry — IMPLEMENTED / LOCAL VALIDATION PASS

- Canonical public root `https://lab.legendstudy.com/`, one app URL definition;
  small shared Home card after recent updates and MY service entry, available
  to Guest/account alike. External browser only, safe retry/busy handling.
- Web is a separate service (`LC3808/legendstudy-lab`). Shared auth, session/profile
  handoff, payment/entitlement and record sync NOT IMPLEMENTED; WebView NOT USED.
- Full **482 PASS / 1 existing skip**, LAB focused **10 PASS**, analyze PASS;
  Android debug/iOS simulator builds PASS. Native iOS Home/MY 1×/2× renders and
  actual Safari launch/app return verified; 360×640 widget renders reviewed.
  Android physical-browser acceptance remains Owner follow-up, not claimed PASS.
- Corrected canonical: `/` returns HTTP 200; `/lab/` redirects to `/` with
  HTTP 308 (read-only verified). App already launches the root. Introductory copy makes no active AI/payment claim.
- Existing Auth/policy/deletion release gates remain: **RELEASE READY NO**.
  Production mutation 0. Details: [Core improvements](core-app-improvements.md#legendstudy-lab-production-entry--2026-09-20).

## 2026-09-20 Materials delivery — IMPLEMENTED / LOCAL VALIDATION PASS

- Independent free Materials access: centralized file/page/original/unavailable
  action, purpose CTA + destination host, conservative uncertain-link fallback.
  Direct/landing cards also offer original source; launch errors stay inline.
- Existing occurrence grouping/collapse, search/filter/loaded pages and return
  state preserved. Recent means intent/foreground dwell, not proven PDF reading.
  Search-row bookmark HOLD resolved by the inline increment above; no
  viewer/mirror/rights or ingestion changes.
- Full **472 PASS / 1 existing skip**, focused **64 + 2 PASS**, analyze PASS;
  Android debug/iOS simulator builds PASS. iOS native offline journey **2 PASS**
  at 1×/2× and 360×640 widget renders reviewed. Keyboard/OS safe-area adjustment
  allowed; selected row remains visible after return with no repeated query.
- Metadata lacks public health/expiry/auth flags; no official-source inference.
  No fresh Production schema/API or real website/file/browser-return E2E check.
  Owner destination/device acceptance and existing Auth/policy/deletion release
  gates remain. Scoped delivery COMPLETE YES; RELEASE READY NO. Mutation 0.
- Canonical audit/evidence: [resource delivery](day-9-c-resource-detail.md).

## 2026-09-20 Core Account/Auth — LOCAL UX TESTED / RELEASE GATES OPEN

- Email login/signup validation, confirmation, show/hide, autofill and duplicate
  request guards implemented; neutral recovery request copy and password controls.
- MY account/email, school/grade, saved/recent, support/policies and account
  management grouped; local logout busy/error handling added. Guest return still
  has no automatic save. A→Guest→B saved/recent isolation regression PASS.
- Unavailable deletion explains status with a feedback route; in-flight back
  blocked. Server deletion/local cleanup retry distinction preserved.
- Full Flutter **446 PASS / 1 existing skip**, focused **35 PASS**, analyze PASS;
  Android debug/iOS simulator build PASS. 360×640/2× form renders and Android
  login/OS keyboard reviewed; iOS install/launch/Home PASS. Production E2E pending.
- Provider flags remain off by default. Functional OAuth code tested; official
  social-button design HOLD. Policy URL paths ready, actual URLs Owner-required.
  Recovery email, provider/device callbacks, deletion deploy/flag/E2E/web URL and
  lifecycle decisions remain release gates. AUTH UX COMPLETE NO; RELEASE READY NO.
- Brand assets/native IDs and Historical work untouched; Production mutation 0.
  Canonical detail/matrix: [core-app-improvements.md](core-app-improvements.md).

## 2026-09-20 LegendStudy+ — BRAND IDENTITY COMPLETE

- Official display name 레전드스터디+ / LegendStudy+ retained; technical IDs,
  OAuth/deep links, native version and all in-app code unchanged.
- Owner 1024×1024 PNG `assets/brand/source/legendstudy_app_iocon_1024.png`
  confirmed as sole launcher source; source hash preserved. Earlier source HOLD
  resolved. Legacy/reference images retained and not used for launcher export.
- Android five densities + API26 adaptive resource; 60dp full-source image within
  108dp canvas, centered padding only. Circle/squircle mark containment PASS.
- iOS all existing iPhone/iPad/App Store sizes exported, fully opaque RGB;
  1024 RGB pixels match original exactly. Contents.json unchanged.
- Analyze PASS; full Flutter suite 427 PASS / 1 existing skip (includes four
  brand layout cases); Android debug and iOS simulator builds PASS.
- iPhone simulator launcher/name, white launch and Home PASS; Pixel 5/API36
  emulator circle launcher, official-icon splash and Home PASS. Squircle verified
  by offline mask render/safe-zone check. Brand focused renders 4 PASS.
- Both-platform brand ready; Owner review/push remains. Pixel app-drawer text
  may be ellipsized by the OS; full installed/accessibility label is correct.
- No Production mutation. See [brand record](../assets/brand/README.md).
  Core release/Owner gates remain separate from this brand task.

## 2026-09-20 Core App — CODE IMPLEMENTED / OWNER RELEASE GATES OPEN

- Current priority: independent free Materials journey → Core release quality →
  Daily Sync foundation. Analytics/BM/advanced Engine are deferred directions.
- Split month/type filters, actionable empty states, collapsible resource groups,
  truthful external CTAs, Guest login return, grade settings, native app version,
  policy URL seams and explicit OAuth availability implemented.
- Confirmed server deletion is separate from retryable device cleanup/logout.
  Sparse profile writes preserve existing name/grade/school information.
- Earlier Core pass: 423 PASS / 1 existing skip; latest Account pass above supersedes
  the suite count. Production E2E not performed in these UI tasks.
  Owner policy/provider/recovery/deletion/device gates remain; RELEASE READY NO.
- Inline result bookmarks HOLD; Daily Sync is a documented contract, LS LAB
  placement only. No ingestion/Production changes; prior physical results and
  Historical A2 gates remain unchanged.
- Details: [core-app-improvements.md](core-app-improvements.md). Older dated
  sections below retain historical context, not the active priority ordering.

## 2026-09-20 In-App Exam — PAPER-FIRST MODEL / ENGINE CONDITIONAL

- [Canonical architecture](architecture-in-app-exam.md) refines the Viewer-first
  order: solve on paper → exam selection/Attempt → answers → server score/grade
  → Academic Record → basic history/comparison. Viewer opening is not required;
  Viewer failure cannot block the engine. Optional Tablet route remains.
- Existing answer entry/scoring is a reusable GO foundation. Integrated Engine
  CONDITIONAL on validated keys/subjects/dataset and Record/lifecycle contracts;
  full implementation readiness NO for these dependencies, not PDF availability.
- Viewer CONDITIONAL on its separate benchmark/rights track; PDF mirror/Storage
  HOLD. Historical semantic/scoring validation and rights gates remain intact.
- Atomic persistence/revision/recovery, single execution owner, immutable answers,
  idempotency, versioned server scoring and entitlement design are preserved.
  Basic Record/comparison is V1; Advanced Analytics/AI strategy V2+.
- Monetization/retention centre on user academic history and personalized value;
  price/quota/tier decisions remain open. Documentation only, Production mutation 0.

## 2026-09-19 Monetization & In-App Learning strategy — PLANNED

Documentation only; nothing implemented, no price or product final, no
Production change, and no feature promoted into v1.0.

- Web and App are separate products: Web keeps search acquisition, the public
  archive and AdSense; the App carries FIND → VIEW → SOLVE → SCORE → RECORD →
  ANALYZE → IMPROVE. Features are now designed with their user value, app
  advantage, retention and monetization roles stated.
- Core study material moves toward in-app viewing, piloted on roughly three
  years × 고3 6월/9월 평가원 + 수능 by view demand. **Metadata coverage and
  viewer coverage are explicitly separate**, with the original source page as a
  permanent fallback. Any mirrored copy remains gated on the rights decision
  deferred in `day-9-ingestion.md`; the 2026-09-12 no-bulk-mirroring rule stands.
- Premium sells analysis, AI and continuity — not basic access. Candidate tiers
  FREE / BASIC / ADVANCED / MAX (superseding the Free/Basic/Pro sketch), an
  approximately three-use free trial as direction only, and subscription +
  credits for AI-heavy features, with MAX explicitly not "unlimited AI". The
  ₩4,900 one-time ad-removal purchase stays a separate product role.
- **Community is back on the map as PLANNED**, role FREE / RETENTION, starting
  with 학교 급식 자랑 (Meal-linked) and 잡담. It is not a launch blocker and not
  an early paywall centre; reporting, blocking, moderation, spam handling,
  personal-information and image safety plus an operator workflow are designed
  with the posting feature.
- Status: outbound resource open is the existing behaviour. In-app viewer,
  Storage mirror, viewer cache, viewer ↔ Mock Exam integration, free analysis
  trial, subscription, credit system, LS LAB subscription integration and
  Community are all **NOT IMPLEMENTED**; the tiers are **product concept only**.
- Detail: [roadmap-monetization-and-in-app-learning.md](roadmap-monetization-and-in-app-learning.md);
  durable rules in [decisions.md](decisions.md).

## 2026-09-19 Academic Analytics → Achievement → Admissions Engine — PLANNED

Documentation only; nothing was implemented and no Production change was made.

- Study and Mock Exam are now recorded as the first data sources of a longer
  chain: Subject Study Tracking → Academic Record → Academic Analytics →
  Achievement Engine, with Academic Profile → Target University/Department →
  Admissions Engine alongside. Sequence P1–P7 is a data dependency, not a forced
  release order.
- The badge idea returns as an **Achievement Engine** based on real learning
  behaviour and confirmed growth, with behaviour-based and growth-based
  achievements separated. Prediction-style badges are forbidden, and Achievement
  and Admissions stay separate systems.
- Binding boundaries: study time is not a direct admission-probability
  predictor; correlation is not stated as causation; a score gap is not an
  admission probability; LS LAB essay results are never summed onto the
  모의고사/내신 score scale.
- Status: Study core and Mock Exam/scoring are existing implementations.
  Academic Record, manual score entry, Subject Study Tracking, Academic
  Analytics, Achievement Engine, Target University/Department, Admissions Engine
  and admission prediction are all **NOT IMPLEMENTED**.
- Detail: [roadmap-academic-analytics.md](roadmap-academic-analytics.md);
  durable rules in [decisions.md](decisions.md). v1.0 scope is unchanged.

## 2026-09-18 LS LAB Core University selection — HOLD UNTIL OWNER REVIEW

**CORE UNIVERSITY SELECTION: HOLD.** The Owner has explicitly deferred the
CORE / NEXT / CATALOG_ONLY decision to next week's review. Nothing below is to
be decided by an agent in the meantime.

On hold until that review: Core selection; CORE/NEXT/CATALOG_ONLY assignment;
semantic verification of the 15 candidates; QuestionSet confirmation; Question
confirmation. **Gold Evaluation Package: NOT STARTED. AI evaluator: NOT
STARTED.** The 42-university Public Catalog is **PRESERVED** either way.

- **Essay-module product model (decision).** The LAB Essay module is not organised around a
  university's administrative 전형명. 논술우수자전형 / 논술전형 / 논술일반전형
  are all simply **ESSAY (논술)** to a student; the official name is kept as
  provenance metadata only. Canonical hierarchy: University → Essay → Essay
  Track → QuestionSet → Question. Track candidates: HUMANITIES,
  BUSINESS_ECONOMICS, NATURAL_ENGINEERING, MEDICAL_PHARMACY, ARTS_SPORTS,
  UNKNOWN. **Track, problem format, answer format and input mode are four
  separate axes and must never be collapsed into one another.**
- **Core-first depth (decision).** Service depth is CORE / NEXT / CATALOG_ONLY
  / UNDECIDED. Deep AI evaluation starts with roughly 10–15 Core candidates
  rather than all 42 shallowly. **Only the Product Owner selects Core** — no
  automatic score or model decides it. Every candidate is currently UNDECIDED /
  PENDING / OWNER_REVIEW_REQUIRED.
- **Owner-verified data principle.** For Core universities the 계열 relations
  (인문 / 상경 / 자연·공학 / 의예·약학 / 예체능), which 계열 actually share one
  paper, and the 장문 / 단문 / 약술 / 수리 / 과학 problem and answer types are
  settled by Owner verification, not by automatic projection. Verification
  stages (AUTO_DISCOVERED → RESEARCH_VERIFIED → OWNER_REVIEW_REQUIRED →
  OWNER_VERIFIED → GOLD_PACKAGE_READY → EVALUATOR_VALIDATED) are a concept
  only; no Production schema implements them.
- **Public Catalog (Phase 3-A.1 / 3-A.2).** 42 universities, 53 source
  administrative rows, 50 essay offerings, 101 essay tracks, 330 Quick Links.
  Structural QA **PASS**; publication readiness **CONDITIONAL**. Automatic
  EssayTrack projection is **not authoritative** before Owner review. Full
  42-university semantic perfection is **not** a launch gate, and the full
  semantic cleanup is not being done now.
- **Multimodal.** `answer_format` and `input_mode` stay separate. Future input
  modes: TEXT_EDITOR, HANDWRITTEN_IMAGE, TEXT_AND_IMAGE, SHORT_TEXT, UNKNOWN.
  Maths/science essays are headed for 종이 풀이 → 촬영 → quality gate → ordered
  multi-page upload → Vision interpretation → structured answer → evaluator,
  with original image provenance retained and **OCR text never the sole source
  of truth**. A future PC↔Mobile handoff uses a short-lived, attempt-scoped,
  single-purpose QR upload session that never carries a user id, JWT,
  service-role key or permanent token. **Current implementation: NONE.** V1 is
  text-first; multimodal is a staged rollout.
- **Gold Evaluation Package** (official intent, required reasoning, evaluation
  elements, official criteria, approved reference-answer elements, deduction
  elements, evaluator configuration) is a **private** asset and must never
  enter the Public Catalog. University 우수/합격자 답안 are structured as
  evaluation references, never as sentence-level correct answers.
- **Core strategy artifacts** prepared by Manus
  (`core-university-candidate-evidence.csv`, `official-source-inventory.csv`,
  `university-verification-template.csv`, `owner-decisions-template.csv`,
  `ls-lab-core-university-owner-review.xlsx` and its report) are **Owner review
  planning artifacts, not a Production DB and not Core assignment authority**.
- **Not this week:** additional university research, 42-university semantic
  cleanup, automatic Core ranking, Gold Package creation, AI evaluator content
  build. LS LAB university content classification is HOLD.
- **Next week resume order:** review 15 candidates → Owner decides
  CORE/NEXT/CATALOG_ONLY/HOLD → fix the Core set → pick Reference University #1
  → Owner inspects that university's recent official material → confirm tracks
  and paper sharing → QuestionSet → Question → Gold Evaluation Package v0.1 →
  AI evaluator benchmark. **Nothing from step 5 onward starts before the Owner
  review.**
- LS LAB for Schools (institutional credit purchase, per-student assignment,
  teacher/admin management, usage monitoring) stays a long-term direction
  after B2C, with Education Office / institutional expansion beyond it. Not
  implemented.

## 2026-09-18 P2-B Account deletion — FOUNDATION IMPLEMENTED (fail-closed)

**PRODUCTION ACCOUNT DELETION: PENDING.** Nothing was deployed and no account
was deleted. **PRIVACY LIFECYCLE: DESIGNED.**

- The schema already supports deletion: every user-owned table cascades from
  `auth.users` and `feedback_submissions.user_id` is `on delete set null`, so
  feedback is anonymised rather than destroyed and the Email Worker keeps
  working. **No migration is needed and none was written.**
- Deletion is server-authoritative. A candidate Edge Function
  (`supabase/functions/delete-account/`, not deployed) resolves the caller from
  the bearer token, ignores the body so no client can name a target, refuses
  admin members with 403, and answers the same way on a repeat so retries are
  safe. Widening RLS with client DELETE grants was rejected.
- The app ships the screen behind `ACCOUNT_DELETION_ENABLED`, off by default:
  the entry exists, states what is deleted and what is only detached, requires
  an acknowledgement plus a final dialog, and when unconfigured says the
  feature is not ready. No build shows a fake success, and a failed deletion
  neither signs out nor claims anything.
- Local study data is owner-keyed on the device; `purgeStudyOwner` removes only
  the departing owner's space, which is the same mechanism that keeps account
  switching clean.
- 14 Flutter tests, 9 Deno tests. **Mac verified 2026-09-18:** focused
  Auth/Deletion 63 PASS, full Flutter 412 PASS with one existing skip, analyze
  PASS, `deno test` for delete-account 9/9 PASS.
- Store policy read from the official pages: Apple requires in-app initiation
  and Sign in with Apple token revocation (an open gap for Apple OAuth); Google
  Play additionally requires a web deletion-request URL, which LegendStudy does
  not have because the domain question is undecided. See
  `wiki/account-deletion-privacy.md`.

## 2026-09-18 P2-A Social login — OAUTH CODE FOUNDATION READY

**GOOGLE / APPLE / KAKAO PRODUCTION E2E: PENDING.** No provider console,
Supabase Dashboard or Auth user was touched.

- Blocking gap closed: Android had no `login-callback` intent-filter, so a
  provider callback could not reach the app at all. iOS needed nothing — its
  scheme entry covers both callback hosts.
- Callbacks are now separated by host on one scheme: social login uses
  `com.legendstudy.app://login-callback` (declared as `oauthCallbackUrl`),
  recovery keeps `auth-recovery`.
- `signInWithOAuth` returns only "the provider page opened", which the old code
  ignored: a `false` result left every sign-in button disabled with no message.
  The busy flag is now always released and the outcome reported in Korean.
- Social login had no return policy; a successful session left the user sitting
  on the login screen. AuthPage now owns one policy for both password and
  social sign-in: leave `/auth` (pop, else `/my`), only on a `signedIn` event
  and only while still on `/auth`, so the two paths cannot fight,
  `tokenRefreshed`/`userUpdated` move no one, and a cold-start callback that
  starts elsewhere is left where it is. The router keeps a narrower job:
  recovery routes only.
- Cross-feature bug fixed: `access_denied` alone was treated as a recovery link
  failure, so cancelling a social login could open password recovery. The
  specific `error_code` is now consulted first and only specific codes count as
  link failures.
- An OAuth seam (`oauthServiceProvider`) makes the flow testable without a
  browser: `test/auth_oauth_test.dart`, 16 tests, including manifest regression
  guards. **Mac verified 2026-09-18** in the same run as the deletion gate.
- Account linking: v1 relies on Supabase automatic linking and adds no manual
  linking UI. The exact server-side linking rules are UNVERIFIED and must be
  measured during E2E — same email does not automatically mean same account,
  and Kakao may return no email while Apple may return a private relay address.
  See `Claude outputs/legendstudy-p2a-oauth-readiness.md`.

## 2026-09-20 Historical Phase 1-A1 — INVENTORY / BOUNDED DRY RUN COMPLETE

- Rechecked from current repository after the interrupted September 18 run.
  Current sample: **38 exams / 609 occurrences / 1,228 resources**. Historical
  1,205-resource report is a dated snapshot. Replayed original/current parsers
  and samples: `bf89548` added 23 explicit Box fixture entries plus parser and
  classification support; original 1,205 resource projections are unchanged.
  The added keys/URLs are distinct and source-backed; live payloads unverified.
- 2024 directly recounted: **15 exams / 246 occurrences / 489 resources**;
  grades 1/2/3 = 4/4/7. Grade-3 reference batch: **7 / 151 / 299**, inactive,
  provisional mappings; 7 expiration advisories and 3 unscoped-resource cases.
- Natural-key/locator collision and merge checks pass. Full resolved semantics
  are unchanged by 2026/2030 crawl timestamps; feed dates stay source-time 2024.
  Raw labels retained; no unsafe signing queries or automatic activation.
- Owner Production baseline preserved: 2020–2024 zero; 2025 15/246/507,
  2026 8/117/232; total 23/363/739. No inference about future/unpublished 2026
  sessions. Production's 23 open expiration rows are not assumed 1:1 with exams.
- **Phase 1-A2 structural preflight COMPLETE (Owner 15-row probe scope).**
  Owner reconfirmed Production 23/363/739, no 2024 exams, and subsequently
  reported all 15 source/content IDs NULL with zero child/provenance and exact
  foreign canonical URL/slug conflicts. Natural-key overlap absent within that
  scope; semantic duplicates, URL aliases/file bytes and unrelated UUID PK
  collisions are not proven absent. A1 remains COMPLETE.
- **2024 PUBLICATION READY: NO.** Semantic review, provisional subject mapping,
  ambiguous files (생화활과윤리 / 사회문화1 / 수학(미정)), all 10 grade-3 candidate
  quarantine cases and actual file availability remain unresolved. Keep inactive
  candidates; final Owner publication approval is still required.
- Validation rerun: 150 ingestion/historical tests PASS (including CSV/key
  regression); diff check PASS. No Production mutation or publication SQL.
- Next: **semantic/quarantine/file validation**, beginning with Owner meaning
  review of posts 1618/1646/1649; no automatic remap or publication. Refresh
  structural preflight before a future authorized write. See
  [A2 evidence and gates](../reports/historical-exam/2024-production-preflight.md)
  and [historical handoff](../reports/historical-exam/codex-historical-exam-phase1-handoff.md).
- Future In-App PDF Viewer Pilot remains separate: recent three years' grade-3
  June/September evaluation mocks and CSAT. No download/mirror/viewer work here.
  Production mutation **0**. No ingestion, activation, migration or push.

## 2026-09-18 LS LAB Production Web architecture — APPROVED / DOCUMENTED

- Manus Phase 0/1 research is complete: 42 unique universities and 53 2027
  recruitment-unit rows (Seoul 27, non-Seoul 26), with 39 official-confirmed
  and 14 official-partial rows; 42/42 source audits; historical source
  metadata for 2024–2026 (59/62/67, 188 total); 330 official Quick Link
  candidates; 188 component availability records; 42 rights/use records; 42
  evaluation-readiness records; and a 13-sheet workbook. These figures do not
  authorize Production ingestion.
- Canonical Production direction is **Next.js App Router + TypeScript** in a
  separate `LC3808/legendstudy-lab-web` repository candidate. The current
  React/Vite/Express/tRPC Manus foundation remains mock/prototype only;
  `LC3808/legendstudy-app` remains Flutter Mobile-only.
- Public Web exposes metadata, provenance and official Quick Links. Normalized
  source-derived assets, evaluation assets and user-private data stay behind
  server/private boundaries. Official source, LS LAB-derived, model-derived
  and human-reviewed material must remain distinct.
- Shared Supabase Auth is the direction, not an implementation: LS LAB schema
  and RLS must be isolated from Mobile data. No Production Supabase/Auth/DB,
  live AI, payment, domain or public deployment changes are approved here.
- Phase 2 is Next.js Web Foundation Migration. Evaluation jobs and
  server-authoritative credits remain conceptual contracts pending separate
  implementation design.

## 2026-09-18 Day 11-B4-C — COMPLETE / Production delivery E2E + Cron

- Feedback Email Delivery Production E2E is **COMPLETE**. Owner confirmed
  receipt in the operational Gmail mailbox with the verified sender,
  subject, Korean content, metadata and Feedback ID. Resend delivery is
  Production-verified.
- The Owner-confirmed test fixture was processed exactly once:
  `claimed=1, sent=1, failed=0`; DB postflight showed `sent`,
  `attempt_count=1`, non-null `sent_at`, cleared claim fields and no error.
- The exact fixture and cascaded notification were then deleted by ID.
  Target feedback/notification counts are 0; remaining TEST feedback/outbox
  counts are 0; actionable outbox count is 0.
- Recipient configuration now points to the Owner-controlled operational
  Gmail mailbox. The admin Auth identity and notification mailbox remain
  separate. Sender remains `feedback@legendstudy.com`.
- `FEEDBACK_WORKER_SECRET` was rotated once because its previous raw value was
  unavailable; no other secret was changed. The rotated value is stored in
  Supabase Vault for scheduling and is not recorded here.
- Cron is **ENABLED**: one active `pg_cron` job named
  `legendstudy_feedback_notification_worker`, schedule `* * * * *`, exact
  LegendStudy worker endpoint, POST via `pg_net`, Vault-held
  `x-feedback-worker-secret`, no service-role key, no duplicate job.
- No second test fixture was created and no additional worker invocation was
  made. Follow-up is natural scheduler monitoring; do not send another test
  email solely for scheduler acceptance.

## 2026-09-18 Auth Recovery — PRODUCTION READINESS PREPARED

Code state: **CODE VERIFIED / PRODUCTION READINESS PREPARED. PRODUCTION
RECOVERY E2E still PENDING** — no redirect was registered and no recovery email
was ever sent.

- Blocking gap found and closed: neither platform registered any deep link, so
  a recovery email could not have opened the app at all. iOS now declares the
  `com.legendstudy.app` URL scheme and Android a BROWSABLE intent-filter for
  `com.legendstudy.app://auth-recovery`, declared once as `recoveryDeepLink`.
- Custom scheme over a universal link because `legendstudy.com` is Tistory:
  `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`
  both return 404 and cannot be hosted, so recovery would otherwise be blocked
  on a domain with separately verified association-file support. The scheme matches the OAuth callback the app
  already used.
- An expired, already-used or wrong-device link arrives as a stream error, not
  an event, and used to be silent; it now opens `/auth/recovery?reason=link`
  with Korean copy. Unrelated auth failures cannot hijack navigation.
- Cold start needs no recovery-intent state: `onAuthStateChange` is a
  BehaviorSubject and the SDK starts its deep-link observer inside
  `Supabase.initialize`, so `fireImmediately` already covers it.
- Focused tests 19 → 27, including regression guards that fail if the platform
  deep-link registration is ever dropped. **Mac verified 2026-09-18.**
- Owner actions before E2E: a mailbox that actually receives mail, registering
  the redirect URL in Supabase, and confirming the Site URL. PKCE also requires
  the link to be opened on the install that requested it. See
  `Claude outputs/legendstudy-auth-recovery-production-readiness.md`.

## 2026-09-17 Final closeout — Auth Recovery + Feedback Email (historical baseline)

### Auth Recovery — COMPLETE / CODE VERIFIED

- The forgot-password entry, `resetPasswordForEmail` foundation,
  configurable `SUPABASE_RECOVERY_REDIRECT`, password-recovery event routing,
  `/auth/new-password`, `updateUser(password)`, recovery-session guard and
  duplicate-submit guard are implemented.
- UX is account-enumeration safe and maps raw Auth errors, including invalid
  credentials and same-password/weak-password cases, to Korean messages.
  Recovery tokens, passwords and JWTs are never logged.
- Final routing hardening preserved specific same-password error matching,
  mounted the router with `ref.watch` in tests, and enabled
  `fireImmediately` to cover an already-current recovery event.
- Owner verification: focused `test/auth_recovery_test.dart` 19/19 PASS;
  full Flutter suite 368 PASS with one existing opt-in test skipped; Flutter
  analyze reports no issues.
- Production Recovery E2E remains PENDING: choose/register the redirect URI,
  receive a real recovery email, verify deep/app link, set a new password,
  sign in again, and complete iOS physical acceptance.

### Feedback Email Worker — DEPLOYED / DELIVERY E2E PENDING (superseded by B4-C above)

- B4-A is COMPLETE. B4-B is IMPLEMENTED, REVIEWED and Production DEPLOYED:
  Resend sender domain is verified, the worker migration is applied, the Edge
  Function is deployed, and required Secrets are configured.
- Owner-confirmed safeguards include wrong-secret Production acceptance
  (`403 forbidden`), Deno 2.9.6 runtime tests 5/5, `deno check`, postflight,
  service-role-only RPCs, and verified claim/lease/retry/token semantics.
- Historical snapshot superseded by B4-C: at that time Feedback Email
  Delivery E2E was NOT COMPLETE, Cron was NOT ENABLED, and no successful
  worker invocation or mailbox receipt had been verified.

### Closeout priority

P0 Auth Recovery Production E2E → P1 OAuth completion and account
deletion/privacy lifecycle → P2 Day 13-A User Type & Home Personalization → P3
Day 13-B NEIS Timetable → P4 v1 Gap Audit → P5
app-wide UI/UX polish. Essay Lab remains on its existing roadmap.

## Day 11-B3 final follow-up — COMPLETE

- Owner-confirmed physical Production E2E on a new iPhone (iOS 26.4.2): user
  feedback submission, Admin Inbox list/detail, diagnostics and
  `new → reviewing → resolved` synchronization all passed.
- Fixed the login UX bug where successful password authentication left the
  login route visible. Navigation now waits for the matching authenticated
  identity, returns to the prior route, and falls back to `/my` only when the
  route cannot be popped. Authenticated MY school/grade copy is no longer
  guest-only wording.
- At this earlier B3 follow-up snapshot, the Email Worker remained not
  implemented; account-switch isolation and the previously verified
  Production DB/RLS contract remain unchanged.

## Day 11-B4-A — Feedback Email architecture — DESIGN COMPLETE

- Recommended provider is Resend behind a provider-neutral Edge Function
  adapter. The current outbox was audited; safe concurrent processing needs a
  small future claim/lease/retry migration because it has no processing state
  or atomic claim token.
- At the B4-A design stage, no Edge Function deploy, Resend account/DNS,
  secret, email or Production DB mutation was performed. See
  [Day 11-B4 Feedback Email](day-11-b4-feedback-email.md).
- Historical B4-A snapshot: B4-B was deployed and reviewed while controlled
  delivery E2E and Cron enablement remained pending; B4-C is now complete.

## Day 11-B4-B — Feedback Email Worker — IMPLEMENTED / REVIEWED / PRODUCTION DEPLOYED (historical baseline)

- The migration, service-role-only claim/finalize/reclaim RPCs, secret-gated
  Deno Edge Function, provider-neutral adapter and Resend implementation are
  Owner-confirmed Production deployed/configured.
- Deno 2.9.6 runtime tests pass 5/5 and `deno check` passes. Wrong-secret
  Production acceptance returns `403 forbidden`; postflight and RPC privilege
  checks pass.
- Historical B4-B snapshot: Email Delivery E2E was pending and Cron was
  disabled. B4-C is complete in the closeout section above.

## Next backlog — Day 13

- **Day 13-A User Type & Home Personalization:** add 고등학생, N수생, 학부모,
  교사/강사, 기타 as recommendation preferences only; add MY home settings,
  cloud-persisted visibility for D-Day, study time, next timetable, school
  meal, search, updates and recent views. Do not use user type to block meal
  or timetable features.
- **Day 13-B NEIS timetable:** school/grade/class, next school-day timetable,
  Home summary and MY detail, weekend/holiday/vacation/data-empty handling and
  Home ON/OFF. Implementation is deferred.
- **LEGENDSTUDY APP-WIDE UI/UX POLISH:** after core functionality, improve the
  shared design system across Login, Home, Materials, Study, MY, Feedback and
  Admin (surface hierarchy, elevation, typography, spacing, semantic colors,
  icons, buttons, chips, states, motion and consistency). Avoid screen-by-
  screen temporary polishing.

## Day 11-B3 — Production Admin Inbox — COMPLETE / E2E PASS

- Added the MY admin menu, guarded Admin Inbox list/detail routes, server-derived
  `is_feedback_admin()` access state, newest-first bounded listing, status
  filters, diagnostics and forward-only status management.
- Production feedback DB/RLS and Admin JWT acceptance remain verified. This
  task made no Production API call or mutation. Controlled user submission →
  Admin Inbox → 확인중 → 처리완료 E2E is Owner-confirmed PASS.
- At the earlier B1 snapshot, Email Worker/provider/secrets and reverse status
  transitions remained pending; account-deletion retention/anonymization is
  still an Owner decision. See
  [Day 11-B3 Admin Inbox](day-11-b3-admin-inbox.md).

## Day 11-B1 — Feedback Production security closeout — COMPLETE

- Owner applied `supabase/migrations/20260917000100_feedback_operations.sql`;
  all three feedback tables have RLS enabled and the expected grants/functions
  were verified. Production DB/RLS security is **PRODUCTION VERIFIED**.
- Final real JWT/RLS run `4060f61751ae` passed anon insert, A/B insert and own
  resolution, owner derivation, cross-user denial, status immutability for a
  normal user, admin/outbox denial and exactly-one pending email outbox row.
- Owner removed all five TEST feedback rows from the failed/successful runs;
  remaining TEST feedback/outbox rows are 0/0. Feedback JWT/RLS acceptance is
  **COMPLETE**. The earlier “not applied” B1 state is historical/superseded.
- Admin bootstrap and Admin JWT acceptance are complete. Admin Inbox UI and
  Production E2E are complete. Email worker/provider,
  secrets, admin email, test email and push remain **NOT DONE**. Open policy
  decisions are account-deletion retention/anonymization and reverse status
  transitions. See [Day 11-B1 closeout](day-11-b-feedback-production.md).

## Day 12 — Home Information Architecture & Visual Hierarchy

- Home order is now D-Day → 나의 공부 시간 → 우리학교 급식 → 자료 검색 →
  최근 본 자료 → 최근 업데이트.
- Recent views remain the existing owner-scoped, cloud-backed personal list and
  precede the global update feed; no local-only preference was added. Further
  personalization that requires profile/schema, Guest/Auth merge, cloud
  persistence policy or Day 13-A user types is deferred to that work.
- Removed the duplicate `오늘의 공부` heading. Populated Study state emphasizes
  today’s duration; empty state remains concise and existing data contracts are
  unchanged.
- Added restrained semantic Home accents in `AppTokens`: orange D-Day, indigo
  Study, green Meal, blue Search, amber Updates and violet Recent. Cards remain
  neutral with a soft accent band; no database, provider or navigation behavior
  changed.
- Focused and full Flutter tests, analyze, Android debug build, iOS simulator
  build and physical iPhone Profile launch passed. See [Day 12 Home visual
  hierarchy](day-12-home-visual-hierarchy.md).

## Day 11 — Account & Personal Foundation + Feedback Operations

- Added a minimal Auth screen using the existing Supabase SDK: email/password
  signup/login, Google/Apple/Kakao OAuth entry points, logout and owner-profile
  upsert attempt. Provider dashboard/redirect acceptance remains pending.
- Recent views now use foreground-only meaningful tracking: 10 seconds or an
  explicit resource/original open attempt or successful bookmark. Background
  time is excluded, rebuilds do not write, and MY supports owner-scoped
  individual/all deletion with confirmation.
- Added guest-capable feedback form with bounded title/body, category and safe
  diagnostic metadata. The original draft remains historical; the reviewed
  migration is now Production-applied and JWT/RLS-verified.
- Admin Inbox and email delivery remain incomplete pending admin assignment and
  server-side provider implementation. See
  [Day 11 account/personal/feedback](day-11-account-personal-feedback.md).

## Day 10-C — Legacy Subject Alias minimum foundation

- Implemented an offline deterministic alias resolver that preserves every raw
  subject label and separates `SAFE_ALIAS`, `REVIEW_REQUIRED`,
  `HISTORICAL_DISTINCT` and `UNKNOWN` outcomes. No DB migration or historical
  ingestion was run.
- Search accepts observed full-name numeric/formatting aliases through the
  released canonical subject lookup; filters remain bounded to the 23 canonical
  subjects. Physics and life-science display names may show a short legacy name
  in parentheses.
- `물리1`, `생물1/2`, 가형/나형, 국사 and other historical labels remain held or
  distinct until year/curriculum review. See [Legacy Subject Alias](legacy-subject-aliases.md).
- Python ingestion tests (146) and targeted Flutter search/UI tests (52) pass;
  Flutter 3.47.3 analyze is clean. The roughly 1,400-post legacy ingestion is
  explicitly deferred so Essay Lab inventory can proceed next.

## Day 10-B — Home Polish v2

Historical implementation snapshot; the meal policy and Owner evidence below have
been superseded by the [2026-09-21 checkpoint](#2026-09-21-end-of-day-canonical-checkpoint)
and [current meal contract](day-10-b-home-polish.md#owner-profile-follow-up--2026-09-21).

- Originally implemented KST-based today/tomorrow meal display with 17:00 dinner and
  tomorrow priority, boundary/resume refresh, and no empty tomorrow section.
- Home recent updates and recent views are now bounded to six records, show two
  by default, and independently expand/collapse to six. Full Materials/MY
  semantics and guest/auth account isolation remain unchanged.
- Full tests (335 passed, one opt-in read-only network skip), analyze, Android
  debug build and iOS simulator build/run pass. iPhone Profile built, but
  CoreDevice automated launch timed out before interactive Home verification.
- Details and remaining device follow-up: [Day 10-B Home Polish](day-10-b-home-polish.md).

## Essay Lab / LS LAB product roadmap — PLANNED

- Before university inventory, survey nationwide all 2027학년도 수시 논술
  실시 대학 from official sources.
- First wave: broad Seoul coverage plus representative non-Seoul universities
  with materially different formats; exact count follows the survey.
- Inventory the latest three years where available, marking missing official
  materials explicitly and never filling them with guesses.
- Keep `long_essay` and `short_response` as separate initial tracks and do not
  force one evaluation contract across them.
- LegendStudy LAB is multi-service; canonical domain is **lab.legendstudy.com**.
  Essay Lab is Web-primary, with the App focused on discovery, results,
  notifications and simple records/connections.
- Manus work proceeds as Phase 0 nationwide survey, Phase 1 first-wave
  selection/material inventory, and Phase 2 LS LAB Web MVP foundation.
- The first approximately three evaluations remain the free-credit direction;
  My Essay Pattern and cumulative growth data remain important. Pricing is
  undecided. No Essay Lab code, schema, AI evaluation, credit, payment or
  Production work is implemented by this roadmap entry. See [Essay Lab
  roadmap](roadmap-essay-lab.md).

## Day 10-A — Flutter 3.47.3 official toolchain migration — COMPLETE

Historical toolchain milestone; current canonical SDK/helper and deferred native
migration decisions are documented in [flutter-toolchain.md](flutter-toolchain.md).

- Official repository baseline is now Flutter **3.47.3** / Dart **3.13.3** from
  `/Users/woojinchang/development/flutter-3.47`. The original
  `/Users/woojinchang/development/flutter` Flutter 3.32.0 / Dart 3.8.0 SDK is
  preserved unchanged as rollback/reference tooling.
- `pubspec.yaml` now requires Dart `^3.13.3` and Flutter `>=3.47.3`; direct
  package constraints were not upgraded. `pubspec.lock` contains the 15
  transitive/SDK resolution changes required by Dart 3.13.3. Analyze is clean
  and the full test baseline remains 316 passed with one opt-in read-only
  network test skipped.
- Android dependency validation passes normally with Gradle 8.14, AGP 8.11.1,
  Kotlin 2.2.20 and NDK 28.2.13676358. Flutter's required
  `android.builtInKotlin=false` and `android.newDsl=false` properties are
  retained. `flutter build apk --debug` passes without a skip flag.
- iOS minimum 15.0 and `ARCHS = arm64` remain repository-native. Flutter 3.47
  Swift Package Manager generated integration is accepted while CocoaPods is
  retained for the existing plugin setup. The custom AppDelegate was migrated
  to `FlutterImplicitEngineDelegate` and the Flutter `UIScene` manifest was
  added. Simulator build/run passes and the Home screen rendered normally.
  The previously verified Flutter 3.47.3 iPhone Profile launch also passes;
  Debug recheck remains dependent on the CoreDevice becoming available.
- No Production DB/publication/is_active/RLS/ingestion change was made. No
  Flutter product feature was added.

## Confirmed Pilot C publication — COMPLETE

- The Product Owner confirms Pilot C publication was executed after the D1
  package: subjects 23/23 active, content_items 23/23, exam_subjects 363/363,
  and resources 739/739 active. Resource breakdown remains question 360,
  answer_explanation 356 and listening_audio 23.
- Owner-confirmed anon RLS counts are public_content_items 23, public_exams 23,
  public_exam_subjects 363, public_resources 739 and public_subjects 23.
  Publication rollback was not executed. The older D1 package note saying
  publication was not executed is historical and superseded by this section.

## Backlog / TODO recorded during Day 10-A (historical snapshot)

- Home Meal Card v2 (superseded): today/tomorrow data, the 17:00 KST dinner boundary,
  conditional lunch/dinner rows, date-boundary refresh, and independent
  expand/collapse behavior.
- Home recent updates and recent views: show two by default, expand to at most
  six, preserve descending order, hide More at two or fewer, and use a shared
  independent expandable-section interaction. Full recent history remains in
  Materials or MY respectively.
- MY 문의·건의사항: inquiry/bug report/feature suggestion/other categories,
  title and body, server-derived authenticated identity, minimal diagnostics,
  and a privacy-sensitive backend/RLS design.
- Legacy Subject Alias: preserve `raw_subject_label`, separate canonical
  taxonomy from searchable aliases, and define mappings for legacy subjects
  before historical ingestion.

## iOS deployment target closeout — 2026-09-16

- Official iOS minimum deployment target is now **15.0** in `ios/Podfile` and
  all Runner Debug/Profile/Release project configurations. Podfile
  `post_install` also pins every generated Pods target to 15.0, covering plugin
  podspecs that still declare iOS 12.0.
- Xcode 27 default simulator build initially exposed a separate Flutter engine
  architecture mismatch; Runner configurations now use repository-native
  `ARCHS = arm64`, matching the Apple Silicon Flutter engine. No external
  xcconfig is required. Default `flutter build ios --simulator --no-codesign`
  PASS.
- `flutter pub get`, `pod install`, `flutter analyze`, and full Flutter tests
  PASS (316 passed, 1 read-only network test skipped). The connected iPhone
  `00008101-001C39E02E61001E` built, installed and launched Runner; device
  process inspection confirmed Runner processes. The resident runner was
  interrupted after launch, so this is not a full interactive runtime claim.
- No Flutter feature logic, Android configuration, DB, publication data, RLS,
  push, PR or merge changed.

## iPhone native startup diagnosis — 2026-09-16

- On Flutter 3.32.0/Dart 3.8.0 with Xcode 27 and iOS 26.6.1, both device
  `flutter run` Debug and Profile reproduce the same pre-`main.dart` abort in
  `Dart_Initialize`/`DartVM::Create`; no Flutter UI is rendered on the iPhone.
- The startup stack matches the known iOS 26 physical-device Flutter 3.32
  failure, whose upstream report identifies the RX/RW memory-protection
  assertion. Simulator Debug runs normally, so this is a Flutter
  engine/toolchain and iOS 26 device compatibility issue, not a feature/runtime
  or RLS issue.
- Repository iOS settings remain unchanged by this diagnosis. `ARCHS = arm64`
  is valid for both the device and Apple-Silicon simulator engine slices and is
  not the cause. Use a Flutter SDK version with the iOS 26 physical-device fix
  for device Debug/Profile validation; the current SDK is suitable for the
  verified simulator path only. No production or publication data changed.

## Day 9-D1 — Pilot C publication package

- Publication package implemented in `tool/publish_pilot_c.py` with offline
  contract tests. It resolves only the exact 23-post Pilot C chain and uses one
  fail-closed transaction: `content_items → exam_subjects → resources`.
- Preflight requires the recorded production baseline, exact scope counts,
  zero signed URLs/duplicates/orphans/blocking quarantine, and 0/0/0 active
  rows. Exact 23/363/739 is an idempotent read-only no-op; partial active state
  fails closed. Rollback is soft deactivation only and was not executed.
- Anon public-projection/RLS and post-publication Search acceptance queries were
  prepared. The package itself made no Production mutation; the later
  Product-Owner publication result is recorded in the current authoritative
  section above. See the [Day 9-D1 package](day-9-d1-publication-package.md)
  for the guarded transaction and rollback contract.

## Phase

**Day 7 = COMPLETE. Day 8-A Study Core = COMPLETE. Day 8-B Focus / DND implemented; Owner-reported iOS lifecycle subset PASS, Focus guidance and remaining physical checks pending. Day 8-C Mock Exam implementation complete; Guest/Auth Flutter runtime PASS; Owner-reported iPhone timeUp/notification/kill-restore PASS, remaining physical checks pending. Day 8-D1 Scoring Storage / Validation Contract = COMPLETE (Owner-reported production/Postflight and actual A/B JWT/RPC PASS); Day 8-D2 Answer Entry + Raw Score = COMPLETE (Guest runtime and Owner-reported actual A/B Flutter scoring PASS). Day 8-D3 Grade + Result UX = COMPLETE (Owner-reported actual A/B Flutter runtime and full cleanup/retention PASS). Day 8 overall is not COMPLETE.**

Product Owner accepted the final runtime results. Day 7 live deployment/JWT/Flutter results below are owner-reported.
Day 8 production migration and full real A/B Study JWT acceptance are also
owner-confirmed. The final Day 8-A Flutter Guest/authenticated runtime PASS is
also Owner-reported and matches the checked-in smoke stages. Prior implementation
checks are retained below. Day 8-B implementation checks are listed separately;
no production calls or DB changes were made for Focus. Earlier implementation checkpoints remain
in [log.md](log.md); this page describes the current state rather than historical gates.

## Day 9-A Search / Explore — COMPLETE

- Materials now provides metadata search, dynamic filters, grouped attachments,
  bounded pagination, explicit empty/error/retry states and Home query handoff.
  Public repository/controller/UI layers and test-only fixtures are separate.
- Read-only public counts: content_items/exams/subjects/exam_subjects/resources
  each 0 on 2026-09-15. Real Supabase SDK search/filters/later-page contract PASS.
  No production fixtures, ingestion, DB/schema/RPC/migration or personal writes.
- Desktop Flutter screenshots reviewed at 360×640/428×926 and 1×/2×. Analyze,
  full 306 tests (one opt-in network test skipped),29 render/handoff tests, separate
  real-SDK public read-only smoke, Android debug and diff/credential checks PASS.
  iOS simulator native 1×/2× review and real software-keyboard inset checks PASS.
  Simulator/profile builds PASS using external Xcode27 iOS15/arm64 overrides;
  official iOS15/arm64 project settings are now repository-native; the external
  validation override is no longer required. This is not a release-signing claim.
- 26 OS-level native screenshots reviewed; normal simulator app restored. No
  physical iPhone connected in this follow-up; prior Day8 physical PASS preserved.
  Day9-B real ingestion and9-C/9-D remain separate. No production writes.
- [Search design, API constraints and Day 9-B/C handoff](day-9-search-explore.md).

## Study/Home UI polish and iPhone acceptance update

- Meal expand/collapse, full lunch/dinner, descending seven-day rows, distinct
  pause/resume and selected mode styles implemented. Mock defaults to 국어80;
  영어45 · 듣기 제외 and 한국사30 added in exam order; UI says 시험 시간.
- Owner-reported iPhone profile launch, Study start, background/lock continuation,
  pause, mock timeUp, local notification and complete kill/relaunch restore PASS.
- Focus guidance is still pending; Android physical and reboot/remaining lifecycle
  checks remain open. These reports supersede blanket iOS-pending wording in older
  checkpoints below, without marking B/C or Day8 COMPLETE.
- Analyze, all257 Flutter tests,14 rendered polish tests, Android debug and iOS
  simulator builds PASS. Actual iPhone12 Pro Max profile UI harness at1×/2× PASS;
  22 screenshots reviewed separately from Owner-reported lifecycle results.
- [Polish scope and UI evidence](study-home-ui-polish.md). D3 A/B runtime issues
  remain separate. No DB/schema/migration/RPC changes or Push/PR/Merge.

## Day 8-D3 Grade + Result UX — COMPLETE

- Owner reports actual A/B Flutter runtime PASS: login, confirmed/estimated/unavailable
  grades, summary, answer review, provenance, native restore, historical-version
  semantics, exact retry, account isolation, legacy fallback and Study/Home navigation.
- Local fixture cleanup and run-UUID scope, production fixture cleanup, three-trigger
  restoration, scoring baseline, existing-data preservation and Auth retention PASS.
  Final `Flutter grade result smoke: PASS`; Flutter subprocess exit0.
- Extra simulator termination exit3 is consistent with an already-stopped process:
  independently reproduced with an absent diagnostic bundle. It is not the Flutter
  test exit code and does not reopen accepted D3 results. See [evidence](day-8-d3-grade-result.md).
- D1/D2/D3 COMPLETE. Day8 overall remains NOT COMPLETE. Existing iPhone physical
  subset and UI polish PASS retained; iOS Focus details, reboot and Android physical
  DND/notification/restore remain open.
- Short Owner command: `./tool/run_mock_grade_flutter_smoke.sh /path/to/local-config.json`.
  Wrapper reuses a dedicated external venv; `--setup` explicitly creates the stable
  user venv if needed. System Python missing psycopg is an environment issue, not
  an acceptance failure. External pooler-host auto-load and password getpass retained.
- This closeout makes no production request/schema/RPC or Flutter feature change.

## Local verifier configuration — 2026-09-15

- D1 verifier and D2/D3 Flutter runners share `admin_host_from_config` in the existing
  scoring verifier module. Optional external `SUPABASE_SESSION_POOLER_HOST` skips
  only the host prompt; absent key retains interactive host/direct-DB fallback.
  Invalid present values fail closed without printing the value.
- A/B and DB passwords remain getpass-only. No local config edit, credential storage,
  production call, schema/RPC change or D3 acceptance claim. Offline49 tests,
  Python syntax/credential scan/diff checks PASS.
- TODO (separate future scope): evaluate macOS Keychain retrieval for
  TEST_A_PASSWORD, TEST_B_PASSWORD and DB password; not implemented now.

## Day 8-D2 runtime acceptance — COMPLETE

- Owner completed the A/B Flutter scoring runner: `tool/run_mock_scoring_flutter_smoke.py`.
  It uses real native entry/controller/storage and authenticated RPC/read-back;
  [D2 execution details](day-8-d2-answer-scoring.md#a-b-native-flutter-scoring-runner-owner-runtime-pass).
- 9 runner offline safety tests, existing45 JWT offline tests, full228 Flutter tests,
  analyze and iOS simulator integration-target build PASS. Actual A/B Flutter
  scoring runtime now PASS independently of D1 JWT acceptance. Next: Day 8-D3 Grade + Result UX.
- Controlled fixture cleanup retains the approved three-trigger, single-transaction,
  run-UUID-only contract. Owner reports fixture cleanup, trigger restoration, scoring
  baseline restoration, existing data preservation and Auth-user retention PASS.
  This documentation closeout makes no production request or schema change.

## Repository and product baseline

- Working checkout: ~/development/legendstudy-app; branch: codex/day-7-school-neis.
  No push, PR or merge in this closeout. Existing untracked supabase/.temp/ is local
  CLI metadata, excluded from commits. Day 7 completion does not imply a main-branch merge.
- Native Flutter iOS/Android app, Riverpod and go_router; four-tab Home / Materials /
  Study / MY shell. Bundle/application identity: com.legendstudy.app.
- Dedicated LegendStudy Supabase project: stlhijzpjfgwwdgunlsd. Complete separation
  from Muselry across code, database, keys, OAuth, signing and deployment remains mandatory.
- Existing legendstudy.com content is the public source. App repositories consume
  normalized backend content; no WebView wrapper or runtime site scraping.
- Day 6 materials/search/content detail and actual empty-backend reads verified.
  No production content ingestion pipeline yet. Public resource link_status eligibility,
  populated-content/file runtime checks and native PDF viewing remain follow-up work.

## Day 7 accepted scope

| Area | Final status and evidence |
|---|---|
| School selection + NEIS Meals | COMPLETE: search, selection, Home meal data/empty/error handling and guest selection implemented |
| School production storage | 20260913000100_profile_school_selection.sql owner-applied; nullable NEIS identifier pair, CHECK and grants verified; actual JWT/RLS save/select/clear and A/B ownership isolation PASS |
| NEIS server proxy | neis deployed to the dedicated project; NEIS_API_KEY registered server-side only. Deployed search for 진접고등학교 J10/7530932, 2026-09-11 meal 1 row and 2026-09-13 empty PASS |
| Flutter NEIS guest runtime | Search, select, school name and Home meal empty state PASS. No client NEIS key |
| Home refinement | Official 레전드스터디-only wordmark crop, compact school/study action rows, attribution only on school setup; approved D-Day pill + secondary date hierarchy complete |
| D-Day production storage | 20260913000200_profile_day_target.sql owner-applied: nullable date/text pair, validated CHECK, finite dates and label validation; profile count 0→0 and unchanged digest at deployment |
| D-Day JWT/REST | Acceptance PASS: save/select/clear, validation boundaries including past dates, other-field preservation and cross-user RLS denial; fixture cleanup PASS |
| D-Day Flutter persistence | Actual runtime smoke PASS: Home save, container restore, edit, account switch and clear |
| Data safety | Runtime profile/school field preservation PASS; fixture cleanup PASS; Auth users retained |

Authenticated D-Day reads/writes use current-session identity and narrow target-only
payloads; clear PATCH retains the profile. Save failures keep the confirmed state.
Logout/account changes discard prior-user UI state and stale responses. Guests keep
session-memory targets, with no automatic upload on login and no persistence claim.

Runtime restoration was tested by rebuilding the ProviderContainer with a live
session. This does not claim OS process-restart token restoration or OAuth-provider
runtime acceptance. These limits do not reopen the owner-accepted Day 7 scope.
Full runtime markers and test procedure: [D-Day storage](day-7-dday-storage-proposal.md).
School/proxy acceptance: [Day 7 NEIS](day-7-neis.md).

## Day 8-A Study Core

- General stopwatch: start/pause/resume/end; separate execution/save state. No general
  target-duration input, DND/Focus control, mock UI/route, scoring or notifications.
- One native atomic JSON file stores versioned per-owner draft/history/outbox;
  Android elapsedRealtime and iOS mach_continuous_time drive elapsed arithmetic.
  The ticker only refreshes display. Same-boot restore checks clock continuity;
  uncertain/reboot gaps require retaining the last checkpoint or discarding.
- Guest completions persist on this device with `이 기기에 저장됨`; no login required
  and no guest-to-cloud upload. Auth completions use immutable narrow study_sessions
  INSERT and verified read-back; `저장됨` only after acknowledgement. Failed writes
  retain the local record as `동기화 대기` with retry. Old-account state is cleared
  immediately; request identity and async generations protect account boundaries.
- Home and Study share KST interval-union totals, including active local overlay,
  study + mock history, midnight split, pause exclusion and seven zero-filled dates.
  Cloud reads use bounded keyset pagination, 2,000 + sentinel; overflow never presents
  partial totals as complete. Initial history failure is distinct from empty.
- Timer is primary, today total is flat, controls precede compact seven-day text.
  48px targets, tabular figures, textPrimary and narrow/large-text vertical controls.
  Day 7 Home layout, profiles/school/D-Day and database contracts are unchanged.
- Claude review preserved verbatim in [UI review](day-8-study-ui-review.md), with
  Owner-approved overrides appended separately. Current contract: [Study v1](study-v1.md).

## Day 8-A accepted validation

- Flutter analyze PASS; 134 Flutter tests PASS (107 existing retained/adapted plus27
  Study tests), including 360×640/2×, monotonic recovery, 24h/256 guards, guest/auth,
  pending retry, account switch during disk/network work, KST union and pagination.
- Android debug and iOS simulator builds PASS. Android SDK XML-version warning is
  non-fatal; Android physical-device runtime has not been verified.
- iOS simulator guest runtime PASS: start, pause/resume, running-controller restore,
  completed local save, reconstructed state + Home summary and original local-file
  restoration. This proves real native I/O/clock with provider reconstruction, not
  OS process-kill/reboot or physical-device screen-lock acceptance.
- Production Study migration `20260914000100_study_sessions.sql` applied by Owner;
  Postflight PASS and full real A/B Study JWT acceptance PASS.
- Final Owner-run Flutter persistence smoke: **PASS**. Guest start/pause/resume,
  running restore, local completion and Home restore PASS. Auth login, cloud save,
  restored Home aggregate, A/B account isolation and pending sync/retry PASS.
- Profile/name/grade, NEIS school pair and D-Day field preservation PASS; fixture
  cleanup PASS and Auth users retained. These results match
  `integration_test/study_core_smoke_test.dart` and `tool/run_study_flutter_smoke.py`.
  Full safe stage markers are preserved in [Study v1](study-v1.md).
- 18 Study Python verifier/runner offline tests and Python syntax PASS. Credential
  scan and git diff --check PASS at implementation. Existing migrations unchanged.
  This closeout edits documentation only and verifies its diff; no test rerun,
  production request, Flutter change or Auth-user change.
- Owner accepts **Day 8-A = COMPLETE**. Physical Android/iOS lock, process-kill,
  reboot and OS process-restart Auth restoration remain platform follow-up checks;
  the smoke proves provider reconstruction, not those untested lifecycle cases.

## Day 8-B Focus / DND — implemented, NOT COMPLETE

- Android compile/target35: API29+ owned AutomaticZenRule + policy access; API21–28
  manual guidance. No global DND/filter/policy writes. Only app-recorded activation
  is released at end/recovery/account change; pause/resume/background preserve it.
- Device preference ask/always/disabled, once not persisted. First Android choices:
  항상 사용 / 이번만 / 사용하지 않음. Small 집중 설정 action; permission-denial retries
  do not repeatedly force system settings. Timer commits before settings handoff;
  exceptions, denial, unavailable APIs and missing settings never block Study start.
- iOS optional manual Focus guide; no automatic activation claim/private settings
  URL. Focus preferences are local and excluded from OS backup/transfer as applicable.
  No cloud profile/Study fields, notification content access or telemetry added.
- Analyze PASS;156 Flutter tests PASS including134 prior tests and22 Focus tests.
  Android JVM lease tests2 PASS; Android debug/iOS simulator builds PASS.
  iOS native guide/skip/start, no automatic activation, preference restore and local
  cleanup PASS. Existing Day 8-A Guest native flow/Home/restore/cleanup rerun PASS.
  These are simulator/logic results, not physical DND acceptance.
- No Android device/emulator available. Physical Android choices/permission/actual
  DND/user-state preservation/revocation and iPhone guidance are pending. Process kill
  can leave our rule until app re-entry; a24h lease deadline is checked on execution,
  not enforced by an OS alarm. Physical restart/override/backup checks remain open.
- **Day 8-B is not COMPLETE.** Next: physical-device Focus acceptance and lifecycle
  hardening if needed. 8-C now reuses FocusService for the mock timer; notification implementation is
  present. Scoring remains out of scope. Day8 overall is not COMPLETE.
- Official API references and full behavior/evidence: [Study v1](study-v1.md).

## Day 8-C Mock Exam — implementation complete / physical-device acceptance pending

- Compact study/mock switch, one active timer; title/optional subject, four presets
  and custom1–720 minutes. Separate MockPhase over shared clock/interval infrastructure.
- Countdown is monotonic active time; pause excluded, background/lock not an implicit
  pause. TimeUp freezes exact logical end, releases owned Focus on execution and
  awaits explicit confirmation. Early-submit dialog continues running time.
- Local envelope v2 preserves v1 general drafts/history/outbox; frozen mock restore
  needs no clock extrapolation. Unknown continuity uses checkpoint recovery. Account
  changes hide old state and freeze old-owner mock without automatically uploading.
- Guest local/auth immutable narrow INSERT and existing retry; generated duration,
  profile/school/D-Day fields and production schema/migrations unchanged. KST Home/
  seven-day totals include mock intervals once, including frozen local overlay.
- Optional native local notification: Android inexact AlarmManager + ordinary
  notification permission, iOS UserNotifications. No new dependency, exact-alarm
  permission, server push or DND bypass. Denial/failure never blocks the timer.
- Analyze PASS;177 Flutter tests PASS (156 prior +21 mock), including small/large-text
  UI, expiry/dialog races, recovery, owner isolation, pending/retry, Focus/notification.
  Python smoke runner2 offline tests and syntax PASS. Final build results recorded
  in the implementation section of [Mock contract](day-8-mock-exam.md).
- Actual iOS simulator Guest PASS: setup/start, pause/resume, running restore, real
  one-minute timeUp, frozen restore before confirmation, local completion, Home
  aggregate and original local snapshot restoration. No production writes in that run.
- Owner reports full actual Mock Flutter persistence smoke PASS: Guest and Auth,
  cloud save/restore, account isolation, pending sync/retry and Home aggregate PASS.
  Profile/school/D-Day preservation, fixture cleanup and Auth users retained PASS.
  Full safe stage markers are recorded in [Mock contract](day-8-mock-exam.md).
  This verifies simulator/provider restoration, not physical kill/reboot acceptance.
- Android/iPhone physical background/lock/notification/Focus/kill/reboot remain pending.
  Inexact notifications can be delayed; rule cleanup after process kill is not guaranteed.
  Day8-C NOT COMPLETE; Day8 overall NOT COMPLETE. D2 scoring acceptance is recorded below.
- Next: complete physical-device gates. Day 8-C final COMPLETE remains on hold;
  Day 8-D1/D2 are complete below; Day 8-D3 Grade + Result UX is the next scope. No DB/schema changes, Push, PR or Merge.

## Day 8-D1 Scoring Storage / Validation Contract — COMPLETE

- Owner approved MCQ-first, confirmed/estimated/unavailable labels, and independent
  Study/result deletion. Unsupported papers stay timer-only; no partial-score scaling.
- [Full executable package](day-8-scoring-migration-package.md) and
  [final storage contract](day-8-scoring-storage-proposal.md) prepared. New migration:
  `20260914000200_mock_exam_scoring.sql`; four existing migrations unchanged.
- Five tables, independent key/cutoff versions, 12 functions, server-recomputed immutable
  results/answers, owner RLS and security-invoker availability projection. Study deletion
  SET NULLs only the optional link; attempt/answers survive. Attempt deletion is separate.
- Preflight/Postflight/guarded rollback are full SQL blocks. Local PostgreSQL17.5
  synthetic validation and static checks PASS. Those earlier local checks are distinct
  from the subsequent Owner-run production acceptance recorded below.
- Pre-production review correction: NEW attempts require current published key and
  optional compatible current cutoff; identical historical retries retain old versions.
  Migration/package/proposal/acceptance synchronized. 21 PostgreSQL local groups,
  37 vectors and seven native PostgreSQL17.6 concurrency groups PASS.
- D1 shared synthetic scoring vectors now pass the D2 Dart parity suite. Real source
  ingestion/publication is not performed; D2 runtime scope is recorded below.
- Owner reports production migration/Postflight PASS: five scoring RLS tables, six
  policies, 12 functions, seven triggers, constraints/indexes/grants/view and synthetic
  engine PASS; scoring rows=0 and prior public row-count/digest baseline preserved.
- Owner reports full actual A/B JWT/RPC acceptance PASS: server-side scoring,
  direct score/grade forgery denied, own snapshots, owner isolation, idempotent retry,
  current version switch, stale key/cutoff rejection and invalid input rejection PASS.
- Study deletion retains attempt/answers and clears only the link; owner attempt
  deletion cascades answers: PASS. Fixture scope/cleanup, three cleanup triggers
  restored, scoring baseline restored, existing data preserved and Auth users retained:
  PASS. [Full runtime evidence](day-8-scoring-jwt-acceptance.md).
- **Day 8-D1 = COMPLETE. Next: Day 8-D2 Flutter Answer Entry + Raw Score.**
  The D1 runtime evidence was supplied by the Owner; the subsequent D2 implementation
  and its distinct runtime gate are recorded below.
- Day8-D NOT COMPLETE. Day8-B/8-C physical background/lock/Focus/notification/kill/reboot
  gates remain pending. No Push, PR or Merge.

## Day 8-D2 Answer Entry + Raw Score — COMPLETE

- Typed availability/questions and existing timer-only fallback; no fake bundled paper.
  Root answer page, five-choice marking/groups/grid, pause/timeUp lock and explicit
  submission. Running state never contains correct answers. Raw score/review is post-submit.
- Native v3 atomic draft + Study/scoring outbox retains answers, fixed attempt ID and
  owner isolation. Guest local pure Dart scoring; Auth exact RPC + verified read-back.
  Failures preserve pending work, stale criteria require explicit recovery, no auto-upload.
- 228 Flutter tests PASS; 37/37 shared vectors PASS; Android debug/iOS simulator builds
  PASS. iOS test-only Guest native answer/restore/submit/result and local cleanup PASS.
  Actual public availability-empty Flutter read PASS; no production fixture created.
  Analyze/diff checks PASS. [Implementation and evidence](day-8-d2-answer-scoring.md).
- Owner reports actual A/B Flutter runtime PASS: answer entry, pause/resume, draft
  restore, server RPC scoring/raw result, server-confirmed result restore, account
  isolation, same-ID retry/idempotency and stale-version handling.
- Pause/timeUp mutation policy PASS: runtime pause coverage plus existing automated
  timeUp lock tests. Local/production fixture scope and cleanup, trigger restoration,
  scoring baseline restoration, existing data preservation and Auth retention PASS.
- **Day 8-D2 = COMPLETE. Next: Day 8-D3 Grade + Result UX.** D3 implementation is not
  started by this closeout. Day8 overall is NOT COMPLETE; 8-B/8-C physical gates remain pending.

## Day 9-B Ingestion — pipeline + dry-run COMPLETE, production write NOT approved

- legendstudy.com surveyed 2026-09-15: sitemap lists **1,673 numeric posts**
  (id 2–1709, id 1520 is 404). 227 posts in the modern range 1481–1709 were read
  in full; 81 of them are exam posts carrying 2,620 Tistory attachments, 134 are
  논술, 4 are columns with no attachment. All attachment extensions are `pdf`.
- Two attachment generations, with a sharp boundary near id 1481/1475.
  **Modern `blog.kakaocdn.net` locators require a site-wide rolling signature
  (`expires` 2026-10-01 00:00 KST) — the unsigned path and an expired signature
  both fail.** Legacy `t1.daumcdn.net/cfile/tistory/{ID}` locators are unsigned
  and stable. The signed query is never stored; the stable Tistory file identity
  (`kage@{s1}/{s2}`) is used as `source_resource_key`.
- Pipeline implemented under `tool/ingestion/` with CLI `tool/ingest_legendstudy.py`
  (dry-run by default; `--apply` always refuses and names the LegendStudy project
  ref before anything else). Standard library only, no new dependency.
- Offline dry-run over 38 real exam posts / 1,205 real attachments:
  38 content_items, 38 exams, 609 exam_subjects, 1,205 resources,
  **0 parse errors, 0 blocking quarantine, 35/38 publish candidates**, and
  **zero violations** against the applied initial content schema. Re-running
  against the state file gives `changed=0, unchanged=38` and a byte-identical
  posts CSV. The only three failures are typos on the source site.
- Title-parsing coverage over all 227 modern posts: **81/81 exam-category posts
  yield a complete exam identity** (year, month, grade, type).
- `national_mock` never takes the source `N학년도` label — the site writes the
  calendar year there. `academic_year` is trusted only for 수능/모의평가.
- **No production write, migration, schema change, push, PR or merge.**
  `Production pilot 적용 준비: NO` — pending one Owner decision on how modern
  attachments are opened. See [day-9-ingestion.md](day-9-ingestion.md).
- Owner-reported Mac network smoke PASS: sitemap 1,673 ids and newest posts
  1709–1705 all parsed (5/5, 6 requests, 0 retries, 0 failures).

## Day 9-B2 Taxonomy + Pilot package — prepared, NOT applied

- Owner decisions recorded: modern attachment access option **(a)** (searchable
  metadata in production; the original legendstudy.com post is the read path,
  opened externally, WebView still forbidden, no Storage mirror); Production
  Pilot **C** (2025–2026, all grades) approved; `subjects` seeded before the
  pilot; the ~1,400 legacy posts deferred.
- Canonical subject taxonomy **v1 = 23 subjects**, not 36. 국어/수학 선택과목 are
  paper variants under their 영역; the nine 사탐 and eight 과탐 details stay
  distinct; 사회/과학/사회탐구/과학탐구 are grade-1 spellings of 통합사회/통합과학.
  Deterministic ids `uuid5(ns, "v1:<code>")`, `taxonomy_version='v1'`,
  `curriculum_version` NULL, `parent_id` NULL, grouping by public `category`.
  **No schema change and no migration** — one data seed.
- Pilot C mapping: **363 / 363 occurrences provisional, 0 unmapped, 0 ambiguous**
  (160 exact, 203 documented alias). All 23 subjects used. `verified` is never
  produced by automated ingestion.
- Owner live evidence confirms one Box link per Pilot C post. All 23 are English
  listening landing pages and normalize as `listening_audio` on the existing
  English occurrence. Expected rows: subjects +23, source_posts +23,
  content_items +23, exams +23, exam_subjects +363, resources +739
  (360 question, 356 answer/explanation, 23 listening audio), quarantine +23
  (`resource_url_expiring` for kakaocdn only; advisory).
- Apply package prepared: preflight / network smoke / live dry-run / seed /
  apply / postflight / publication / rollback. Guards implemented and tested;
  `--apply` still refuses every argument combination.
- `Production pilot 적용 준비:` **package YES, execution NO.** Package steps 1–4
  are Owner-executable; the ingestion writer has no write path yet.
- Publication precondition: 9-C must route `link_kind='unknown'` resources to
  the content item's `source_url`. `content_items.source_url`, `link_kind` and
  `LaunchMode.externalApplication` already exist, so no schema, projection or
  repository change is needed — only the open-target rule.
- Pilot C live dry-run now selects its authoritative 23 post ids before fetching,
  instead of crawling all 1,673 sitemap ids and filtering afterwards. Sitemap and
  per-post fetch/done/retry diagnostics flush immediately; each request remains
  serial with a 20s timeout, two retries and the 1.5s polite interval. The bounded
  72-request budget includes all allowed retries; an incomplete pilot fails closed.
- 106 offline tests PASS. No production write, migration, schema change,
  Supabase call, push, PR or merge.
  See [day-9-subjects-taxonomy.md](day-9-subjects-taxonomy.md) and
  [day-9-pilot-c-package.md](day-9-pilot-c-package.md).

## Day 9-B3 Pilot C Production ingestion — **COMPLETE**. Publication NOT done.

Owner applied Pilot C to the LegendStudy production project. Real content now
exists in production for the first time, and all of it is inactive.

Apply output — every table hit its expected count exactly:

| table | inserted |
|---|---|
| source_posts | 23 / 23 |
| content_items | 23 / 23 |
| exams | 23 / 23 |
| exam_subjects | 363 / 363 |
| resources | 739 / 739 |

Canonical transaction COMMIT, then the quarantine transaction COMMIT (23 rows).

Owner manual postflight, verified in the Supabase SQL editor:

- counts: subjects 23, source_posts 23, content_items 23, exams 23,
  exam_subjects 363, resources 739, ingestion_quarantine 23
- **active_content_items 0, active_exam_subjects 0, active_resources 0**
- mapping: provisional 363, verified 0; canonical subjects 23, occurrences 363,
  confidence 1.00 × 160, confidence 0.95 × 203
- resources: question 360, answer_explanation 356, listening_audio 23
- links: signed_url_rows **0**, unknown 716, landing_page 23,
  unknown_without_file_url 716
- integrity: duplicate source_posts / slugs / exam_subjects / resources all 0;
  orphan exam_subjects 0, orphan resources 0
- anon role RLS: public_content_items 0, public_exams 0, public_exam_subjects 0,
  public_resources 0, public_subjects 23

So the applied rows are invisible to the public client, exactly as intended.

Known issue, already fixed: immediately after COMMIT the **CLI postflight**
raised `ProgrammingError: only '%s', '%b', '%t' are allowed as placeholders,
got '%c'`. The cause was a read-only query only — a literal `'%credential=%'`
LIKE pattern inside a parameterised statement, which psycopg parsed as the
placeholder `%c`. No write path was involved, nothing was re-applied, and the
Owner's manual postflight above is the authoritative verification. The query is
now parameterised and the adapter passes `None` for parameterless statements;
141 offline tests cover it.

**PUBLICATION HAS NOT HAPPENED.** Every content row is `is_active=false` and
stays that way until (a) 9-C routes `link_kind='unknown'` resources to the
content item's `source_url`, and (b) the Owner approves the activation step
separately. Ingestion success is not publication.

## Day 9-C1 Resource Detail + Safe Open Target — IMPLEMENTED

- Existing search → detail navigation now renders resources by occurrence/subject
  using the existing bounded `content_item_id` resource query. Canonical subject
  names remain preferred, with raw-label fallback.
- Open targets are deterministic: `unknown` uses the parent `ContentItem.sourceUrl`,
  `landing_page` uses the resource URL, and `file` uses only a valid `file_url`.
  Unsafe or missing targets do not launch. External opening remains native
  `LaunchMode.externalApplication` with a safe failure message.
- Resource labels include `문제`, `정답·해설`, and `영어 듣기`; unknown resources
  show the short original-page guidance. No bookmark/recent/MY change.
- Relevant 32 tests and `flutter analyze` pass. Android/iOS build validation and
  full regression are tracked separately in this closeout. No DB, Production,
  publication, ingestion, or schema change.
- **Day 9-C1 was implemented at its checkpoint.** C2 owns bookmark/recent views;
  the current C3 closeout below is authoritative for the full Day 9-C status.

## Day 9-C2 Bookmark + Recent Views — IMPLEMENTED

- Content detail now uses the existing auth-derived personal repositories and a
  keyed bookmark controller. Authenticated users can save/unsave the parent
  `content_items.id`; the control distinguishes loading, saved, unsaved,
  mutation and failure, blocks rapid duplicate taps, and rolls back failed
  mutations with a concise Korean message.
- Guests see a login-required explanation and perform no personal cloud write.
  Auth changes rebuild the keyed state so account A's bookmark cannot remain
  visible for account B or after logout.
- A resolved detail entry touches `recent_views` once per page lifecycle using
  `content_items.id`; rebuild/provider changes do not repeat it, while a fresh
  detail entry does. Missing/failed detail does not touch; recent-write failure
  never hides content. Existing repository server timestamp/auth contracts are
  unchanged.
- Added focused C2 tests for bookmark mutation/race/guest/A-B behavior and
  recent lifecycle/rebuild/failure/re-entry behavior. No DB/schema/RLS/RPC,
  production mutation, publication, C3 list screen, or MY redesign.
- **Day 9-C2 was implemented at its checkpoint.** C3 below completes the
  Saved/Recent UI integration and is authoritative for the full Day 9-C status.

## Day 9-C3 Saved / Recent UI + MY Integration — COMPLETE

- `/my/saved` and `/my/recent` now use authenticated personal repositories with
  loading, empty, error/retry and guest-login states. Existing routes and MY
  navigation are preserved; cards open the existing content detail route.
- Personal rows hydrate through the explicit public `content_items` projection
  using one bounded `id IN (...)` batch query (up to 100 IDs), restoring the
  repository's server order. Missing/inactive/deleted content is omitted and
  never fetched through a private or inactive path.
- Returning from detail invalidates the relevant list, so bookmark changes and
  recent server timestamp updates appear on re-entry without global state.
  Home's existing recent placeholder now uses the same small recent-list widget;
  no Home redesign or Meal Card v2 was made.
- C3 focused tests cover saved/recent ordering and batch hydration, guest no
  request, inactive/missing exclusion, 360×640/2× long-title layout and retry;
  existing C1/C2 and navigation regressions remain passing.
- Publication readiness checklist A–Q is PASS for the scoped gate, so
  **PUBLICATION READY = YES**. This is not publication: all Pilot C content
  remains inactive, no production mutation was performed, and publication still
  requires the separate Owner activation decision. Official iOS15/Xcode27
  compatibility is now configured in-repository and default simulator validation
  passes.
- **Day 9-C1/C2/C3 are complete. Day 9-C is COMPLETE.** Next: Owner review and
  explicit publication decision, or separate release-toolchain work.

## Auth recovery foundation — implemented, production config pending

- Login now offers "비밀번호를 잊으셨나요?"; `/auth/recovery` requests a reset and
  `/auth/new-password` sets one, both reusing the existing shell widgets and tokens.
- `resetPasswordForEmail` / `updateUser` sit behind an `AuthRecoveryService` seam,
  so widget tests use an in-memory double and cannot reach the network.
- `AuthStatus` now carries the `AuthChangeEvent`; the router routes only a
  `passwordRecovery` event to the new-password screen, never an ordinary sign-in.
  The recovery token is never read, logged or routed.
- Centralized Korean error mapping: the reported `Invalid login credentials` now
  renders as "이메일 또는 비밀번호가 올바르지 않습니다."; unknown errors use a safe
  fallback and no raw SDK text, token or URL is shown.
- Success copy does not disclose whether an address is registered.
- **No production mutation**: no Supabase dashboard change, no redirect URL
  registered, no recovery email sent. `SUPABASE_RECOVERY_REDIRECT` is empty, so no
  recovery URI was invented.
- `flutter analyze` / `flutter test` could not run in the session environment
  (no Flutter SDK reachable); the Owner must run them. See
  [auth-recovery.md](auth-recovery.md) for the pending list.

## Long-term backlog — preserved for later planning

- Admissions Engine / 수시 합격예측.
- University-specific official calculation rule engine.
- Admissions result collection and normalization.
- legendstudy.com official service-page maintenance.
- Privacy / Terms / Support / Account deletion service pages and flows.
- Consider a future admissions-prediction web service.

These are future planning items, not implemented or approved production deployments.

## Other release / product follow-up

- Official orange memo/document + pencil symbol remains the launcher design basis;
  high-resolution source production/restoration and launcher replacement are pending.
  The legacy 72×72 favicon is not the launcher canonical source.
- Apple/Google registration, signing, physical-device/release distribution, normal
  OAuth-provider runtime, AdMob/IAP and store/service policy work remain separate.
- Assess NEIS quota and deployment-wide abuse/rate controls before public release.
  Day 7 COMPLETE is a development milestone, not general release readiness.
- No credentials committed. Existing source attribution on school setup, system
  body typography, public browsing and optional-login principles remain in force.
