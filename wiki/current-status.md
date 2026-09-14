# Current Status

Last reviewed: 2026-09-14

## Phase

**Day 7 = COMPLETE. Day 8-A Study Core = COMPLETE. Next: Day 8-B Focus / DND. Day 8 overall is not COMPLETE.**

Product Owner accepted the final runtime results. Day 7 live deployment/JWT/Flutter results below are owner-reported.
Day 8 production migration and full real A/B Study JWT acceptance are also
owner-confirmed. The final Day 8-A Flutter Guest/authenticated runtime PASS is
also Owner-reported and matches the checked-in smoke stages. Prior implementation
checks are retained below; tests and production calls were not rerun in this docs-only closeout. Earlier implementation checkpoints remain
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

## Next: Day 8-B Focus / DND

- Android DND/focus integration, with first-use choices: `항상 사용 / 이번만 / 사용 안 함`.
- Preference is device-local; one-time selection does not become a persistent preference.
- Permission denial or capability failure must never prevent the Study timer starting.
- Separate platform capabilities using official APIs. iOS must not offer or claim
  automatic system Focus toggling; provide supported guidance instead.
- Native capability, consent and restoration behavior are the next implementation
  scope. No Focus/DND code is added in this closeout. Day 8 overall is not COMPLETE.

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
