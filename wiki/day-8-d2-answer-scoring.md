# Day 8-D2 — Answer Entry + Raw Score

**Implemented / runtime validation pending. Day 8-D2 is NOT COMPLETE.**
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
- Actual populated A/B Flutter scoring RPC, remote result restoration and account
  switching with controlled production fixtures remain **pending**. D1 Python JWT
  acceptance is separate evidence and does not substitute for this Flutter gate.
- Physical background/lock/kill/reboot remains a separate device gate. Native smoke
  reconstructs controllers against real platform storage/clock, not OS process kill.

Smoke entry: integration_test/mock_scoring_smoke_test.dart. Run with flutter test -d
an iOS simulator. Optional SCORING_LIVE_EMPTY_SMOKE=true plus the external public
Dart-define file performs a read-only real availability-empty check. It creates no
production fixture; the synthetic Guest branch always restores the original local file.
No production mutations, trigger changes, fixture publication, Push/PR/Merge.

Next: complete controlled A/B Flutter runtime before declaring D2 COMPLETE. Day8-D3
requires separate scope approval; do not start grade interpretation/analysis yet.

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

## A/B native Flutter scoring runner (prepared; Owner execution pending)

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
credential scan and git diff checks PASS. Actual A/B Flutter run remains pending;
Day8-D2 and Day8 overall are not marked COMPLETE.
