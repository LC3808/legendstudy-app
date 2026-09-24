# Day 8-D2 — Answer Entry + Raw Score

**Day 8-D2 Answer Entry + Raw Score = COMPLETE. Guest runtime and Owner-reported actual A/B Flutter scoring smoke PASS.**
Day 8-D1 remains COMPLETE. Day 8 overall is not COMPLETE. No schema/migration change.

## Availability and trust boundary

The existing Mock timer remains usable with zero scoring data. A bounded public
availability lookup (up to100 current papers) uses mock_exam_scoring_availability;
exam occurrence/title metadata names the selector. No production fixture is bundled.
The selector offers timer-only and an explicit refresh to recover an updated list.
A selected paper is rechecked/prepared before starting; no automatic version replacement
occurs for an already submitted/pending attempt.

MockScoringAvailability models timer_only/scoring_available and pinned occurrence,
variant, key/version, count, total, optional cutoff and engine metadata. AnswerEntryQuestion
contains number, type and points only: **no correctAnswer field**. The entry repository
projection excludes correct_answer. Solutions are fetched only by the Guest scoring
service after durable submission. Auth uses RPC and server-returned snapshots.

## State and durable storage

AnswerDraft has immutable, ordered nullable choices1–5 indexed by question number.
Selecting the selected choice again clears it. Counts derive from the choices.
Each choice is serialized to the native atomic file before committing visible state;
no per-choice cloud write. A failed local write retains the previous answer.

Study local envelope v3 upgrades v1/v2 without losing owner records/outboxes. The
StudyDraft stores answer metadata/questions/choices alongside the native clock state.
Freeze/pause/resume/recovery retain answers. Completion writes Study history and the
immutable scoring attempt/payload to the same atomic document. The generated attemptId
is durable before the first RPC; timeout/retry sends the same ID and six-field payload.
Study upload is acknowledged before submitting a linked authenticated attempt.

Guest namespaces never upload upon login. Logout/account changes hide prior state;
epoch checks reject stale async results. A new account cannot inherit a prior request.
Completed scoring results are independent from Study records and retained locally.
Auth local results cache only the verified server result; this is not a cloud-wide
history index. Cross-device history listing/cache invalidation and result deletion UI
remain follow-up scope; existing server delete semantics are unchanged.

## UX and lock policy

The existing Study/Mock switch and timer-only setup remain. Scoring adds a paper
selector, a root-navigator answer page (separate from bottom tabs), sticky countdown,
progress and pause/submit actions. Rows are grouped by five without per-question cards.
The number grid distinguishes answered with a checkmark and spoken state; tapping jumps
to the row. 45 and100 questions fit360×640 at1×/2× text; choice targets are >=48px.

Running permits marking; paused, recovery, timeUp and submitted states refuse mutation.
TimeUp keeps the existing exact active cutoff and Focus/notification cleanup and waits
for confirmation. Submission dialog reports unanswered count; cancelling keeps the
original state and a running clock continues. Correct answers are absent before submit;
result history is hidden while a new session is active to avoid exposing old solutions.

Pending/submitting/completed/stale outcomes are distinct. Failures keep local answers
and never claim a score. Stale versions show a safe notice plus read-only retained
answers; the user can select a new exam explicitly. No auto-rescore/new UUID on retry.

Results show raw/max score, correct count, wrong/unanswered numbers and per-question
submitted/correct choice, points and outcome. Grade metadata is retained for parity,
not promoted into a Day8-D3 grade-analysis UI. No subscription, graphs, AI or admissions
features. No user-facing development placeholders.

## Server and Guest scoring

Auth sends only p_attempt_id, p_study_session_id, p_answer_key_version_id,
p_grade_cutoff_version_id, p_scoring_version and p_answers. Owner comes from the captured
Supabase session/JWT; no user_id/score/grade/correct-answer payload. RPC then fetch-own
read-back must match ownership, pinned scope, answers, counts and internally consistent
snapshots/totals before local completion. Server results are never overwritten by a
Guest calculation. Historical idempotent retries reach RPC without a client current-check.

Guest uses the pure Dart mcq5-v1 engine with publication data read only at scoring time.
All37 shared D1 vectors match, including confirmed/estimated boundaries, no-cutoff,
wrong/blank and mixed points. Guest result storage is device-local; no RPC/cloud upload.

## Verification

- Flutter full suite228 PASS (177 previous tests plus51 scoring/vector/UI tests).
- Shared server/Dart vectors37/37 PASS; exact six-field payload, malformed server
  result, timeout/same-ID retry, stale version, owner switch/late response, local-write
  failure, restore and lock policy tested. Native Focus/School/D-Day/Study/Mock regression
  retained.100-question grid navigation and2× semantics/touch-target checks included.
- Android debug build and iOS simulator build PASS; Android SDK metadata warning is
  non-fatal. Flutter analyze and git diff --check PASS.
- Real iOS simulator test-only Guest runtime PASS: answer, pause/resume, native draft
  restore, submit/raw score, native result restore and restoration of the original
  whole local file. This uses synthetic injected repositories, not published fixtures.
- Actual LegendStudy public availability read from Flutter:0 rows PASS (read-only).
  This is not populated scoring evidence and created no production fixture.
- Owner reports actual populated A/B Flutter scoring RPC, server-confirmed result
  restoration and account switching with controlled production fixtures **PASS**.
  This is independent Flutter evidence, separate from D1 Python JWT acceptance.
- Physical background/lock/kill/reboot remains a separate device gate. Native smoke
  reconstructs controllers against real platform storage/clock, not OS process kill.

Smoke entry: integration_test/mock_scoring_smoke_test.dart. Run with flutter test -d
an iOS simulator. Optional SCORING_LIVE_EMPTY_SMOKE=true plus the external public
Dart-define file performs a read-only real availability-empty check. It creates no
production fixture; the synthetic Guest branch always restores the original local file.
That Guest-only smoke makes no production mutations or fixture publication. The
Owner-run A/B smoke below uses approved temporary fixtures and verified cleanup.
This documentation closeout makes no production changes, Push/PR/Merge.

Next: Day 8-D3 Grade + Result UX. This closeout does not start D3 implementation.
Day8 overall remains NOT COMPLETE; 8-B/8-C physical-device validation remains pending.

Native smoke markers:

```text
SCORING_FLUTTER PASS production_availability_empty
SCORING_FLUTTER PASS guest_answer
SCORING_FLUTTER PASS guest_draft_restore
SCORING_FLUTTER PASS guest_pause_resume
SCORING_FLUTTER PASS guest_submit_raw_score
SCORING_FLUTTER PASS guest_result_restore
SCORING_FLUTTER PASS local_fixture_cleanup
```

## A/B native Flutter scoring runner (Owner runtime PASS)

`tool/run_mock_scoring_flutter_smoke.py` launches
`integration_test/mock_scoring_auth_smoke_test.dart` on the iOS simulator. This is
separate from the D1 Python/JWT acceptance: Flutter signs A/B in with the Supabase
SDK and exercises the production StudyController, AnswerEntryPage, native atomic
store, SupabaseStudyRepository and SupabaseScoringRepository/RPC/read-back.

Run with the existing external scoring verifier Python environment:

```sh
cd /Users/woojinchang/development/legendstudy-app && /private/tmp/legendstudy-scoring-verifier-venv/bin/python -B tool/run_mock_scoring_flutter_smoke.py /Users/woojinchang/legendstudy-local.json
```

A/B passwords and the LegendStudy DB password use hidden terminal input. The
non-secret Session pooler hostname is the same Dashboard Connect hostname used for
D1 (blank selects the pinned direct host). No administrator credential reaches
Flutter. A one-use random loopback URL delivers public config and account inputs
in memory; only that temporary URL is a Dart define. Output forwards exact allowed
stage markers, never Flutter raw output, raw HTTP bodies or credentials.
`--preflight-only` checks login/admin baseline without creating fixtures;
`--device <simulator UUID>` selects another booted iOS simulator.

Coverage: real availability/preparation, multiple answers/change/unanswered,
pause lock/resume, native controller reconstruction, authenticated submission,
server score/snapshot and canonical read-back, result reconstruction compared to
a fresh server fetch, account switch and B RPC/answer isolation. A controlled
key/cutoff current switch then tests the identical historical attempt retry,
exactly one server attempt, and rejection of a new stale attempt with answers
retained and no result/fake success. No local fake scoring repository is used.
The entry page is mounted directly with the real controller/repositories; this
runner does not claim tab navigation, OAuth UI, OS-kill restoration or cross-device
history acceptance. During running, the stable identifier is the Study draft ID;
the scoring attempt ID is allocated durably at submission and retained for
restore/retry. No new pre-submission attempt-ID contract is introduced.

The D1 administrator fixture lifecycle is reused separately from Flutter. Every
Study/attempt UUID is registered and collision-checked **before** native repository
writes (maximum two each); checkpoints reconcile lost acknowledgements. The native
process/app is stopped before cleanup. Cleanup reuses the single transaction,
locks, exact run scopes/counts/digests, three specifically approved USER triggers,
FK cascades, full trigger restoration and public baseline comparison. All registered
Study owners are checked under lock. No production schema change or normal
published-data deletion permission is added. Native local storage is backed up in
memory and restored in the test's finally block. A failed/missing stage or missing
local cleanup prevents overall PASS; administrator cleanup still runs on failure.

Preparation validation: 9 runner offline tests and all45 existing JWT offline tests
PASS (private PostgreSQL, not production JWT evidence); full228 Flutter tests,
flutter analyze and iOS simulator integration-target build PASS. Python syntax,
credential scan and git diff checks PASS. Owner subsequently completed the actual
A/B Flutter run below. Day8-D2 is COMPLETE; Day8 overall is NOT COMPLETE.

## Accepted Day 8-D2 runtime evidence — COMPLETE

Owner reports the following actual A/B Flutter results. Existing synthetic Guest
native runtime PASS is retained above; it is not represented as production Guest
scoring. Pause/timeUp mutation policy PASS combines the actual pause/resume smoke
with the existing Guest/Auth automated frozen/timeUp mutation tests. No physical
background/lock/Focus/local-notification/kill/reboot acceptance is implied.

```text
D2_FLUTTER PASS login_preflight
D2_FLUTTER PASS auth_scoring_start
D2_FLUTTER PASS answer_entry
D2_FLUTTER PASS pause_resume
D2_FLUTTER PASS draft_restore
D2_FLUTTER PASS auth_submit
D2_FLUTTER PASS auth_result
D2_FLUTTER PASS auth_restore
D2_FLUTTER PASS account_isolation
D2_FLUTTER PASS retry
D2_FLUTTER PASS stale_version
D2_FLUTTER PASS local_fixture_cleanup
D2_FLUTTER PASS fixture_scope_verified
D2_FLUTTER PASS fixture_cleanup
D2_FLUTTER PASS cleanup_triggers_restored
D2_FLUTTER PASS scoring_baseline_restored
D2_FLUTTER PASS existing_data_preserved
D2_FLUTTER PASS auth_users_retained
Flutter scoring smoke: PASS
```

Answer entry/change/unanswered, draft restoration, authenticated server RPC and raw
score/result read-back, result restoration, account isolation, exact retry/idempotency
after current switch and stale new-submission rejection all PASS. Answers remain
preserved on stale rejection, with no fake success. Local/run fixture cleanup,
trigger restoration, scoring baseline restoration and existing public-data preservation
PASS; Auth A/B users are retained. Next: **Day 8-D3 Grade + Result UX**.

## Current exam selection and scoring handoff — 2026-09-24

This current contract supersedes the older free-text/flat-paper setup presentation.
The historical D2 Owner fixture acceptance above remains historical evidence, not
proof that every public Production exam has a verified key.

| Stage | Actual code/schema evidence | Status / boundary |
|---|---|---|
| Exam | `exams.content_item_id` PK → content_items title; initial_content_schema migration | IMPLEMENTED, not a separate exams.id |
| Subject | exam_subjects.id/content_item_id; versioned subject_id + taxonomy_version FK; raw_subject_label fallback | IMPLEMENTED; UI groups ScoringPaper by exam content identity, then selects that exam's subject/variant |
| Resource | resources.exam_subject_id/content_item_id composite FK, resource_type | IMPLEMENTED PDFs/links; resource availability does not imply machine-readable answer keys |
| Key | answer_key_versions + exam_questions; published/current/verified source/version/digest contract in scoring migration and availability view | IMPLEMENTED contract; broad real exam key catalogue/import is MISSING |
| Selection | SupabaseScoringRepository.availablePapers joins same exam_subject IDs to normalized subject/title | IMPLEMENTED for scoring_available rows only, bounded100; no fabricated exams/subjects; incomplete metadata fails closed |
| Preparation | prepare checks current key/cutoff version and question count/points/type; no correct answers in running AnswerDraft | IMPLEMENTED; original mcq5-v1 safety contract unchanged |
| Answers/attempt | StudyController scoringSetup→draft.answers→ScoringAttempt; local durable draft, frozen/time-up guards | IMPLEMENTED; selected context is fixed for scoring; pending request blocks start/duplicate selection |
| Score | authenticated submit_mock_attempt + fetch_own_mock_attempt; guest local engine only with verified published key | IMPLEMENTED, idempotency/owner/pinned version validated; stale keys fail, never AI/generated key |
| Result | mock_exam_attempts/mock_exam_answers, raw/correct/unanswered + sourced grade if available | IMPLEMENTED; grade cutoff absence is distinct from answer-key absence |
| MY | latest completed recorded result + deterministic correct-count comment; missing result explicit | IMPLEMENTED local known-history snapshot, no comparable-trend or admissions claim |
| Mobile LAB | /lab/scores: native history/result/provenance + next exam action | PARTIAL actionable analysis; aggregate strategy/cross-device history and Web deep reports FUTURE |

Refresh audit:
- Purpose: old “시험 목록 새로고침” called loadPapers(reset:true), cleared scoring
  context and queried repository availability again. It did not refresh exam PDFs,
  fetch new ingestion content, or calculate results.
- Source: mock_exam_scoring_availability → exam_subjects → exams/content_items and
  subjects. Existing query includes scoring_available only, limit100.
- When required/value: initial entry needs data; a failed network request needs
  retry. A permanent successful-state reset button exposed implementation detail.
- Decision: automatic entry load + “다시 시도” on failure. Empty success says
  “정답 데이터 없음 · 타이머만 사용할 수 있어요.” Full public catalogue including
  timer-only exams and pagination/data publication remains an explicit GAP.

Canonical path: 시험 선택 → 해당 시험의 과목/variant → published-key preparation →
시험 시작 → 답안 입력 → 제출/검증된 채점 → 실제 결과 → MY → Mobile LAB.
Title and subject are not editable in this path; duration preset cannot overwrite
canonical subject. A separate “타이머만 사용” practice retains editable **연습 이름**
and the existing timer subject presets (not falsely presented as an official exam
catalogue). No free-text subject field remains. This practice has no linked key,
no auto score and no fabricated result. Existing MCQ1–5 only; math short answers,
full catalogue browsing, large-volume pagination, cross-device full scoring-history
query and detailed trend/strategy are not completed by this UI correction.

Tests: device_followup_two_test (metadata join/fail-closed, exam-filtered subjects,
2x layout, pinned subject unaffected by duration); existing mock_scoring_test,
mock_scoring_ui_test, grade_result_test protect key/owner/result contracts. Production
DB was not queried or mutated in this task. No new migration or key publication.

## Owner follow-up 3 — dual practice modes

**IMPLEMENTED locally; new Owner device E2E NOT VERIFIED.** Historical D2/D3
Production fixture acceptance does not prove broad real answer-key availability.

### Actual schema/taxonomy audit

- exams shared content_item_id has year, grade_level, exam_month, exam_type;
  no separate agency or trusted duration column. Known official types used:
  national_mock (교육청), evaluation_mock (평가원), csat. Unknown/other types are
  not promoted into official practice by parsing their titles.
- subjects v1 has code/name/category/version and23 seeded subjects (common,
  integrated,social,science). Occurrences retain subject_id/taxonomy_version and
  raw label. No seeded foreign-language/vocational expansion in this task.
- UI 국어/수학/영어/한국사 is derived from actual canonical codes; actual
  social/science/integrated category→탐구; remaining actual rows→기타.
  This is presentation grouping, not a replacement taxonomy or invented subjects.
- Paper variants come from published-key availability rows, not hardcoded elective
  examples. Canonical raw occurrence and key paper_variant remain distinct.

### A — Official Past Exam Practice

Explicit mode, year→grade→month progressive selection. Multiple actual exams in
that cohort add a title selector; a single exam resolves without another dropdown.
Absent metadata is shown as unknown, never guessed. Only groups actually present
for the selected exam appear; Wrap prevents horizontal crowding. A one-option
subject resolves directly; multiple real subject/variant options get a compact
picker. Parent change clears child selection and prepared key.

SupabaseScoringRepository joins scoring availability→exam_subjects→subjects/exams/
content_items. Existing bounded100 scoring_available query remains; known official
exam_type filter adds classification. This is **supported-key catalogue**, not
full exam browsing. Empty/error is explicit; free timer remains usable. Missing
keys/unsupported numeric math are not advertised as automatically scorable.
Agency field and authoritative exam-duration metadata GAP: keep existing practice
presets/custom duration, do not invent official time or agency from title.

Preparation/start still checks published/current key and cutoff; draft pins actual
occurrence/variant/version; no answers leaked before submission. Existing Guest
verified local engine and authenticated RPC, owner isolation, stale rejection and
idempotent result read-back unchanged. Official result→existing MY Snapshot/LAB
only. No new strategy, admission, full key import or cross-device history engine.

### B — Free Practice

User title1–80runes, optional subject, existing preset/custom1–720minute duration.
No official exam/date/subject/key selectors, no auto scoring or ScoringAttempt.
Completion reuses immutable StudyRecord elapsed/segments/inclusion, and atomically
adds a separate local owner-space `free_practices` entry keyed by study UUID.
Manual score finite0..1000 is user-entered, not normalized/verified/graded. Editable
from completion or 자유 연습 기록; write failure retains old score and retry UI.

Persistence: additive optional field in existing v3 native atomic document,
serialized through StudyController; missing legacy field means empty. No SQL,
migration, StudyRecord server payload change or scoring RPC. Duplicate completion
is UUID-idempotent; same-device restart restores history, account switch isolates
it, existing owner purge removes it. No retroactive classification of old records.
Guest follows existing local Study lifecycle, not new login forcing.
Manual score stays out of `attempts`, MY score summaries, Mobile LAB and admissions;
raw time still follows include_in_study_total in canonical aggregation. Personal
score cross-device sync and full official catalogue remain **GAP_OPEN**.

Tests: device_followup_three_test covers real-metadata fixture selection/reset,
actual-option grouping, single/multi variants, free title/start/manual save,
restart/write-failure/owner-race isolation, no scoring outbox and include true/false.
Fixtures are test-only; no Production exam/subject/key inserted. Existing scoring
and grade suites preserve pinned/owner/idempotency/answer-safety regressions.

## End-of-day foundation and Phase2 gaps — 2026-09-24

MOCK: FOUNDATION / PHASE2 OPEN. UI V2 Owner acceptance is not Mock product
completion. Official uses actual canonical exam/subject/variant and published,
current verified key with existing pinned-version/owner/idempotency/stale/answer
safety. Free uses user title, duration, optional subject and local manual score;
no verified scoring or automatic official/admissions analytics inclusion.

OPEN / FUTURE: full official exam catalogue; complete year/grade/month browsing;
full answer-key catalogue; official selection UX completion; Free Practice custom-
time UX polish; free subject-level score structure; cross-device result history.
Existing custom duration and optional subject are implemented foundations, not
proof these later UX/data gaps are complete. No new keys, taxonomy or schema.
Mock Phase2 NOT STARTED today; resume only at Owner request. Next default priority
is [offline Daily Sync Phase1](daily-sync-phase-1-deterministic-delta-package.md),
not automatic Mock expansion or Daily Sync Phase2.
