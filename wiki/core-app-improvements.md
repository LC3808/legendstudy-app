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
- Recovery implementation is unchanged. Existing deep-link/recovery regressions
  remain part of the full suite.
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
