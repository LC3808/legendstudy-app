# Current Status

Last reviewed: 2026-09-14

## Phase

**Day 7 = COMPLETE. Day 8 design approved / final migration prepared; production application pending.**

Product Owner accepted the final runtime results. Repository/code and Wiki were
checked before this documentation closeout. Live deployment/JWT/Flutter results
below are owner-reported and match the checked-in acceptance tools; they were not
rerun in this documentation-only task. Earlier implementation checkpoints remain
in [log.md](log.md); this page describes the current state rather than historical gates.

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

## Validation baseline

- Flutter analyze PASS; 107 Flutter tests PASS (existing 95 retained/adapted plus
  12 persistence tests), including 360×640 and 2× text scale.
- 13 Python verifier/runner offline tests PASS; NEIS Deno typecheck and 9 proxy
  tests PASS at the recorded feature checkpoint.
- Android debug and iOS simulator builds PASS; latest owner Flutter persistence
  runtime smoke PASS. Credential scan and git diff --check PASS at implementation.
- This closeout changes documents only; Flutter tests/builds and production tests
  were not rerun. Day 7 validation is historical. The current package adds an unapplied migration;
  no Flutter, production, secret or Auth-user changes.

## Next: Day 8 Study — migration ready, not deployed or implemented

[Study v1](study-v1.md) defines 8-A timer/state/guest/auth/Home/seven-day behavior,
8-B platform-aware focus, 8-C mock countdown/notifications and 8-D later scoring.
[Storage proposal](day-8-study-storage-proposal.md) includes reviewable SQL,
preflight/catalog/rollback and real JWT acceptance plan. New migration:
20260914000100_study_sessions.sql; not yet applied. Copy-ready SQL is in the
[migration package](day-8-study-migration-package.md).

Approved v1: durable local active timer, immutable completed cloud sessions with
validated active intervals; no live cross-device timer or automatic guest upload.
Study shell and Home summary remain static; this task changes design/proposal only.
Android DND requires policy access and own-rule lifecycle validation; iOS has manual
Focus guidance, not a promised automatic global toggle. Focus preference stays local.

Owner approved the contract; cancelled sessions remain local, with no cloud status
column. The bounded KST-window SELECT contract adds no aggregate RPC.
Next Owner preflight/application/catalog checks, then real JWT acceptance and
8-A. No production call/deployment, Flutter implementation, push, PR or merge in this
step. Static validation details are in the proposal; Day 8 is not COMPLETE.

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
