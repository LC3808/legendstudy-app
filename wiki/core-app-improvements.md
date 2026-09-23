# Core App improvements — 2026-09-20

## App native/shared-account follow-up — 2026-09-21

Google now uses the native SDK on Android/iOS; iOS Apple uses native ID-token
exchange; Kakao and Android Apple retain browser OAuth. Official-source local
marks, common social-button geometry and LegendStudy Account copy replace the
text-only fallback. Direct login returns Home; protected return stays intact.
Google flag additionally requires public client config; missing iOS scheme fails
safely before SDK launch. Native credentials never enter UI state or logs.

Owner reports LAB Web Email/verification/recovery/Google/Kakao/Apple/session E2E
PASS on 2026-09-21. That supersedes earlier LAB-unverified context only for those
reported Web flows, not App native or shared identity. Same account does not mean
shared session. Opt-in debug-only GET comparison checks SDK/server/expected owner
without displaying/storing IDs. Profile/release never exposes the checker.

[Native setup and Owner E2E checklist](auth-native-owner-acceptance.md) is the
operational reference. Preserve working LAB config. Apple revoke/secret renewal
and Google exposed-secret rotation remain OPEN. App Email login and Profile session
restore are PASS; Google/Kakao/Apple App login and cross-platform identity remain
NOT VERIFIED. Current provider
button labels/typography still need brand review; no store approval is claimed.


## Product definition clarification — 2026-09-20

Current essay-oriented LAB entry copy below describes actual app behavior, not
LAB's full product identity. [Product architecture](product-architecture.md)
defines LAB as multi-service Web Intelligence / Deep Work; Essay is one module.
Copy/authenticated IA alignment is a future task; no app code changed here.


## Account lifecycle follow-up — 2026-09-20

Existing Auth reused: configurable signup verification return, safe duplicate
account copy, email-forgotten support/back navigation, fail-closed policy links,
expired initial-session guard and owner-safe password completion. Detailed
code/config/E2E/Owner matrix: [Auth lifecycle](auth-recovery.md#account-lifecycle-completion-review--2026-09-20).
Email/recovery code readiness is distinct from Production acceptance. Google,
Apple and Kakao remain explicit flag-controlled; Apple revoke and deletion gates
remain HOLD. LAB is identity-compatible by design, not verified shared login.
No Production mutation, new identity database or Materials feature change.

## Scope and evidence

Materials is an independent free core product: search → discover → external
problem/answer/explanation/audio access → bookmark → find again. Core release
quality precedes Analytics, monetization and expanded Exam Engine work.
Historical Phase 1-A2 evidence and publication gates are unchanged.

CODE IMPLEMENTED below is separate from TEST PASS and OWNER ACTION REQUIRED.
This task performed no Production E2E, Supabase access, mutation or deployment.

## Implemented

- Materials has separate 시행 월 / 시험 종류 chips; existing AND query semantics
  are unchanged. No-results actions clear query, selected conditions or both.
- Resource sections keep distinct occurrence IDs, even for equal subject names.
  At more than eight resources, sections start collapsed; otherwise expanded.
  Type summaries distinguish 문제/정답/해설/듣기. Source attribution is retained.
- CTA follows actual destination: file → type-specific 보기; landing page →
  type-specific 자료 페이지 보기; unknown → 원문에서 보기 with parent-source fallback.
  Explanations describe external access, never availability or rights guarantees.
  The later delivery increment below centralizes fallback decisions; no viewer,
  download or mirror was added.
- Guest bookmark pushes login, then successful sign-in returns to original
  detail. It does not auto-save; user taps save after returning. The visible
  auth route owns return navigation (GoRouter push retains the branch URI).
  Saved/recent empty states provide login or Materials navigation; saved items
  are explicitly bookmarks, not downloaded files.
- Inline search-row bookmark HOLD is resolved: list/detail now share owner-scoped
  optimistic state with rollback and bounded membership batches. See the
  [personal-state increment](day-9-c-personal-state.md#materials-inline-bookmark--2026-09-20).
- MY grade page supports existing 고1/고2/고3, load/save/retry and stale account
  response guards. Existing repository/RLS path is reused; sparse upsert omits
  absent name/grade, preventing login or grade-only updates from erasing fields.
  Checked migration contracts locally; deployed RLS was not re-verified here.
- MY exposes school, grade, account, support and app/policy sections. The fake
  upcoming donation price card is removed. App version/build comes from Android
  package metadata / iOS Bundle via a small MethodChannel; no new dependency.
- Policy entry seams use PRIVACY_POLICY_URL and TERMS_URL compile-time config.
  Missing/invalid URLs show a preparation/support message; no URL is invented.
- GOOGLE_OAUTH_ENABLED, APPLE_OAUTH_ENABLED, KAKAO_OAUTH_ENABLED default false.
  Buttons appear only for explicitly enabled providers. These are Owner release
  declarations, not discovery or proof of Production provider readiness.
- Recovery service and routing contracts are preserved; account UX refinements
  and current validation are recorded below.
- After confirmed server deletion, local study cleanup and local sign-out are
  tracked separately. A failure says the account is already deleted; retry only
  retries unfinished local steps and never resends server deletion. Cleanup is
  scoped to deleted owner; another signed-in owner is not logged out.
  The completion state is page-local, not a durable restart cleanup queue.
  Edge Function deployment and enable flag are unchanged.

## Validation

- Flutter 3.47 toolchain: full suite 423 PASS, 1 existing skip; focused Core
  render suite 8 PASS; search render suite 29 PASS. Analyze PASS; Android debug
  and iOS simulator builds PASS. Existing toolchain deprecation warnings remain.
- New coverage: independent filters/no-results actions; guest login return with
  no auto-save; grade preservation and failure retry; policy/version/config;
  deletion local-write/sign-out failures with one server call and owner isolation.
- 360×640 resource collapsed/expanded long-title layouts rendered at 1× and 2×,
  reviewed using app theme and Korean/Material icon fonts. They scroll and wrap;
  search layouts also cover 360×640 / 428×926 at 1×/2×, loading/error/empty
  and simulated keyboard insets (not an OS keyboard screenshot). These are
  widget renders, not physical iPhone acceptance for this change.
- Existing route/search/bookmark/profile/recovery/Study/scoring regressions pass.

## Owner release actions

1. Supply real published privacy/terms URLs through existing local build config
   (`--dart-define-from-file`), then verify both links on devices. Do not put
   private credentials in repository files.
2. Validate each OAuth provider and redirect/cold-start flow before setting its
   corresponding boolean true. A configured client flag is not Production E2E.
3. Complete recovery real email / redirect / cold-start checks and account
   deletion deployment, enablement, provider revocation/policy decisions.
4. Validate grade persistence, bookmark/login return and real external resource
   opening on iPhone/Android; verify About version/build on each platform.
5. Release remains NOT READY until these gates close. Prior accepted Study/iPhone
   results are preserved, not reset by this task.

## Deferred integrations

Daily Sync minimum contract is in [ingestion.md](ingestion.md#daily-sync-minimum-contract--2026-09-20).
No scheduler or Production automation was implemented.
The supplied Production LAB URL now has small Home/MY external entries; see
[LAB production entry](#legendstudy-lab-production-entry--2026-09-20). No web edits,
shared auth, token handoff, payment or result sync is implemented.


## Core Account/Auth UX — 2026-09-20

### Audit and implementation

Starting repository state: `ed191d8`, `codex/day-7-school-neis`, tracked clean.
Existing email auth, OAuth seam/flags, recovery, Guest return, grade settings,
policy config and deletion server/local split were reused. The prior form lacked
password confirmation, field validation, visibility and autofill; logout had no
busy/error handling. No native identifiers, brand assets, backend contracts,
dependencies or Production settings changed.

- Email login/signup now have distinct modes, email validation, password
  visibility, autofill and next/done keyboard actions. Signup requests only
  email/password/confirmation, minimum 8 characters consistent with recovery;
  login does not reject existing shorter passwords. Server policy remains final.
  No-session signup shows a neutral request/conditional email-verification notice.
- `auth_email.dart` isolates existing SDK calls for tests; session material stays
  inside the SDK. Missing session, invalid credentials, existing email, weak
  password, transport and unexpected errors are mapped to safe Korean copy.
  The UI never displays raw SDK/provider configuration text.
- Email/signup/recovery/update and OAuth launch retain busy guards. An OAuth
  browser opening is not login success; only the signed-in auth event returns
  to the visible originating route. Cancellation is gentle and permits retry;
  refresh/update/recovery events do not trigger the ordinary login return.
  Guest detail → login → detail still requires an explicit second save tap.
- Google/Apple/Kakao flags default false, hide unavailable buttons and are
  rechecked when tapped. These flags declare intended availability; they do not
  inspect the console. Callback route and both native deep-link registrations
  are code-tested. Cold/warm real provider callbacks and actual session creation
  still require Owner acceptance; unit events are not external E2E evidence.
- Social buttons have consistent text-only fallback styling and no invented
  provider logos. **Official provider button artwork/design review HOLD** before
  release enablement; functional code readiness does not imply branding approval.
  References reviewed: [Google](https://developers.google.com/identity/branding-guidelines),
  [Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple),
  [Kakao](https://developers.kakao.com/docs/en/kakaologin/common).
- Recovery request says “입력한 이메일로 비밀번호 재설정 안내를 요청했습니다.”
  without asserting delivery or account existence. New-password visibility and
  autofill improved; expired/reused/malformed link and missing-session safe paths
  remain. No real email or password change was performed.
- MY groups account/email, school/grade, saved/recent, support/policies and account
  management. Email is shown only for the matching SDK owner. Existing dynamic
  version/build and internal feedback route remain; no contact/LS LAB URL invented.
- Logout is immediate local-device sign-out with clear scope, a duplicate-call
  guard and retryable safe error. No destructive-data confirmation is needed.
  Tests cover A → Guest → B for both saved/recent lists; existing owner-keyed
  Study/profile guards and sparse name/grade/school writes are retained.
- Disabled deletion now shows explanatory copy and an active feedback route,
  not an inert destructive CTA. Enabled deletion still has two confirmations;
  back navigation is blocked while the operation is in flight. Confirmed server
  deletion is never resent by local cleanup retry. Page-local completion is not
  a durable restart cleanup queue. This fallback is **not** store-ready deletion.
- Policies remain centralized in `PRIVACY_POLICY_URL` / `TERMS_URL`: code paths
  ready, default actual URLs absent, explicit preparation/support state. Real
  URLs and device-open acceptance remain Owner actions; no placeholder page.

### Validation and limits

- Full Flutter suite **446 PASS / 1 existing skip** (prior 427); account/render/
  deletion focused suite **35 PASS**; analyze **PASS**, Android debug **PASS**,
  iOS simulator build **PASS**. Existing native toolchain warnings only.
- 360×640 at 2×: login, signup/errors, enabled social buttons, recovery/link
  failure, new password and MY long email rendered and visually inspected.
  Keyboard inset 260px with scroll-to-CTA assertions for all four forms; no
  overflow/clipped CTA. Shortened signup return copy after visual review.
- Pixel 5/API36 actual Home → login and real OS keyboard rendering PASS;
  iPhone 16 Pro/iOS18.6 install/launch/Home render PASS. iOS interactive auth
  navigation was not exercised (computer-use tool could not select Simulator).
  Widget renders are not physical-device or Production authentication evidence.
- Render evidence (local, not committed): `/private/tmp/legendstudy-core-ui/account-*.png`,
  `/private/tmp/legendstudy-auth-android-login.png`,
  `/private/tmp/legendstudy-auth-android-keyboard.png`,
  `/private/tmp/legendstudy-auth-ios-home.png`. Tests can regenerate widget images
  with `--dart-define=CORE_RENDER=true test/account_ux_render_test.dart` on macOS.
- Materials search/filter/detail/external-launch seams, bookmark/return,
  saved/recent and grade preservation are covered by the passing full suite.
  No real Production material/account mutation or external sign-in was run.
- Credential-pattern and added logging scans, brand/native/dependency unchanged
  check and `git diff --check` PASS. Production mutation **0**, no push.

### Release readiness (code / test / external gates are separate)

| Area | Code | Local Test | Production E2E | Owner Action | Release Blocker |
|---|---|---|---|---|---|
| Email login | IMPLEMENTED | PASS | Existing A/B history; revised journey pending | Device/account acceptance | Yes, acceptance |
| Sign-up | IMPLEMENTED | PASS | Not verified | Mail/confirmation/policy acceptance | Yes |
| Google OAuth | Functional code ready; official design HOLD | PASS | Not verified | Official button, console/flag, device callback | If enabled |
| Apple OAuth | Functional code ready; official design HOLD | PASS | Not verified | Official button, console/flag, callback/revocation | If enabled / launch policy decision |
| Kakao OAuth | Functional code ready; official design HOLD | PASS | Not verified | Official button, console/flag, device callback | If enabled |
| Password recovery | IMPLEMENTED | PASS | Not verified | Real mailbox/redirect, cold/warm/expired link | Yes |
| Grade setting | IMPLEMENTED, preserved | PASS | Revised journey pending | Persistence/account acceptance | Acceptance gate |
| Privacy Policy | CODE PATH READY | PASS | Actual URL not supplied in repo defaults | Publish/configure/open real URL | Yes |
| Terms | CODE PATH READY | PASS | Actual URL not supplied in repo defaults | Publish/configure/open real URL | Yes |
| Account deletion | Client + server candidate; provider lifecycle gap | PASS (client regression) | Not verified; no deploy in this task | Deploy/flag, E2E, web request URL, retention/revocation | Yes |
| Materials guest journey | IMPLEMENTED, preserved | PASS | Prior public-read evidence retained; full revised device journey pending | External access/return acceptance | Acceptance gate |
| App identity/icon | COMPLETE, unchanged | Prior native render + regression PASS | N/A (local identity) | Prior Owner visual review | No new blocker |

Deletion gates: CODE READY (foundation) YES; DEPLOYED remains last documented
NO, not remotely queried here; CONFIG ENABLED default NO; PRODUCTION E2E VERIFIED
NO. Apple token revocation and feedback retention decisions remain unresolved.
Policy gates: CODE PATH READY YES; ACTUAL URL CONFIGURED not verified/default NO;
OWNER ACTION REQUIRED YES. No local config contents were inspected or printed.

**Core forms/account UI IMPLEMENTED and locally TESTED. Full AUTH UX COMPLETE NO**
while official social button design is on HOLD. **RELEASE READY NO** until Owner
release gates close. No previous Study/iPhone or D3 runtime result is downgraded.

Next candidates only, no implementation: (1) Production Auth/Account/policy Owner
acceptance, (2) Release QA/store preparation after those gates, (3) Materials
external delivery improvements after rights review, (4) Daily Sync against the
existing ingestion contract. The formerly deferred LAB external entry is now
implemented below; deeper integration remains deferred with Analytics/BM.


## Materials delivery increment — 2026-09-20

Materials remains an independent free core product. Starting state `85e3c27`,
tracked clean; no Auth/Study/brand/ingestion/backend changes in this increment.

- Existing URI-only logic and independent CTA copy are replaced by one typed
  delivery action: explicit file / landing page / parent source / unavailable.
  Missing, invalid or uncertain direct targets now have safe original fallback.
  No suffix-only file inference, official-source guess or rights promotion.
- Direct/landing cards retain purpose CTAs, show host only and offer original
  fallback even after a successful OS launch. Errors stay local to their action.
- Existing occurrence grouping/collapse and search/filter/pagination state kept;
  filter/detail/external actions dismiss keyboard. Return needs no repeat search.
- Public API cannot guarantee health, expiry or hidden auth requirements.
  Query-bearing files conservatively use original source, including benign
  queries. No HTTP availability claim, network file probe or auth bypass.
- Recent intent/dwell semantics clarified. The subsequent inline bookmark
  increment resolves N+1 with ID-filtered batches, not the bounded saved list.
- [Canonical delivery audit/contract](day-9-c-resource-detail.md) separates public
  fields, internal health metadata, rights, navigation and future sync boundaries.
  Existing Auth/policy/deletion release gates above are unchanged.

Validation: full **472 PASS / 1 existing skip**, focused **64 + 2 PASS**, iOS
simulator offline journey **2 PASS** (1×/2×), analyze and Android debug/iOS simulator
builds PASS. Actual renders reviewed; external opener/lifecycle are test doubles,
not website/file or real browser-return E2E. Native keyboard/safe-area scroll
adjustment is bounded and the selected row remains visible. Owner real-device
external destination acceptance remains; RELEASE READY NO. Mutation 0, no push.


## LegendStudy LAB production entry — 2026-09-20

- Public canonical URL: `https://lab.legendstudy.com/` in
  `lib/core/links/service_links.dart`; exact HTTPS root validation rejects other
  hosts, paths, query/fragment and credential-bearing entries. No dynamic URL,
  auth token, profile or tracking parameters are appended.
- `LegendStudyLabEntry` reuses `CompactUtilityCard` and `ExternalLinkButton`.
  Home places it after recent updates; MY puts it in 서비스 after personal lists.
  Guest and account use identical public access without login gating.
- Copy: **논술 준비, LegendStudy LAB** / **논술 준비를 위한 LAB을 웹에서 살펴보세요.** /
  **LAB 살펴보기** with external-link icon. Introduction/discovery only, no promise
  of active AI correction, current university problem inventory or payments.
- Existing externalApplication launcher owns OS browser choice, catches raw
  exceptions, displays safe inline failure and allows retry; busy disables repeat
  submission. Returning does not navigate, save data or hand off app sessions.
- Web repo `LC3808/legendstudy-lab` remains separate. Shared auth, payment,
  entitlement and study/essay record sync **NOT IMPLEMENTED**; **WebView NOT USED**.
  Materials resolver, Auth, Study, brand/native identity and backend unchanged.

Validation: full Flutter **482 PASS / 1 existing skip**, LAB focused **10 PASS**,
analyze, Android debug/iOS simulator build, credential scan and diff check PASS.
360×640 at 1×/2× Guest/account Home/MY renders reviewed; minimum CTA height 48.
iOS simulator native matrix passed (10 checks), real public Safari launch and
app return additionally checked. Render evidence is local under
`/private/tmp/legendstudy-core-ui/lab-*.png` and
`/private/tmp/legendstudy-lab-native/`; not repository assets. No dark theme exists.
The live-browser integration test is opt-in (`LAB_LIVE_BROWSER=true`); the
operator/host returns to the app within 12 seconds after `LAB_BROWSER_OPEN`.
The test asserts resumed lifecycle; browser content is separately inspected. Other tests
use opener/account doubles, never Production auth. This is not real-account E2E.
Canonical correction, rechecked read-only: `/` is HTTP 200; `/lab/` returns
HTTP 308 to `https://lab.legendstudy.com/`. This supersedes the earlier opposite
direction note. The app already uses the equivalent root URL; LAB code unchanged.

Owner follow-up: physical Android/iPhone browser/back acceptance and independent
LAB web availability/content management. No app config, shared auth or payment
setup is required for this entry. Existing policy URLs, Auth/recovery/deletion
acceptance and store gates still block release. **RELEASE READY NO**.
Production mutation 0; no Cloudflare/DNS, web repo, DB, Storage or Edge changes.


## Materials inline bookmark — 2026-09-20

The earlier HOLD is closed by the [shared bookmark contract](day-9-c-personal-state.md#materials-inline-bookmark--2026-09-20).
Search rows save/unsave without navigating, using optimistic filled/outline icons,
48px targets and accessible busy/selected/retry labels. Errors rollback locally;
search and other rows remain usable. Guest receives a login prompt and returns
to the mounted search route without automatic save or repeated search.

Full **493 PASS / 1 existing skip**, new focused **11 PASS**, native iOS fixture
journey **2 PASS**, analyze, Android debug and iOS simulator builds PASS.
All six filters/query/pages/scroll, Guest cancel/sign-in, A→Guest→B, detail/list,
rollback and bounded lookup behavior tested. 360×640/1×/2× renders reviewed.
Credential/diff checks PASS. Actual Production bookmark E2E was not run; mutation 0.
No delivery/rights/Viewer/ingestion/LAB behavior changes. Release gates unchanged.

## MY configured state and core mobile audit — 2026-09-21

Root cause: ProfilePage rendered static school/grade setup labels and explanatory
copy, without subscribing to saved values. This was a display/read-path omission,
not evidence of lost Production data. School already restores through
schoolSelectionProvider: profiles.neis_office_code/neis_school_code → NEIS lookup
→ School.name. Authenticated selection writes only those profile columns; Guest
selection is memory-only. Grade uses existing UserProfile.gradeLevel (1/2/3),
profiles.grade_level and sparse profile upsert, not local preferences.

MY now renders Label / Current value / Action. Unset shows 설정; set shows actual
school name or 고등학교 N학년 and 변경. Loading suppresses unset/value/action;
errors offer retry instead of claiming unset. School reuses its existing provider.
A new owner-watching currentProfileProvider reads the existing repository, rejects
owner mismatch and reloads after successful grade save. No parallel local cache,
new taxonomy, schema or Auth/session change. On a fresh app container, existing
SDK Auth restoration triggers canonical profile/NEIS reads; device E2E remains open.

Local evidence: new state tests cover school/grade set/unset/loading/error at
360×640/2×, school selection, grade invalidation, logout/login and fake-repository
fresh-container restore. Existing grade widget test verifies save invalidates the
MY read provider. Full suite 513 PASS / 1 existing skip; analyze and both Android
debug/iOS simulator builds PASS. MY raster reviewed with actual theme and Korean
font; no overflow. This is local evidence, not Production session persistence.

### Core screen audit (code review; no broad redesign)

| Screen | Findings / follow-up |
|---|---|
| Home | Existing typed data states, section accents and scrollable shell; selected study metric uses w800 intentionally. No new P0 found. P2: review overall section density in a later device UX pass, not another redesign now. |
| Materials search | Search hint, clear tooltip, wrapped filters, loading/error/empty and retry are distinct; keyboard submit dismisses focus. P2: filter ActionChip shows visual check/background but does not explicitly expose selected semantics; improve screen-reader selection feedback later. |
| Saved | Guest login and empty → 자료 찾기 escape path; owner-scoped loading/error/retry. Saved copy explicitly distinguishes downloads. P2: 3-line ellipsis hides long titles at 2×; detail remains accessible, assess title readability later. |
| MY | Fixed P1: real configured school/grade were hidden by static setup copy. Labels/values/actions separated; progress/error distinct, ≥48px CTA, wrapped value in Expanded. No session implementation changed. |
| Login | Existing primary email CTA, gated aligned social buttons, autofill/show-password, busy/error and protected return retained. No new P0 from review; real provider/device E2E still independent. |
| Signup | Existing confirmation/validation and session-dependent verification guidance retained; scrollable form and error wrapping. No new defect established. |
| Recovery | Separate request/reset flows, safe error and scrollable inputs retained; real mail/cold/warm acceptance remains pending. |
| Settings (within MY) | No separate screen needed. App version asynchronous; unavailable policies explicit. P1 release gate: Owner-approved App policy/support/deletion URLs still need final verification. P2: NestedPage itself lacks bottom SafeArea unlike tab shell; check bottom gesture inset on nested forms during final physical UX pass before changing shared layout. |

P0: none newly demonstrated in this scoped review. P1 MY display fixed; policy
finalization remains Owner work. P2 items above are audit follow-ups, not proven
runtime failures. Existing typography/spacing and navigation hierarchy retained;
no new global font/bold/card rules. Auth prior keyboard/render evidence is retained;
this task adds MY raster evidence, not new physical renders for every audited screen.

Owner-observed iOS debug home-screen launch warning (“In iOS 14+, debug mode Flutter
apps can only be launched…”) after disconnecting Flutter tooling is not evidence
of a session-restore defect. Owner later verified `APP_SESSION_RESTORE: PASS` on
iPhone Profile after terminate/relaunch; the Debug tooling warning is not a failure.

## Owner Profile UX follow-up — 2026-09-21

Owner reports Email App login, session restore and MY school/grade actual values
PASS on iPhone Profile. Preserve this device evidence; earlier Debug launch warning
was not a session bug. Social Auth/shared identity/isolation remain separate gates.

Home LAB promotional entry and its trailing gap removed; MY LAB entry, URL/opening
foundation and architecture retained. MY gear (tooltip/semantics 설정, ≥48px) pushes
/my/settings in the existing MY navigator. Settings groups account/service/policies/
account management; reuses dynamic appVersionProvider, safe configured policy links,
logout busy/error behavior and existing deletion route. Deletion has destructive
styling; Guest Settings hides account destructive actions after logout. No second
shell or new auth/session implementation. POLICY/ACCOUNT_DELETION readiness stays NO.

Scoped audit: P0 meal time/data interpretation fixed; P1 hidden tomorrow load errors
and missing Settings entry fixed. Home/Materials/Saved/Login retain existing safe
states and navigation; no new P0 observed. Remaining P1 release gate: final Owner
policy URLs and deletion deployment/revoke. P2: Materials filter selection semantics,
long saved titles and final physical spacing/accessibility pass, not a new redesign.
Settings and meal detail use SafeArea/scroll; 2× long-email/menu raster reviewed.
School/grade providers and Auth modules were not modified in this follow-up.
Owner confirmed the meal progression and MY Settings UI on iPhone:
`MEAL_TIME_AWARE_DEVICE_E2E: PASS`, `MY_SETTINGS_DEVICE_E2E: PASS`. Policy and
account deletion production readiness remain NO. No Production mutations, console
or signing edits.

## Mobile IA, Profile and Learning — 2026-09-23

IMPLEMENTED: 홈/자료/학습/LAB/MY independent tab stacks; old deep paths preserved,
/my/grade redirects to integrated school/grade. LAB links only the current public
service root; no unverified analysis/AI service routes or fake results. MY removes
email banner and LAB entry; compact nickname/default avatar, single school·grade
row, common learning summary and saved/recent entries. Settings groups account,
profile, learning, service/policies, destructive account management. Logout dialog
requires explicit confirmation and owner consistency; cancel/dismiss sends no call.

Profile uses existing nullable display_name (trimmed 1–80 code points, no controls),
explicitly entered, optional at signup. Nonunique; no social metadata import or
new identity/table/RLS. Existing school/name/grade sparse writes retained; grade
clear is explicit NULL, omitted grade preserves it. School and optional grade are
edited on one screen with independent save feedback (no false atomic-save claim).
Nickname persists in existing owner profile. First increment used a default
avatar; the second refinement below adds gated private photo upload. Profile field/grade load failures cannot be saved as empty defaults.

Learning keeps study summary/history exclusively in Timer; Mock retains current
setup/countdown/answer entry/server scoring/grade/basic result/history. Existing
single active draft prevents timer/mock simultaneous runs. No manual score-entry
feature or new LAB advanced-analysis integration was invented. Exam-specific
include toggle snapshots into draft/completion, survives restarts, and never
changes the default preference. Default ON preserves previous totals. Settings
preference is owner-isolated local atomic storage (Guest separate), not cross-device.
Home/Learning/MY share existing KST union aggregation, now filtering excluded mocks.
Raw exam segments and scoring attempts are retained whether included or excluded.

Owner reports 20260923000100_study_total_inclusion.sql applied PASS with zero
existing/excluded/invalid rows. Populated A/B cloud acceptance remains separate.

OWNER E2E REQUIRED: five tabs → LAB → MY → school/grade summary/editor → Settings
→ cancel/confirm logout → Timer → Mock → inclusion toggle. Repeat restart/owner
switch and confirm Home totals. New mobile UI device E2E NOT VERIFIED. Prior Owner
Email/Apple/Google/Kakao App and LAB login, session restore and school/grade acceptance
remain PASS; Kakao cross-platform identical user is NOT VERIFIED.

Future handoff (NOT IMPLEMENTED): Community uses this same auth-owned nickname and
future avatar only; email/provider private; school/grade publication undecided.
Decide Unicode normalization, case/uniqueness, reserved names/change/reuse policy
before Community posting. Add a minimal public projection/RPC with reviewed RLS,
never public SELECT of full profiles. Boards/comments/report/block/moderation later.
Avatar upload is now gated code in the second refinement below; public Community
profile and image access still require separate privacy/RLS design.
LAB Web separately: simplify Account, remove internal identity/session prose, group
user account info, add logout confirmation, responsive QA, review temporary safe
Kakao diagnostic verbosity. Do not change LAB in this App task.
Mock Phase 2: build on existing answers/scoring/attempts; remaining work is manual
score entry/product paper selection and real LAB data linkage, not reimplementing D2/D3.
Apple revoke/renewal, Google rotation, account deletion/policy/Store gates stay OPEN.

Validation closeout: 589 PASS/1 existing skip, analyze, Android debug and iOS simulator
builds PASS on canonical Flutter 3.47.5/Dart 3.13.4. 24 render cases across 360×640 /
428×926 and 1×/2× pass; reviewed MY/Settings/school/Mock/LAB raster images under
/private/tmp/legendstudy-core-ui (ephemeral local evidence, not repository assets).
iPhone 17 Pro simulator native Home/five tabs screenshot reviewed at
/private/tmp/ls-ia-simulator-home.png. No new physical-device acceptance claim.
Large text intentionally wraps and scrolls; no clipped CTA/overflow detected.
Secret pattern and GitHub ignore/artifact audit PASS (manual local checks, no
existing audit executable found). SQL grammar/static RLS review PASS; live migration
and server acceptance NOT RUN. Owner native file hashes unchanged. Production 0.


## MY dashboard, Study Trends and LAB refinement — 2026-09-23

IMPLEMENTED: configured nickname hides MY edit text; missing nickname shows
프로필 설정. Avatar tap and Settings → 프로필 edit the same private own photo.
No school/grade/avatar requirement is added to profile completion. Two study CTAs
open existing Timer and /my/trends. An already active Mock retains the existing
single-session guard rather than creating a concurrent Timer.

Study Trends use common KST interval union (Home/Timer/MY same inclusion rules),
14 daily / 8 Monday-start weekly / 6 calendar-month bars. Six-month bounded query,
100-row keyset pages, 2000-row cap fails visibly instead of silently truncating.
Local unsynced records merge by ID; overlapping time is unioned, excluded mock
raw records remain intact. Active draft contributes to chart/current summary,
not completed-period comments. Ten-percent stability threshold, minimum three
active calendar days across the comparison, zero-baseline nonpercentage message.
Compare completed 7 days, completed 2 weeks, or last full calendar month against
the previous matching period. Calendar months compare total time, not daily rate.
No AI or inferred grades. Error/retry remains within the detail, not whole MY.

MY 성적 is separate from 나의 자료. Existing device-known completed Mock attempts
supply raw/max/grade label; no invented trend from one score. /lab/scores exposes
existing result/history with provenance. New-device cross-device attempt discovery
is not implemented; only already known attempt IDs refresh. Internal school-grade
input/backend does not exist, so its row explicitly says unsupported (no dead
성적 입력 CTA). LAB separates score overview and public 논술 준비 entry; no
unverified authenticated Web route or token forwarding. No WebView.

Photo: image_picker gallery only, 512px bound, PNG re-encode strips EXIF, 1MiB max.
Android recovered picker result is discarded before a fresh selection: it is never
uploaded automatically under a possibly different owner. Captured Storage headers
bind each operation to the selecting account; late responses cannot paint another
owner. Refresh removes old MemoryImage bytes after replace/delete. Load failures
are retryable and not silently treated as missing images. iOS library usage copy
is the only new Info.plist setting; existing Owner native changes are not staged.
See [private Storage Owner procedure](database.md#private-profile-avatar--owner-action-required).

Classification:
- IMPLEMENTED (local code): conditional Profile CTA, study CTAs/Trend/chart/comments,
  Mock score summary/overview, private photo edit/service, existing Essay Web entry.
- FOUNDATION: photo Production availability (migration + deletion rollout/E2E),
  internal-grade summary slot with honest unsupported state, private own avatar as
  future Community identity. No public Profile query.
- FUTURE: internal-grade input/analysis, target universities/majors/admissions,
  probability bands, essay target schools/history, Community activity queries,
  full cross-device score discovery and detailed LAB Web reports.

Owner device sequence after review: MY profile/CTA → study Timer → Trend daily /
weekly / monthly → score empty/actual results → LAB score / essay → five tabs →
Settings. Then **after** private Storage/action gate: avatar choose/upload → MY &
Settings immediate image → restart → replace → remove/default → A/Guest/B isolation.
Use naturally occurring records; no fake Production scores/study rows required.
New device E2E NOT VERIFIED. Prior Owner Auth/session/meal acceptance is preserved.


Second-refinement validation: Flutter 3.47.5 / Dart 3.13.4; full 628 PASS / 1 existing
skip, analyze PASS, iOS simulator + Android debug builds PASS. 40 renders cover
MY configured/unset, Settings, Profile keyboard, school, LAB, Mock, Trends empty/data
and scores at 360×640/428×926 × 1×/2×. Selected actual PNGs visually inspected,
no overflow; 2× CTAs stack. Photo tests cover private owner paths, pick/replace/
remove, upload/permission failures, stale picker and A→Guest→B late-load protection.
Deno deletion candidate 11 PASS + index type check. SQL pglast grammar and manual
private-policy/compatibility review PASS; live Storage/A/B E2E not performed.
Secret patterns + ignore/staged-artifact GitHub readiness reviewed (no dedicated
repo scanner executable); diff check PASS. No Production mutation or push.
image_picker is the only new direct dependency (official Flutter plugin, no existing
package upgrades); no chart/crop package. iOS CocoaPods migration advisory and
Android KGP future-version advisory remain non-failing existing tooling follow-ups.

Final simulator install/launch and settled Home/five-tab screenshot were verified
on iPhone 17 Pro simulator (`/private/tmp/ls-refine-simulator.png`). This is a
credential-free local launch, not Owner iPhone/profile/photo Production E2E.
