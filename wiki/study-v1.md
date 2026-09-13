# Day 8 Study v1 — architecture and UI contract proposal

Reviewed: 2026-09-14. **Design approved; final migration package prepared; production application pending.**
Day 7 remains COMPLETE. This document defines approved behavior; no Study feature, package,
native permission, DB object or production deployment was implemented in this task.
Claude UI/UX review can refine presentation within these proposed data boundaries.

## Verified starting point

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
| 8-A first | General start/pause/resume/end, durable local session, completed cloud history, today/seven days, Home summary | Approve contract, owner migration, actual JWT acceptance, then implementation |
| 8-B | Optional focus environment and device-local preference | Native capability and restoration prototype; never blocks 8-A |
| 8-C | Preset/custom mock countdown, pause/resume/end/submit, local completion notification | Separate UI/platform acceptance after 8-A |
| 8-D later | Answer entry, scoring, results, grade provenance and explanations | Separate content/attempt design; no answer/cutoff table now |

## Storage choice: B recommended

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

Use an injected StudyClock and a transactional local store (SQLite recommended;
package/version selection is implementation work). Store schema version, fixed
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
   is not a portable restart clock. Reboot, unsupported continuity, corrupt draft,
   negative delta or inconsistent wall/monotonic anchors enters recoveryRequired.
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
local history and today's total. Label “이 기기에 저장”; uninstall loses it. It has
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

Proposed interfaces (not implemented):

- StudySessionController: start / pause / resume / finish / cancel / recover.
- StudyLocalStore: atomic draft + history + outbox transactions, scoped internally.
- StudyRepository: fetchCurrentSessions(window, cursor), saveCompletedSession(payload),
  deleteCurrentSession(id). The name saveCompletedSession covers completed snapshots,
  excluding cancelled work; callers never send owner/created_at/duration counters.
- StudySummaryProvider: one shared pure interval aggregator for Home and Study.
- StudySyncCoordinator: owner-scoped retry and merge, generation/request guards.

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
minute: “오늘 1분 미만 공부했어요.” Use completed records only for Home/summary;
running duration belongs to the central Study timer, with optional “공부 중” meta
and no second clock. Local pending completed work is included once with sync status.
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

## Focus capability and preference (8-B, not implemented)

Android: request Notification Policy Access contextually, open system policy-access
settings, then recheck isNotificationPolicyAccessGranted. OS/user denial must still
start the timer. Own AutomaticZenRule only; end/pause/cancel releases our rule,
resume rechecks consent/access. Do not restore an old global snapshot over changes
made by the user or another rule. On restart reconcile a stale own rule; rule expiry
and process-kill cleanup need physical-device proof before automatic integration ships.
Older API behavior requires a separate adapter; until safe own-rule lifecycle is
verified, offer manual settings guidance, not a global toggle fallback.
([NotificationManager](https://developer.android.com/reference/android/app/NotificationManager))

Android15 targetAPI35+ cannot globally turn DND off or replace global policy;
legacy setters affect an implicit rule and system combines policies. Therefore
ending our session cannot promise global DND is off. ([Android15 DND changes](https://developer.android.com/about/versions/15/behavior-changes-15#dnd-changes))

Apple's documented Focus Filters let an already activated Focus change app behavior;
they are not Focus activation controls. This design therefore treats general
third-party automatic global Focus/DND toggling as unsupported, not parity with
Android. iOS offers concise Control Center/manual Focus guidance; no private API,
settings deep-link guess or imitation “enabled” status. User-configured Shortcuts
can be investigated separately, not advertised as automatic app control.
([Apple Focus filters](https://developer.apple.com/documentation/AppIntents/defining-your-app-s-focus-filter))

Device-local preference: ask / always / never; “이번만” is ephemeral consent and
leaves ask for next session. Always is a preference, never proof of OS permission.
No profile column or cross-device sync. Expose reset in Study settings. On capable
Android first use offers 항상 자동 적용 / 이번만 / 사용 안 함 with a clear settings
handoff; do not repeat-denial-loop. iOS does not offer unsupported automatic choices:
use “집중 모드 설정 안내” / “안내하지 않음”, with timer continuing either way.
Account changes release our active focus rule; another account never inherits a
running rule. Preference remains device-level and explicitly editable.

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

## Acceptance plan and approval gate

See [storage proposal](day-8-study-storage-proposal.md) for exact SQL/catalog/rollback
and real JWT steps. Future tests must cover:

- Pure fake-clock: pause gaps, delayed callback, midnight, 7 zero days, overlapping
  devices and mode filters, fractional rounding, limit clipping, under1second,
  clock reversal/timezone shift, reboot/unproven continuity and256interval boundary.
- Durable store: crash before/after each atomic transition, corrupt/versioned draft,
  paused/running restart, end+outbox exactly once, failed disk write, offline/retry,
  duplicate/uncertain network success, local/server UUID merge and deletion retry.
- Auth: guest survives restart, no login import, A restore, logout/account switch,
  auth resolution/error, stale fetch/save, identity change between check and send,
  A pending queue inaccessible to B, token renewal without losing ownership.
- Widget: every state above at 360×640 and 2×, 48px actions, tabular figures, keyboard,
  screen reader, Home unset/recorded/running/pending/error and7-day zero/history.
- Real JWT: owner SELECT/INSERT/DELETE, forbidden column/UPDATE and cross-user
  denial, malformed segments/date/title/plan, retry idempotency and fixture cleanup.
- Real Android/iOS: screen lock, background, kill/restart, offline end/restore/sync,
  A/B isolation, Home refresh. 8-B access denial/revocation/user DND changes and
  crash cleanup; 8-C notification denial/reboot/pause rescheduling in separate gates.
- Implementation gate: flutter analyze/test, git diff --check, Android debug/iOS
  simulator builds plus physical-device lifecycle acceptance. Existing Day 7 tests
  and profile/school/D-Day contracts remain intact. None rerun as Study acceptance now.

Owner approved B/local durability, cancelled exclusion with no cloud cancellation,
KST/overlap-union summary, 24h/256interval and1min–12h bounds, Android capability
constraints/iOS manual guidance and local Focus preferences. Final migration is
prepared. Next: Owner preflight/apply/postflight, real JWT acceptance, then8-A
implementation. **STOP before production execution or Flutter implementation here.
Day8 is not COMPLETE.**
