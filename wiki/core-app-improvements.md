# Core App improvements — 2026-09-20

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
  No viewer, download, mirror or destination-resolution change.
- Guest bookmark pushes login, then successful sign-in returns to original
  detail. It does not auto-save; user taps save after returning. The visible
  auth route owns return navigation (GoRouter push retains the branch URI).
  Saved/recent empty states provide login or Materials navigation; saved items
  are explicitly bookmarks, not downloaded files.
- Inline search-row bookmark is HOLD: current state reads are per-content.
  Adding one per result creates N+1 reads and needs a bulk/optimistic/rollback
  contract. Existing detail bookmark and duplicate-request protection remain.
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
LS LAB initial placement recommendation: MY service link, external web launch,
only after Owner supplies the published URL. Promote to a small Home card once
public utility is demonstrated. No placeholder link, web edits, shared auth,
token handoff, payment or result sync is implemented.


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
existing ingestion contract, (5) LS LAB entry only after a real web deployment
URL. Analytics/BM remain deferred.
