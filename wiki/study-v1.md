# Day 8 Study v1 — approved contract and core implementation

Reviewed: 2026-09-14. **Production migration and full A/B JWT acceptance PASS (Owner-reported).
Day 8-A Study Core = COMPLETE; Flutter Guest/authenticated runtime PASS (Owner-reported).**
Day 7 remains COMPLETE; Day 8 overall is not COMPLETE.
Day 8-B implementation and its pending physical-device gate are recorded in the Focus section.
[Claude review](day-8-study-ui-review.md) preserves the original and separates Owner overrides.

## Historical design starting point (superseded by implementation below)

Local branch codex/day-7-school-neis, starting commit
05a055310c321e06d9e87f3b4612e3c88c21d89a (historical inspection point, not permanent HEAD).
Tracked tree clean; existing untracked supabase/.temp/ is local CLI metadata.
Read AGENTS, index, current status, product scope, architecture, database, UI v1 and
design system before reviewing source and all three applied migration files.

- StudyPage is a StatelessWidget: static today empty text, 48sp 00:00:00, disabled
  start button and empty seven-day region. No timer repository/controller/storage.
- Home has the approved study title/action row with static empty body.
- StatefulShellRoute.indexedStack preserves tab navigation. AuthStatus exposes user
  identity, not tokens. School/D-Day controllers already guard identity changes and
  stale async responses; their repositories send narrowly scoped profile fields.
- Migration inventory has content and profile contracts, no Study storage. Day 7
  deployment/JWT/runtime acceptance is owner-reported and recorded in current-status.
  No production catalog or runtime call was made in this design task. Preflight must
  confirm actual production state before any approved deployment.

## Delivery boundaries

| Stage | Scope | Gate |
|---|---|---|
| 8-A first | General start/pause/resume/end, durable local session, completed cloud history, today/seven days, Home summary | COMPLETE: migration/postflight, real JWT and Flutter runtime accepted |
| 8-B | Optional focus environment and device-local preference | Native capability and restoration prototype; never blocks 8-A |
| 8-C | Preset/custom mock countdown, pause/resume/end/submit, local completion notification | Separate UI/platform acceptance after 8-A |
| 8-D later | Answer entry, scoring, results, grade provenance and explanations | Separate content/attempt design; no answer/cutoff table now |

## Storage choice: B approved

| Choice | Benefit | Cost / failure boundary |
|---|---|---|
| A: cloud running row with accumulated time/running_since/status | Another device can discover an active session | Pause writes need offline queue/order/versioning; concurrent devices need conflict ownership; guest needs another mechanism; timestamp alone cannot reconstruct pause distribution |
| B: durable local execution, terminal immutable cloud snapshots | Same local timer for guest/auth; no network dependency while studying; atomic local end/outbox | Active session is device-bound; uninstall/device loss can lose unsynced work; no live handoff across devices |

Choose B for v1. Cloud receives completed records only, never
running/paused heartbeats. One active session across both modes per device. Different
devices may run independently; completed history syncs, live timers do not.
Do not advertise backup before upload acknowledgement. This is self-reported study
tracking, not exam proctoring: interval validation prevents inconsistent counters,
but cannot prove a user actually studied or prevent a malicious client fabricating
an internally valid interval list.

## Local clock, state and durable transitions

Use an injected StudyClock and atomic local store. The initial design recommended
SQLite; 8-A uses native atomic file replacement to commit the single draft/history/
outbox document without adding a database dependency. Serialized writes cover all
owners. This is an intentional implementation choice, not volatile preferences. Store schema version, fixed
session UUID, immutable owner namespace, mode/title/subject/plan, UTC start anchor,
monotonic anchor and recovery metadata, state, closed active intervals, open interval
start, last durable checkpoint, final payload and outbox status. No JWT in this store.
Do not rely on preferences, Riverpod memory, widget disposal or a final lifecycle
callback for session durability.

1. Start writes a durable draft before showing running. Serialize commands; duplicate
   start/end taps cannot create another UUID. Failure to write locally keeps prior
   state and offers retry. UI ticker only requests a redraw.
2. Logical elapsed since session start comes from a continuous monotonic clock,
   including background/lock. Active elapsed is the sum of closed intervals plus
   the open interval. Pause closes it; resume opens another. Never add one second
   per timer callback; pause gaps are excluded from study duration.
3. Record integer millisecond half-open intervals [startOffset, endOffset) relative
   to logical started_at. Example [[0, 60000],[120000, 180000]] = 120 seconds of work
   over 180 seconds of wall span. Pauses do not require a separate event table.
4. UTC calendar anchor + monotonic offset defines a stable session timeline. A wall
   clock/timezone change does not alter accrued duration. Clock anomalies prompt a
   recovery review rather than silently re-dating or inflating time. New sessions
   use a new anchor. No security claim for client clock accuracy.
5. Atomic checkpoints on start/pause/resume/end and every 30 foreground seconds;
   lifecycle checkpoints are best effort. Open interval persists, so same-boot
   process death need not lose uncheckpointed running time when clock continuity
   can be established. Paused restart remains paused.
6. Adapter must prove monotonic continuity across process restart (public per-boot
   source + platform recovery metadata). A serialized Dart Stopwatch/Swift Instant
   is not a portable restart clock. Reboot, unsupported continuity, negative delta or inconsistent wall/monotonic anchors enters recoveryRequired.
   Show last verified duration: “시간 기록을 확인해 주세요”; retain up to last
   checkpoint or discard, with explicit choice. Never auto-credit uncertain gap.
   Choosing retain closes the session at that checkpoint before a new one starts.
7. Proposed product bounds: 24 hours total session span including pauses, at most
   256 active intervals, mock plan 1 minute–12 hours. Auto-finalize at the 24-hour
   boundary (on next execution if suspended), clipping the open interval. At interval
   limit ask to finish before another resume. These are approved v1 product/storage limits,
   not OS constraints or official exam limits.
8. End freezes elapsed once, atomically stores terminal payload + outbox, removes
   active draft, then attempts upload. Failed upload never restarts the timer or
   discards time. New session may start after local commit while retry remains queued.
   Under-one-second records are discarded locally; cancelled records may be zero.

Android elapsedRealtime includes deep sleep and wall-clock time may jump; it is the
appropriate elapsed-clock basis ([SystemClock](https://developer.android.com/reference/android/os/SystemClock)).
iOS continuous clocks advance during sleep ([ContinuousClock](https://developer.apple.com/documentation/swift/clock/continuous));
public [Mach continuous time](https://developer.apple.com/documentation/kernel/mach_continuous_time)
is a candidate bridge for persisted numeric anchors. Validate minimum OS support,
boot-continuity detection and physical-device restart behavior before claiming
reliable automatic restore. No always-running background service is needed for
arithmetic; OS suspension does not promise callback execution.

## Guest, account ownership and cloud repository

Guest namespace is installation-local and durable across process restarts, with
local history and today's total. Label “이 기기에 저장됨”; uninstall loses it. It has
no cloud persistence and is not Supabase anonymous Auth. Guest records never auto-upload
when login occurs. Cloud accounts and guest storage are separate namespaces.

Capture ownership at start from current authenticated SDK session in the data/use-case
layer; presentation receives no user_id parameter. On logout/account switch, close
and locally queue the old owner's active interval at transition time, clear visible
old-owner state immediately, and cancel old fetch/subscriptions. Auth-A pending rows
remain inaccessible to B/guest, resume upload only after A login, and never acquire
B ownership. Guest active work closes into guest history on login, never into A.
Auth loading/error is not equivalent to a deliberate logout: block new cloud commands
and show resolving/error state without misclassifying a known owner's draft as guest.

Implemented 8-A interfaces (controller also coordinates summary and sync):

- StudyController: start / pause / resume / end / recover / sync; owner epoch and
  serialized local mutations, separate TimerPhase and SavePhase.
- StudyLocalStore: native read/write of atomic versioned draft/history/outbox document.
- StudyRepository: insertCompleted / fetchWindow / deleteOwn. Current-session owner
  is captured in the repository; immutable INSERT has no UPDATE API.
- studyWeek: pure union/split function used by Home and Study through one controller.

Before every network dispatch ensure draft owner still equals current SDK user.
Supabase INSERT omits user_id, deriving it via DEFAULT auth.uid(); caller cannot
insert that column. SELECT/DELETE also filter current owner in addition to RLS.
An auth change racing dispatch can otherwise assign an A draft to B via the default:
use a request-scoped SDK auth context captured for A (not a mutable global client's
new B token), then reject/ignore completion if generation changed. Never log/copy
that request token to application state. Tests must switch accounts exactly between
identity check and HTTP send. Revoked/expired identity leaves A outbox queued.

Fixed UUID is generated once locally. INSERT uses ignore-duplicates (DO NOTHING),
never merge-upsert/UPDATE. After a timeout or conflict, fetch that UUID and compare
all canonical payload fields (normalized instants and segments) and derived duration.
Only identical owner row counts as synced. Different/invisible row means conflict,
not success. Merge local/server history by UUID; queued records show “동기화 대기”,
not cloud-saved. Delete removes only that owner row and cancels its queued retry so
it cannot resurrect; deletion UI is optional later, contract supports cleanup.

Fetch on login, app foreground and successful upload; paginate the whole requested
window (started_at, id cursor), with a 2,000-record bound and explicit overflow
error as defined in the final storage contract; never publish partial totals.
Cloud cache/error must be distinguishable from actual zero history. Epoch guards
apply to fetch, upload, deletion and aggregate completion, not only one provider.

## Home and seven-day aggregation

Home retains “나의 공부 시간 / 학습으로 이동”, 48px action and compact row. Empty:
“오늘 공부 기록이 아직 없어요.” Recorded: “오늘 1시간 42분 공부했어요.” Under one
minute: “오늘 1분 미만 공부했어요.” Include completed records and the current draft
active portion in both Home and Study totals (Owner override). Home keeps a summary,
not a duplicate seconds clock. Local pending completed work is included once with sync status.
Cancelled sessions may stay only in local history as “취소됨”, excluded from totals; regular 공부
종료 means completed, not cancelled. Explicit discard requires confirmation.

v1 date grouping is Asia/Seoul (KST), matching Day 7 meals; travel does not silently
regroup existing history. Store instants in UTC. Seven days means today plus six
preceding Korean calendar dates, zero-filled, today emphasized; date rollover and
foreground trigger refresh. Include records overlapping the window, not merely
started inside it. With the 24-hour bound, fetch start >= windowStart-24h and
start < windowEnd then filter actual segment intersections. Old outbox insertion
requires a fresh query on foreground; pagination is not a concurrent snapshot claim.

Convert each active interval to UTC instants; intersect with each day's [midnight,
nextMidnight). Union overlapping intervals across devices/records before sum for
**total** so simultaneous sessions do not double-count a person's elapsed time.
Mode filters union within their mode; overlapping study/mock totals are not additive
and must not be shown as a stacked breakdown. v1 shows combined total first; optional
mode-filter view explains overlap. Duplicate UUIDs are removed before aggregation.
Sum integer milliseconds, then floor only for displayed seconds/minutes. Weekly
value derives from milliseconds, not rounded daily/session labels (rounding can
cause at most small display differences). Bars have text equivalents, no chart-only
information. 23:50–00:20 with pause23:55–00:05 yields5min firstday+15min nextday.

## Mock exam and scoring boundary

Reuse mode=mock_exam; require title and planned_duration_seconds; optional subject
is a display label, not a taxonomy FK. Presets Korean80/math100/English70 minutes
are proposed editable conveniences, not a verified official exam schedule. Custom
name/subject/limit supported. Keep mode/plan fixed once running; switching requires
finish/cancel confirmation. Local presets can later become versioned catalog data.

Countdown = max(0, planMs-activeMs); explicit pause is permitted in this practice
mode, background/lock is not a pause. At zero close active interval exactly at the
limit even if callback resumes late. 제출 completes early and freezes used time;
it does not submit answers or score. 종료 offers “기록 저장” (completed) or “취소”
(cancelled, excluded). Zero-active submission yields no completed record. Finished
UI shows used/planned time and completion, with no score/grade claim. A local finish
reason (submit/limit/manual/cancel) can drive wording; cloud v1 stores only completed records, without status or submitted booleans.

Actual exams PK is **exams.content_item_id**, not exams.id. exam_subjects.id is the
occurrence PK with content_item_id FK and unique(id, content_item_id). v1 custom
sessions deliberately have no exam FK. Later mock_exam_attempts can reference a
study session and optional exam_content_item_id + exam_subject_id with a composite
same-exam FK. Decide deletion/version semantics in that migration; do not guess an
exam_id field now. Content resources are attachments, not structured answer keys.

Future exam_questions/key versions, points, mock_exam_answers, immutable scoring
results and grade_cutoffs must be separate. Results pin question/key/scoring-rule
versions. Cutoffs need expected/final status, official/source URL, publication/version
and applicable cohort/subject/score scale; predictions cannot masquerade as final.
Wrong-answer links resolve existing resources by occurrence. No scoring schemas,
answers, cutoffs or ingestion added to the present proposal.

## Day 8-B Focus / DND — implemented, physical-device acceptance pending

Current local Android compile/target SDK35, minSDK21 (FlutterExtension used by
app/build.gradle.kts). No SDK target downgrade, private API or third-party DND package.

| Platform | Implemented capability | Evidence boundary |
|---|---|---|
| Android API29+ | Notification Policy Access + app-owned AutomaticZenRule condition | Build and mocked/JVM logic tests; actual DND physical-device test pending |
| Android API21–28 | Manual quick-settings guidance; stopwatch works | No global-filter fallback or deprecated provider-service implementation |
| iOS | Optional Control Center / Settings > Focus guidance | Simulator guide/preference/timer PASS; physical iPhone flow pending |
| Other/unavailable bridge | Unsupported; timer starts without Focus | Failure paths covered by Flutter tests |

Android's [NotificationManager API](https://developer.android.com/reference/android/app/NotificationManager)
provides ownership-scoped rule operations and policy-access checks. Condition updates
can be overridden by user actions; a successful request does not prove global DND.
[Android15 behavior](https://developer.android.com/about/versions/15/behavior-changes-15#dnd-changes)
requires target35+ apps to avoid changing global DND state/policy. This app never calls
global setInterruptionFilter/setNotificationPolicy or restores a global snapshot.
[AutomaticZenRule](https://developer.android.com/reference/android/app/AutomaticZenRule)
allows a null service owner with a configuration Activity for the API29 condition
approach. StudyFocusSettingsActivity supplies that declared, exported information
surface. Only ACCESS_NOTIFICATION_POLICY is added; no notification listener/content
reading, telemetry, exact-alarm or background service permission.

The one stored rule ID must match our configuration Activity and condition URI;
NotificationManager also checks ownership. It uses INTERRUPTION_FILTER_PRIORITY with
inherited priority policy, leaves user-disabled rules disabled, and sends STATE_TRUE
once per consented session. No repeated activation on pause/resume or background.
End, discard/recovery, account switch or expired/missing draft sends STATE_FALSE only
for an activation lease recorded by this app. The rule itself is retained for next
use; user overrides remain authoritative. UI says 연동 요청, never guarantees all
notifications are blocked or global DND is off afterward.

### Local preference, start and permission flow

`ask / always / disabled` are device preference values. Android first start asks
`집중 모드를 사용할까요?` with `항상 사용 / 이번만 / 사용하지 않음`.
Once is not persisted; always attempts on subsequent starts. Disabled bypasses Focus.
A small `집중 설정` action changes the next-start choice. No large Focus card.

After selection, the Study timer is durably committed **before** any OS settings
handoff. Focus activation then verifies the same durable draft UUID. Local timer
failure creates no Focus activation. Focus failure/denial/unsupported/timeout cannot
undo or prevent a successful Study start. Closing the first-choice dialog skips
Focus and starts the timer. Native operations have bounded waits; no wait for the
user to return from system settings, and duplicate start taps are guarded.

Explicit always/once with missing access opens the official
[Notification Policy settings](https://developer.android.com/reference/android/provider/Settings#ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).
On return, access is rechecked once and activation is limited to that same session.
Denial never loops the permission screen. Later automatic always attempts with no
access show a short message; explicit `알림 권한 설정` remains in settings. Revocation
retains any owed cleanup metadata for a later permitted retry and never stops Study.
Account switches discard pending permission activation but keep the device preference.

Android uses study-focus-v1 SharedPreferences (preference, owned rule ID and lease).
The file is excluded from cloud backup and device transfer through the two supported
[Android backup rule formats](https://developer.android.com/identity/data/autobackup).
iOS uses an atomic Application Support/StudyFocusLocal/preference.txt file with
[isExcludedFromBackup](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup).
No Focus fields enter Supabase, profiles, Study cloud payloads or analytics.

### iOS capability

Apple [Focus filters](https://developer.apple.com/documentation/appintents/defining-your-app-s-focus-filter)
change app behavior for the current system Focus; they are not a public general
system-Focus activation API. Implementation therefore offers manual guidance only,
with no automatic toggle, false active label or private Settings URL. First-start
choices are 안내 건너뛰고 시작 / 다시 안내하지 않고 시작. Both start Study. The small
settings action can restore guidance. There is no Android-style always-auto choice.

### Lifecycle and next-mode reuse

**Latest Owner policy overrides the earlier design:** pause/resume keep Focus;
only terminal session changes release the app's activation. Timer accounting code
is unchanged. study_providers observes draft identity/readiness/recovery and feeds
StudyFocusController; focus exceptions never flow into StudyController transitions.
FocusService isolates native capability/request/reconcile methods. 8-C can call the
same start coordinator and session observer rather than build another DND adapter.

The native activation lease includes session UUID and a24h wall deadline. Restart
reconciles it with a verified local running/paused draft; unknown/recovery/missing
or other-account draft requests owned deactivation. **No alarm/foreground service
runs after process kill. A stale rule may remain until app re-entry, even beyond the
deadline.** No claim of automatic force-stop/reboot cleanup. The settings UI asks users
to check device DND after force-closing. This is a physical-device acceptance/release
limitation, not a reason to globally turn off user DND or hide the risk.

### Validation and remaining gate

- Analyze PASS;156 Flutter tests PASS (134 preserved +22 Focus cases): preference,
  denial/grant/revocation/failure, no repeated settings, stale return/activation,
  pause/resume/end/account/recovery, iOS no activation,360×640/2× and48px targets.
- Android JVM2 lease-policy tests PASS; these test decisions, not OS permission or
  effective DND. Android debug and iOS simulator builds PASS. Diff/credential/scope
  checks PASS; no schema/migration changes.
- iOS simulator native smoke PASS: guide_skip_timer_start, no_system_activation,
  device_preference_restore, local_cleanup. Original local Study/preference restored.
- Existing Day 8-A Guest native smoke rerun PASS with the iOS guide: start/pause/resume,
  running restore, local completion, Home and original snapshot cleanup. No Auth/DB mutation.
- No Android device or configured emulator available. Android physical first-start,
  all choices, permission request/denial/revocation, real priority DND, pause/resume/end,
  existing user/other-rule preservation, manual overrides, process-kill/restart and
  backup/transfer behavior remain unverified. iPhone physical guidance flow also pending.
- **Day 8-B implemented, NOT COMPLETE.** Day 8-A remains COMPLETE; Day8 overall not
  COMPLETE. 8-C design can reuse the interface; do not treat physical Focus acceptance
  as passed or implement mock UI/notifications/scoring in this task.

## Completion notifications (8-C)

Local scheduled notification is recommended for mock time-up outside the app, not
required for 8-A stopwatch and not server push. Ask contextually; denied permission
means timer remains correct but no promised background alert. Schedule by session
UUID/revision, cancel on pause/end/account switch and reschedule on resume. Reconcile
on restart/reboot; stale callbacks cannot finish a different session. OS force-stop,
revoked permission, Focus and delivery delays prevent guaranteed audible exact time.

Android exact alarms need capability/permission checks; select SCHEDULE_EXACT_ALARM
only after 8-C delivery requirements review, do not casually assume USE_EXACT_ALARM
eligibility. Reboot requires scheduling recovery. No alarm runs the timer counter.
([Android alarm scheduling](https://developer.android.com/develop/background-work/services/alarms))
Apple UserNotifications can deliver scheduled local notifications while app is not
running, with authorization and system presentation constraints. No background Dart
loop or critical-alert entitlement assumption.
([Apple local scheduling](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app),
[notification authorization](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications))

## UI/UX review specification

Keep existing brand/system font, textPrimary contrast and restrained primarySoft;
no orange small text on white or urgent red countdown by default. Timer is primary,
today's total secondary; recent seven days/history lower. Use tabularFigures, default
48sp timer and no fixed-height clipping. At360×640/2× scale, permit vertical scroll
and wrap actions to full-width rows instead of shrinking accessible text. Targets
>=48×48, labelled controls and logical focus order. Screen reader announces state
changes; avoid reading every second. Mock expiration announcement once only.

| State | Main content/actions | Persistence/accessibility behavior |
|---|---|---|
| idle | 00:00:00, 공부 시작; today + recent7days | Start disabled only during local restoration, not for guest |
| running | elapsed; 일시정지 / 종료 | Navigation allowed; mode controls locked; explicit running label |
| paused | frozen elapsed; 계속하기 / 종료 | Secondary 일시정지; no time accrual |
| ending | frozen elapsed; 저장 중 | Disable duplicate terminal actions until local transaction resolves |
| save success | elapsed summary, 새 공부 시작 | Auth synced or guest 이 기기에 저장; successful state announcement |
| save failure | recorded duration, 재시도; concise cloud failure | Local success shows 동기화 대기, never cloud success; local write failure retains recoverable ending state |
| guest | small 이 기기에 저장 meta | No forced login and no auto-import on later login |
| authenticated | current-owner restored totals, unobtrusive sync/error | Loading/error is not empty; no old-account flash |
| mock idle | preset/custom name, subject, limit; 시험 시작 | Validate fields; keyboard-safe scroll; no scoring controls |
| mock running | remaining countdown, used/planned secondary; pause/end/submit | Submit confirm if early; background continues; mode fixed |
| mock finished | 종료/제출 완료, used/planned; 다시 시작 | Not a score; exactly-once local finalization and retryable cloud sync |
| recoveryRequired | last verified duration and 간격 확인 안내 | Retain checkpoint or discard; no unverified time credit |

Recent history rows: title fallback 공부, Korean date, duration, mode and cancelled/
pending meta. Fetch failure preserves available cache with retry. Starting another
timer is not blocked by unrelated history network errors. Home retains approved
row hierarchy; no new large focus/permission section above the timer.

## Day 8-A implementation and verification (2026-09-14)

Implementation files: `features/study/domain/study_models.dart`,
`data/study_local.dart`, `data/study_repository.dart`,
`application/study_controller.dart`, `study_providers.dart` and `presentation/study_page.dart`.
Home only changes its existing summary body. Native bridge is in MainActivity/AppDelegate.
Four presentation widgets cover page/flat summary, timer, controls and seven days.
No dependency, schema/migration, profile, NEIS, D-Day or route additions.

Local storage is Application Support on iOS (atomic write, protection until first
unlock) and app files on Android (AtomicFile). Draft + completed outbox are one atomic
commit. Namespaces are guest or current-user UUID; tokens/passwords are never stored.
The single file is an app-internal serialization format, not an encryption claim.
Corrupt/unsupported file or malformed draft reports local read error and blocks new
starts without overwriting the file; repair/export UI remains follow-up. Clock
uncertainty has explicit keep-last-checkpoint/discard actions. No unverified gap credit.

Android elapsedRealtime + boot count and iOS mach_continuous_time + boot metadata
check same-boot elapsed continuity and wall/monotonic drift. If boot metadata is
unavailable, a per-process nonce keeps same-process timing functional and forces
confirmation across process restart; it never claims cross-restart continuity.
Android BOOT_COUNT is available from API24 ([official reference](https://developer.android.com/reference/android/provider/Settings.Global#BOOT_COUNT)). Start/pause/resume/end
are durable; running checkpoints every30s. Idle date refresh every30s while mounted;
foreground triggers clock/history refresh. Background callbacks are best effort;
24h cap finalizes at the boundary on the next execution. 257th active interval is
prevented, under1s is not uploaded. Known draft can pause/end while Auth resolves;
new starts cannot accidentally assume guest ownership.

Completed cloud writes contain id,mode,title,subject,planned_duration_seconds,
started_at,ended_at,active_segments only. UUID retries use ignore-duplicates + full
payload read-back, never UPDATE. Bound request token prevents A→B dispatch reassignment.
Expired token leaves pending work for retry after a valid session. On account change,
old draft closes into its original local namespace; guest is never auto-uploaded.
Cached totals are labelled stale on refresh failure; initial unreadable cloud history
is not shown as zero. Overflow has no numeric total. Local retention is not capped;
large-history compaction/SQLite migration and deletions UI are later work. The repository
DELETE is available for owned records/testing; no history-delete UI exists in8-A.

Validation at implementation: analyze PASS,134 Flutter tests PASS,Android debug/iOS
simulator builds PASS,18 Study Python offline tests PASS,syntax/credential scan/diff
checks PASS. These checks were not rerun for this documentation-only closeout.

## Day 8-A runtime acceptance — COMPLETE

Owner reports the following full real Flutter smoke result. Stage names match
`integration_test/study_core_smoke_test.dart` and the safe-output runner
`tool/run_study_flutter_smoke.py`; no credential or raw response is recorded here.

```text
STUDY_FLUTTER PASS guest_start
STUDY_FLUTTER PASS guest_pause_resume
STUDY_FLUTTER PASS guest_running_restore
STUDY_FLUTTER PASS guest_end_local
STUDY_FLUTTER PASS guest_home_restore
STUDY_FLUTTER PASS login_preflight
STUDY_FLUTTER PASS auth_save
STUDY_FLUTTER PASS auth_restore_home
STUDY_FLUTTER PASS account_isolation
STUDY_FLUTTER PASS pending_sync
STUDY_FLUTTER PASS pending_retry
STUDY_FLUTTER PASS profile_preserved
STUDY_FLUTTER PASS fixture_cleanup
STUDY_FLUTTER PASS auth_users_retained
Flutter persistence smoke: PASS
```

Production Study migration is Owner-applied; Postflight and full real JWT acceptance
PASS. Flutter Guest and authenticated runtime PASS, including cloud save/read-back,
restored Home aggregate, account isolation, simulated pending sync and successful
retry. Read-only before/after profile snapshots cover display_name,grade_level,
NEIS school pair and D-Day pair: preservation PASS. Run-owned fixture cleanup and
local snapshot restoration PASS; Auth users retained. No production mutation was
performed in this documentation-only closeout.

**Day 8-A Study Core = COMPLETE. Next: Day 8-B Focus / DND. Day 8 overall is not COMPLETE.**
Restore evidence is provider/controller reconstruction with real native storage;
physical Android/iOS lock/background/process-kill/reboot and actual OS process-restart
Auth restoration remain platform follow-up acceptance, not claims of this smoke.
These limits do not reopen the Owner-accepted Day 8-A milestone.

Day 8-B now implements Android capability-based DND/focus, first-use choices
`항상 사용 / 이번만 / 사용 안 함`, and device-local preference. Permission denial or
feature failure must not block timer start. iOS will not claim automatic system Focus
toggling. Distinguish platform capabilities using official APIs as specified in the
Focus section above. That Day 8-A closeout introduced no Focus code. Day 8-B implementation and pending
physical-device gate are recorded above; mock UI/notifications/scoring remain future.
