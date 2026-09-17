# Current Status

Last reviewed: 2026-09-17

## Day 11-B3 — Production Admin Inbox — IMPLEMENTED / E2E PENDING

- Added the MY admin menu, guarded Admin Inbox list/detail routes, server-derived
  `is_feedback_admin()` access state, newest-first bounded listing, status
  filters, diagnostics and forward-only status management.
- Production feedback DB/RLS and Admin JWT acceptance remain verified. This
  task made no Production API call or mutation. Controlled user submission →
  Admin Inbox → 확인중 → 처리완료 E2E is pending Owner acceptance.
- Email Worker/provider/secrets and reverse status transitions remain pending;
  account-deletion retention/anonymization is still an Owner decision. See
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
- Admin bootstrap and Admin JWT acceptance are complete. Admin Inbox UI is now
  implemented, while Production E2E remains pending. Email worker/provider,
  secrets, admin email, test email and push remain **NOT DONE**. Open policy
  decisions are account-deletion retention/anonymization and reverse status
  transitions. See [Day 11-B1 closeout](day-11-b-feedback-production.md).

## Day 12 — Home Information Architecture & Visual Hierarchy

- Home order is now D-Day → 나의 공부 시간 → 우리학교 급식 → 자료 검색 →
  최근 업데이트 → 최근 본 자료.
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

- Implemented KST-based today/tomorrow meal display with 17:00 dinner and
  tomorrow priority, boundary/resume refresh, and no empty tomorrow section.
- Home recent updates and recent views are now bounded to six records, show two
  by default, and independently expand/collapse to six. Full Materials/MY
  semantics and guest/auth account isolation remain unchanged.
- Full tests (335 passed, one opt-in read-only network skip), analyze, Android
  debug build and iOS simulator build/run pass. iPhone Profile built, but
  CoreDevice automated launch timed out before interactive Home verification.
- Details and remaining device follow-up: [Day 10-B Home Polish](day-10-b-home-polish.md).

## Essay Lab product roadmap — PLANNED

- Product priority is now AI essay feedback (Essay Lab) ahead of grade
  analysis and admission prediction. Target: **2026-10 Beta or initial public
  service**.
- The planned service combines the existing Mobile App, a Web-primary long-form
  authoring surface, and the shared Supabase backend. Initial scope is typed
  answers, structured question-level evaluation packages, approximately 5–10
  universities and the latest 2–3 years of available material.
- The initial business model is account-level server-side free credits for the
  first three evaluations, followed by credit/package purchase consideration.
  Accumulated “My Essay Pattern” data and growth history are core retention and
  conversion value; free results must not be intentionally degraded.
- Academic Profile and Admission Simulator are explicitly **LATER**. No Essay
  Lab code, schema, AI evaluation, credit, payment or Production work is
  implemented by this roadmap entry. See [Essay Lab roadmap](roadmap-essay-lab.md).

## Day 10-A — Flutter 3.47.3 official toolchain migration — COMPLETE

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

## Backlog / TODO recorded during Day 10-A

- Home Meal Card v2: today/tomorrow data, the 17:00 KST dinner boundary,
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
