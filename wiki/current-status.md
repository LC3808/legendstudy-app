# Current Status

Last reviewed: 2026-09-13

## Phase

**Day 7 = COMPLETE. Next stage: Day 8 Study.**

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
  were not rerun. No Flutter, DB/schema/migration, secret or Auth-user changes.

## Next: Day 8 Study — planned, not implemented

The current Study page remains an idle timer/empty-history shell. Start the next
stage with a scoped implementation plan and storage/platform capability review:

- General study timer.
- Today's cumulative study time, study history and recent seven days.
- Focus / Do Not Disturb integration, subject to actual iOS/Android capabilities
  and user-granted permissions; do not promise unsupported system control.
- Mock-exam mode.
- Subsequent design for automatic grading, scores and grade-level results.

Any new production storage follows the existing owner-review/application process.
Day 8 has not started in this documentation task.

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
