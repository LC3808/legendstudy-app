# Current Status

Last reviewed: 2026-09-15

## Phase

**Day 7 = COMPLETE. Day 8-A Study Core = COMPLETE. Day 8-B Focus / DND implemented; Owner-reported iOS lifecycle subset PASS, Focus guidance and remaining physical checks pending. Day 8-C Mock Exam implementation complete; Guest/Auth Flutter runtime PASS; Owner-reported iPhone timeUp/notification/kill-restore PASS, remaining physical checks pending. Day 8-D1 Scoring Storage / Validation Contract = COMPLETE (Owner-reported production/Postflight and actual A/B JWT/RPC PASS); Day 8-D2 Answer Entry + Raw Score = COMPLETE (Guest runtime and Owner-reported actual A/B Flutter scoring PASS). Day 8-D3 Grade + Result UX = COMPLETE (Owner-reported actual A/B Flutter runtime and full cleanup/retention PASS). Day 8 overall is not COMPLETE.**

Product Owner accepted the final runtime results. Day 7 live deployment/JWT/Flutter results below are owner-reported.
Day 8 production migration and full real A/B Study JWT acceptance are also
owner-confirmed. The final Day 8-A Flutter Guest/authenticated runtime PASS is
also Owner-reported and matches the checked-in smoke stages. Prior implementation
checks are retained below. Day 8-B implementation checks are listed separately;
no production calls or DB changes were made for Focus. Earlier implementation checkpoints remain
in [log.md](log.md); this page describes the current state rather than historical gates.

## Day 9-A Search / Explore — implemented, iOS validation pending

- Materials now provides metadata search, dynamic filters, grouped attachments,
  bounded pagination, explicit empty/error/retry states and Home query handoff.
  Public repository/controller/UI layers and test-only fixtures are separate.
- Read-only public counts: content_items/exams/subjects/exam_subjects/resources
  each 0 on 2026-09-15. Real Supabase SDK search/filters/later-page contract PASS.
  No production fixtures, ingestion, DB/schema/RPC/migration or personal writes.
- Desktop Flutter screenshots reviewed at 360×640/428×926 and 1×/2×. Analyze,
  full 306 tests (one opt-in network test skipped),29 render/handoff tests, separate
  real-SDK public read-only smoke, Android debug and diff/credential checks PASS.
  iOS simulator/profile/native review blocked by
  Xcode's unaccepted license; Owner review/acceptance requested. Day 9-A is not yet
  COMPLETE. Prior Day 8 iPhone PASS and remaining physical edges remain unchanged.
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
