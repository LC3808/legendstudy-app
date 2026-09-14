# Day 8-C — Mock Exam v1 design

Reviewed: 2026-09-14. **Implementation complete; Guest/Auth Flutter runtime PASS; physical-device checks pending. Final COMPLETE on hold.**
Day 8-A remains COMPLETE; Day 8-B is implemented with physical acceptance pending.
Day 8 overall is NOT COMPLETE. This document supersedes earlier mock auto-completion
wording in Study v1. Implementation below adds Flutter/native behavior; no production
schema or migration change. Design sections remain the contract, with implementation
details and evidence explicitly distinguished below.

## Entry and setup

Study uses one compact `공부 타이머 | 모의고사` switch above the existing primary
content, not two stacked timer cards. Navigation to Home does not pause either mode.
Only one running/paused timer across both modes on this device. An active session
locks mode changes with `진행 중인 공부로 돌아가기`; end/discard explicitly before
starting another mode. An unconfirmed frozen mock must be confirmed/discarded before
another session for that owner; viewing other tabs remains allowed.

Setup contains title, optional subject, preset/custom duration and a primary start
button. `ready` is valid setup on the same screen, not another mandatory wizard page.
Trim title/subject before validation. Required title: 1–80 Unicode code points;
optional subject: blank becomes NULL, otherwise 1–40 code points. UI counters and
paste validation must match PostgreSQL char_length, not UTF-16 code units alone.
No silent truncation. Show inline errors and retain input. Subject is a free label.

| Preset id | Label / suggested subject | Minutes |
|---|---|---|
| korean | 국어 | 80 |
| mathematics | 수학 | 100 |
| english | 영어 | 70 |
| inquiry | 탐구 | 30 |
| custom | 사용자 지정 | 1–720, integer minutes |

These are practice conveniences, not an official CSAT timetable. Each preset has a
stable local id, display label, suggested subject and durationSeconds. Copy values
into setup; preserve a manually edited title/subject. Default title may be
`영어 실전 모의고사`, editable before start. A preset does not identify an exam in DB.
Custom input validates 1–720 minutes (DB 60–43200 seconds); shortcuts emphasize
normal exam lengths. Lock title, subject and plan after start. No timetable table.

At 360×640 and 2× text scale: scrollable keyboard-safe setup, switch labels can wrap,
controls >=48px, no fixed-height clipping. Countdown uses tabular figures and
textPrimary; restrained primarySoft accents, no alarm-red default. Running screen:
remaining time primary, title/subject and used/planned time secondary, pause/submit
below. Long labels wrap or ellipsize with accessible full labels. Actions stack at
large text. Home retains only the existing study aggregate, never another countdown.

## State and clock contract

Mock has its own presentation/controller state; general TimerPhase stays separate.
Reuse clock, integer active intervals, local storage transactions, record validation,
repository, outbox and aggregation through adapters, not a merged global enum.

| State | Transition / durable behavior |
|---|---|
| setup | Invalid/incomplete editable values; no timer |
| ready | Valid setup; start commits owner-bound draft before platform work |
| running | Clock advances; pause -> paused; submit opens confirmation |
| paused | Clock frozen; resume -> running; submit permitted |
| timeUp | Frozen intervals/end instant, no active segment; confirmation pending |
| submitting | Confirmed frozen payload being atomically committed locally |
| completed | Local completion committed; independent SavePhase local/saved/pendingSync |

RecoveryRequired remains a separate recovery gate, not an extra normal timer phase.
Frozen pending confirmation carries local reason `planElapsed`, `wallLimit`,
`accountChanged` or `recovery`; only planElapsed displays `시험 시간이 끝났어요.`.
For other reasons use a truthful stopped-session message, not a fake zero countdown.

Source of truth: stored UTC start + per-boot monotonic anchor + integer millisecond
active segments `[start,end)` relative to start. RemainingMs = max(0, planMs -
sum(active segments including the open one)). Render ceiling remainingMs/1000 as
HH:MM:SS, so zero means exhausted. The one-second ticker only refreshes the display.
Background/screen lock continue; pause closes the active segment, resume opens one.
Reuse same-boot continuity checks; wall-clock changes/reboot/uncertain continuity
require checkpoint recovery and never silently credit an unknown gap.

When the plan is exhausted, close at the exact logical instant that used active time
reaches planMs, even if the app resumes late. Persist timeUp and its frozen ended_at;
waiting for confirmation contributes no time and cannot change ended_at. A killed app
may persist this transition only on re-entry; calculate it from the existing durable
anchor rather than from notification delivery. Never call general end/auto-finish
at mock expiry: those methods currently create completed records and start upload.

Pause is allowed in v1 and keeps Focus. Pause time never counts toward plan/aggregate.
The 24-hour session-span bound includes pauses: clip at that boundary on next execution
and enter frozen confirmation with wallLimit, even if plan time remains. Do not
stretch a paused session beyond 24h. At 256 active segments refuse a further resume;
allow ending/discarding and a new exam. No zero-length or overlapping segments.
Recovery retain freezes at the last verified checkpoint for confirmation; discard
removes only this local draft. This differs from general Study automatic finalization.

## Time-up and submission

At timeUp show `시험 시간이 끝났어요.` and `시험 종료`; do not resume, auto-upload,
auto-grade or claim completion. That action opens `시험을 종료할까요?` confirmation.
Cancel stays timeUp. Early submit uses the same dialog; while open, a running exam
continues and a paused exam remains paused. Cancelling an early dialog returns to
its current state; if time expires meanwhile, it returns to timeUp, never running.

Confirm closes the current segment at confirmation time (or uses the already frozen
end), clamps to plan/span, and serializes exactly one terminal local transaction for
the session UUID. Simultaneous expiry, duplicate tap, lifecycle callback and retry
must converge on that payload. Submitting is a local-write state, not a network wait.
Local write failure retains frozen data with retry, no completed/saved claim and no
new timer until resolved. Cloud failure after local commit shows `동기화 대기`.
Less than 1000ms active work cannot satisfy DB: explain `1초 미만의 기록은 저장되지
않아요` and discard only on explicit confirmation. A separate secondary discard
confirmation excludes cancelled work from totals and cloud. Completion shows actual
used and planned time, not points or a score.

## Local persistence and account boundaries

Design a version-2 local envelope with discriminated general/mock draft. Mock carries
UUID, mode, title, optional subject, planSeconds, owner namespace, clock/checkpoint,
segments, phase, frozen end/reason and notification revision. Owner never comes from
presentation. These are local fields, not new database columns.

Atomic v1 -> v2 migration preserves all general drafts, records, pending retries and
UUIDs. Unknown/corrupt formats remain recoverable without destructive overwrite.
StudyDraft.finish currently defaults to study; mock completion must explicitly map
mode/title/subject/plan into the already-capable StudyRecord. Update shared native
Focus draft inspection together with the versioned reader: it currently recognizes
only running/paused JSON drafts. Test old snapshots rather than silently resetting.

On logout/account switch immediately hide old-owner data and invalidate async epochs.
Freeze a mock under its original owner at the switch instant (subject to continuity
and limits), cancel notification, reconcile Focus and retain it awaiting confirmation;
**do not reuse general Study's automatic completion on identity change**. On return
that owner can confirm/discard, not resume the frozen exam. Another owner can start
their own session; old responses cannot affect it. Guest results/drafts never migrate
to authenticated storage automatically. No other-account title appears in alerts.

Guest confirmed records persist on-device with `이 기기에 저장됨`. Auth completion
atomically transitions draft -> record/outbox, then reuses request-bound repository
and same-UUID idempotent retry/read-back. Sync status is independent of completed.
Do not add a second queue or introduce profile writes.

## Production storage and aggregate contract

Existing Owner-applied `20260914000100_study_sessions.sql` already supports this.
No migration/RPC is required. INSERT allowlist:
`id, mode='mock_exam', title, subject, planned_duration_seconds, started_at, ended_at,
active_segments`. UTC timestamptz boundaries; JSONB integer-ms segments. Never send
`duration_seconds`, `user_id` or `created_at`. DB generates duration from validated
segments; auth.uid() supplies ownership. Owner SELECT/INSERT/DELETE, no client UPDATE.
Completed records are immutable. No status, answers, score or grading fields added.

Bounds: finite end >= start, span <=24h, <=256 ordered nonoverlapping positive
segments within span; generated duration >=1s; activeMs <= planMs; plan 60–43200s;
trimmed title 1–80, optional subject 1–40. Store actual used time, retaining plan even
for early submission. Do not re-send name/grade/NEIS/D-Day or change content tables.

Home/today/7-day totals reuse bounded KST-window repository reads and interval union
across study/mock records. Split at KST midnight, fill missing dates with zero, union
cross-device overlaps and deduplicate UUIDs. Running/paused/frozen-unconfirmed work
is the current owner's local overlay, not a completed cloud record. Replace that
overlay atomically with the completed UUID once confirmed; no double counting.
Discard removes overlay. Home keeps ordinary total wording; Study identifies
`종료 확인 대기` so temporary local contribution is not described as synced history.
Existing pagination overflow/error handling remains; no unlimited history download.

## Focus and local notification

Reuse FocusService / StudyFocusController device-local ask/always/once/disabled flow.
Start timer before permission/settings handoff; denial/failure never blocks it. Pause
retains owned Focus; submit, discard, account switch and entering frozen timeUp request
owned-state cleanup. **Design choice:** release at timeUp as active study has ended,
not hours later when confirmation arrives. Never change the user's global DND state.
iOS remains manual guidance, not automatic Focus toggle. No preference cloud fields.

Day 8-B currently has no guaranteed OS cleanup after process kill. Reusing it does
not magically release an Android rule at a background deadline. Foreground/re-entry
must reconcile frozen states; a safe native deadline adapter may reconcile only the
matching owned session when invoked. Never assume a notification runs Dart or makes
cloud writes. Background/kill cleanup remains a physical acceptance item and must
be reported as a limitation if not proven; no promised exact DND expiry.

**Decision:** include best-effort local time-up notification in 8-C implementation;
receiving it is optional and must never gate timer operation. Use a setup option
`종료 알림` with contextual permission, not a forced start-time permission chain.
Text: `모의고사 시간이 종료됐어요.` No exam title/account information on lock screen.

Android13+ needs POST_NOTIFICATIONS for ordinary alerts; denial leaves countdown
working. [Official notification permission](https://developer.android.com/develop/ui/views/notifications/notification-permission).
Default Android scheduling is inexact and may be delayed in Doze. Exact-alarm special
access is **not required in v1**; no USE_EXACT_ALARM assumption, full-screen intent,
critical/bypass alert or battery exemption. A later exact-delivery requirement needs
separate capability review. [Official alarm scheduling](https://developer.android.com/develop/background-work/services/alarms).
iOS uses authorized UserNotifications scheduling/cancellation; it can present while
app is not running, subject to system settings/Focus. [Official local notification guide](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html).

Schedule remaining active time at start/resume with session UUID + revision; cancel
pending/delivered request on pause, early submit, discard and account switch. Serialized
scheduling plus revision checks prevent a late async schedule recreating a cancelled
alert. Reconcile after restore/reboot/permission change; uncertain clock -> cancel
until recovery. Foreground announces expiry once, no duplicate banner. Notification
tap opens the current owner's exam and recomputes state; stale/other-owner alerts
cannot restore someone else's exam. No auto-submit from an alert. Focus may silence
notification sound; do not promise audible delivery or bypass user choices.

## 8-D extension boundary

Keep mock session UUID as future attempt linkage; preset ids remain local conveniences.
Actual exams PK is exams.content_item_id, not exams.id. A future attempt can link an
exam content item and exam_subjects.id with same-exam integrity. Version answer keys,
question/point definitions, scoring rules and cutoff sources in a later reviewed
migration. Cutoffs retain expected/final status, source URL, publication/version,
cohort/subject and score scale; predictions must not be shown as confirmed grades.
Decide deletion/version semantics then; content resources are not structured answer
keys. Future path: timeUp -> answer editing locked -> confirmation -> grading.
Raw score, expected/final grade, wrong answers and explanation resource links are
future work. No speculative fields/tables or answer UI are created now.

## Implementation and acceptance plan

1. Unit tests: preset validation (including Unicode80/40), custom1/720 boundaries;
   monotonic countdown, pause gaps, late expiry, clock jump/reboot recovery, exact
   plan cap, 24h/256 boundaries, <1s, early dialog/expiry race and exactly-once confirm.
2. State/storage: v1 snapshot migration preserving general/outbox; running/paused/
   timeUp restoration; local failure retry; no upload before confirmation; guest
   no-auto-import; auth pending retry; logout/switch/stale responses; payload allowlist.
3. Aggregate: study+mock union, midnight KST split, empty days, frozen overlay ->
   record replacement and discard, unchanged Home hierarchy and bounded reads.
4. Widget: 360×640 and 2× text, keyboard, long title, each state, wrapped mode switch,
   >=48px actions, screen reader state announcement without per-second chatter.
5. Focus/notification fakes: failure does not block start; pause holds; timeUp/end
   release request; scheduling cancellation/revision races and no old-owner alerts.
6. Regression: existing Study/Focus/School/D-Day tests; flutter analyze/test,
   Android debug + iOS simulator builds and git diff --check during implementation.
7. Actual Guest/Auth smoke: start, pause/resume, early submit, expiry with delayed
   confirmation, restore, immutable cloud read-back, pending/retry, account isolation,
   unchanged profile/school/D-Day; delete only run-owned fixtures, retain Auth users.
8. Physical Android + iPhone: background/screen lock, same-boot kill/restore, reboot
   recovery, timeUp/frozen end, permission denied/revoked, delayed/missing alert,
   tap/cancel, Focus/manual guide, owned rule vs user's DND override, submit and restore.
   Document actual delivery/cleanup limitations; simulator tests do not close these.

At the design checkpoint, checks covered production migration/code alignment, links
and documentation diff only. Implementation and subsequent runtime evidence are
recorded below; physical Focus acceptance remains open.
No blocking Product Owner decision for design. Defaults chosen here: pause allowed,
subject optional, integer-minute custom limit, best-effort optional alerts, Focus
release at frozen timeUp. Guaranteed audible/exact alerts or strict no-pause practice
would be a later scope decision, not a silent promise in v1.


## Day 8-C implementation and evidence — 2026-09-14

- `study_models.dart`: separate MockPhase and validated MockSetup; shared StudyDraft
  has optional mock metadata and frozen reason/checkpoint. General TimerPhase enum
  unchanged. Stored frozen draft uses paused interval core + explicit frozen reason;
  presentation exposes timeUp, never resumable. Mock finish maps mode/title/subject/
  plan to existing StudyRecord. Duration is never sent to Supabase.
- `study_controller.dart`: single execution slot, configure/start mock, bounded active
  countdown, pause/resume, freeze then explicit end, short/discard exclusion. General
  end behavior preserved. Local-write failure keeps frozen memory for retry; disk
  failure cannot promise durability across process death. Auth epoch/request binding
  reused; departing mock stays frozen in original namespace without completion/upload.
- `study_local.dart`: recognizes envelope1/2. Controller validates all owners before
  atomic v1->v2 upgrade; file path stays study-state-v1.json for continuity. Existing
  records/outbox/UUIDs retained. Mock metadata is the discriminator; no second store.
  Notification schedule identity derives from session UUID + open-segment offset;
  serialized replace/cancel is the revision mechanism, not a new cloud field.
- `mock_exam_panel.dart` + Study page: compact mode switch, optional subject candidates,
  presets/custom, inline DB-compatible code-point validation, tabular dark countdown,
  confirmation/discard and compact used-time result. Buttons >=48px; large text stacks.
  Presets are practice values, not an official exam timetable. No answers or grading.
- `study_providers.dart`: existing Focus session observer excludes frozen/recovery;
  native owned-rule reader excludes frozen drafts. Start/permission flow reused;
  pause/resume do not reactivate. End/timeUp cleanup remains best effort on execution.
- `MockNotificationController`: optional adapter isolated from timer, serialized
  schedule/cancel. Pause/submit/account change cancel; foreground timeUp cancels.
  If already background when plan expires, retain the pending alert until foreground
  reconciliation so an inexact alarm is not cancelled before delivery. No cloud action.
- Android MockNotificationBridge/receiver: ordinary POST_NOTIFICATIONS, inexact
  elapsed-realtime AlarmManager, non-exported receiver checks run-owned current draft
  before generic notification. No exact-alarm permission/service. Reboot/force-stop
  scheduling is recovered only on app re-entry, not via a boot receiver.
- iOS AppDelegate: optional UserNotifications authorization and single replaceable
  local request. Generic notification tap opens the app; it does not deep-link to an
  old owner's exam or auto-submit. Current owner's Study tab restores the draft.
  No automatic system Focus toggle, critical alert or guaranteed audible delivery.

Verification:

- flutter analyze PASS; flutter test177 PASS (156 retained +21 new mock tests).
- Final Android debug and iOS simulator builds PASS. git diff --check, local Wiki
  links and actual publishable-key/secret/JWT scan PASS; migrations/proposals unchanged.
- New tests cover setup80/40 Unicode bounds,1/720-minute limits, both mode locks,
  pause/background/late expiry, exact ended_at, running/paused/frozen restore,
  recovery,24h/256/<1s guards, local-write retry, Auth pending/switch/stale isolation,
  KST union, Focus failure/cleanup, alert scheduling/cancellation,360×640/2× UI and
  running confirmation dialog cancellation/expiry. These mocks are not OS delivery evidence.
- Python runner2 offline tests/syntax PASS, including Mock marker allowlist and no
  passwords in Flutter arguments/output. Dedicated integration smoke uses the existing
  one-shot loopback/getpass runner with --mock; no secret fixture/config committed.
- iOS simulator Guest real native clock/storage PASS, stages:

```text
MOCK_FLUTTER PASS guest_start
MOCK_FLUTTER PASS guest_pause_resume
MOCK_FLUTTER PASS guest_running_restore
MOCK_FLUTTER PASS guest_time_up
MOCK_FLUTTER PASS guest_end_local
MOCK_FLUTTER PASS guest_home_restore
MOCK_FLUTTER PASS fixture_cleanup
```

The one-minute countdown actually elapsed; frozen state was reconstructed before
confirmation. Original local snapshot restored; this Guest run made no production
fixture. It does not prove physical lock/kill/reboot or real notification delivery.
## Owner-reported Guest/Auth Flutter runtime acceptance

Product Owner supplied the following final output after running the dedicated Mock
smoke. Stage names match `integration_test/mock_exam_smoke_test.dart` and the
`--mock` runner. This documentation update does not rerun tests or production requests.

```text
MOCK_FLUTTER PASS guest_start
MOCK_FLUTTER PASS guest_pause_resume
MOCK_FLUTTER PASS guest_running_restore
MOCK_FLUTTER PASS guest_time_up
MOCK_FLUTTER PASS guest_end_local
MOCK_FLUTTER PASS guest_home_restore
MOCK_FLUTTER PASS login_preflight
MOCK_FLUTTER PASS auth_save
MOCK_FLUTTER PASS auth_restore_home
MOCK_FLUTTER PASS account_isolation
MOCK_FLUTTER PASS pending_sync
MOCK_FLUTTER PASS pending_retry
MOCK_FLUTTER PASS profile_preserved
MOCK_FLUTTER PASS fixture_cleanup
MOCK_FLUTTER PASS auth_users_retained
Flutter persistence smoke: PASS
```

Day 8-C implementation complete. Guest/Auth runtime, cloud save/read-back/restore,
Home aggregate, account isolation and pending sync/retry PASS. The runner checks
saved mode/title/plan/generated duration/segments and unchanged profile/school/D-Day
snapshots. Fixture cleanup PASS: only run-owned Study UUIDs deleted and original
local snapshot restored; Auth A/B users retained. Existing Study rows stop preflight
rather than being deleted arbitrarily.

Restoration evidence is simulator/provider reconstruction with actual native storage
and real JWT/REST, not physical background/lock/Focus/local notification/kill/reboot
acceptance. Those physical-device checks remain pending. **Day 8-C final COMPLETE
is on hold until physical verification. Day 8 overall is not COMPLETE.**
Day 8-D Scoring starts only after separate Product Owner approval; no answers,
scoring, grade or schema implementation is included in this documentation closeout.

## Subsequent Day 8-D2 extension

[D2](day-8-d2-answer-scoring.md) now adds optional answer entry/raw-score flow when a
current scoring package exists. The original timer-only path remains. Paused/timeUp
answers are locked; submission persists an immutable attempt separately from Study.
D2 is implemented/runtime pending; this does not close the physical8-C gate.
