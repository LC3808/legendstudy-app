# Home Personalization and Event Collection — Architecture Audit

Status: **PLANNED / FOUNDATION DESIGN ONLY — 2026-09-25**

This document records the audited foundation for two future product tracks:

- Multi D-Day as an event collection that can later power Home, List and Calendar.
- Role-based Home customization as a presentation preset, never an authorization
  or product-permission model.

No Flutter feature, schema migration, Supabase mutation, notification, Calendar,
Admissions engine or analytics implementation is authorized by this document.

## Current implementation audit

### D-Day

The current model is `DayTarget` in
`lib/features/home/domain/day_target.dart`:

- `date` is normalized to a calendar date and displayed with Korean calendar-day
  arithmetic through `koreanCalendarDay()`.
- `label` is trimmed, non-empty and limited to 80 Unicode code points.
- `description()` distinguishes future `D-n`, today `D-DAY` and `지난 일정`.
- There is no id, event type, pin, ordering, creation time or update time.

`DayTargetRepository` has exactly one fetch/save/clear target contract. The
Supabase implementation in `lib/features/home/data/supabase_day_target_repository.dart`
stores only `profiles.target_date` and `profiles.target_label`, scoped to the
authenticated user. It verifies the returned row and preserves unrelated
profile/school fields. The applied storage contract is documented in
`wiki/day-7-dday-storage-proposal.md`.

`DayTargetController` returns null for a Guest because there is no owner. A Guest
can edit the in-memory provider value during the session, but it is not account,
device or cross-device persistence. Authenticated users have account persistence.

`DayTargetCard` is rendered directly by `HomePage` and opens `_TargetDialog` for
one target. The current date picker prevents creating a new past date, while an
existing target remains visible as `지난 일정`; stored data is not automatically
deleted. Coverage exists in `test/day_target_test.dart` and
`test/day_target_persistence_test.dart` for validation, KST day calculation,
Guest/session behavior, save/clear, account isolation and profile-field
preservation.

### Current Home modules

`lib/features/home/presentation/home_page.dart` currently constructs these
sections in order:

| Module | Current evidence | Future classification |
|---|---|---|
| Greeting / identity | `HomeGreeting`, profile nickname when authenticated | FIXED shell/header |
| D-Day | `DayTargetCard` | CUSTOMIZABLE |
| Study summary | `_HomeStudyCard`, `studyControllerProvider` | CUSTOMIZABLE |
| Meals | `HomeMealCard`, school/meal providers | CONDITIONAL + CUSTOMIZABLE |
| Materials search / quick filters | `_HomeSearch` and content-type chips | FIXED discovery |
| Recent materials | `PersonalMaterialList(recentViews, homeMode: true)` | CUSTOMIZABLE, auth-scoped data |
| Recent updates | `HomeRecentUpdates`, bounded content provider | CUSTOMIZABLE |
| Notification slot | non-interactive planned icon only | FUTURE / not implemented |
| Five-tab navigation | `NavigationShell` | FIXED; never customizable |

This is an audit of actual composition, not a claim that future scores, insights,
achievements or notifications exist. Today the child providers are mounted by
the Home tree; future customization must compose only enabled modules so hidden
meal/material/analytics providers do not issue unnecessary work.

## Multi D-Day architecture

### Canonical event model

The long-term source record should be one owner-scoped event collection, not
`dday1`, `dday2` columns and not a second Calendar table.

Conceptual minimum:

| Field | Policy |
|---|---|
| `id` | Stable event identity, preferably UUID |
| `owner_id` | Canonical `auth.users.id`; never client supplied |
| `title` | User text, bounded and sanitized; not a default analytics dimension |
| `event_date` | Calendar date in the product's KST date contract |
| `event_type` | Small structured category, with `other`; not an authorization role |
| `is_pinned` | MVP boolean; at most one active pin per owner |
| `display_order` | Optional future user order; do not require drag reorder in MVP |
| `created_at` / `updated_at` | Operational timestamps, not event occurrence time |

`event_date` is the occurrence date. `created_at` and `updated_at` must not be
used to calculate D-n or replace the user's event date. If an event is later
linked to an admission/application record, the event remains a presentation
record with provenance rather than becoming authoritative application state.

### Event type policy

`event_type` is useful for display, filtering, future notifications and aggregate
analytics, but it must not become a large rigid admissions enum in the first
schema. MVP should use a versioned, small taxonomy such as:

`exam`, `school`, `admissions`, `personal`, `other`.

The UI may offer labels such as 중간고사, 수행평가, 모의고사, 수능, 논술,
면접 and 합격 발표. These can map to the small category or a later taxonomy
version. Admissions-specific lifecycle/status belongs to the future Admissions
domain, not to D-Day MVP.

### Home representative policy

Home must not render the full collection. Recommended deterministic order:

1. The owner's pinned event, if one exists.
2. Otherwise the nearest event with `event_date >= today`.
3. If no current/future event exists, use a future-reviewed UX choice: compare
   continuing to emphasize the most recent past event as a history state with
   prompting “다음 일정을 추가해보세요”. This audit does not force either
   behavior.

The card shows one representative event and a compact `외 N개 일정` affordance
to the event list. A pinned past event remains stored and visibly marked as past;
pinning is an explicit user override, not automatic deletion or silent replacement.
The list can separate upcoming/today from recent past while older events remain
recoverable.

MVP permits one pin. A future invalid multi-pin state must resolve
deterministically (pinned, then earliest date, then stable id) and should be
repaired only through an explicit reviewed write, not silently during rendering.

### Management UX

```text
Home D-Day card
  ├─ 대표 일정: 수능 · D-120
  └─ 외 3개 일정 → 나의 일정

나의 일정
  ├─ [+ 일정 추가]
  ├─ 수능       대표 · 2027.11.18       [수정]
  ├─ 수행평가   2027.05.12              [수정]
  └─ 면접       2027.12.02              [수정]

일정 추가/수정
  ├─ 이름
  ├─ 날짜
  ├─ 종류(선택)
  ├─ [대표 일정으로 설정]
  └─ [저장] [삭제]
```

Calendar is not implemented here. It should read the same event collection and
apply a calendar projection; it must not introduce a parallel date/event model.

### Persistence recommendation

- Authenticated users: account-owned collection with RLS and cross-device sync.
- Guest users: local/session collection only, with no forced login for basic use.
- Guest → login: MVP may show an explicit one-time choice such as “기존에 만든
  일정 N개를 계정에 저장할까요?” and then migrate only with confirmation; do not
  silently merge, overwrite or duplicate records.
- Logout/account switch: clear the active account view and never expose another
  account's events. Deletion/retention must follow existing personal-data policy.

The existing `profiles.target_date/target_label` should not be expanded into
multiple columns. A future migration should introduce one event collection and
define a one-time compatibility path for the current single target; no migration
is created in this audit.

## Role-based Home customization

### Role contract

MVP recommends one editable **primary presentation role**, optional and skippable:

`student`, `repeat_student`, `parent`, `teacher`, `academy_instructor`, `other`.

The role selects an initial Home preset only. It is not an auth role, Supabase
RLS claim, organization membership, teacher permission, or access gate. Multiple
roles may be considered later through a separate profile-preference relation;
MVP should not add an array or permission table solely for Home presets.

Progressive profiling should ask after the user can understand the value, for
example “어떤 목적으로 LegendStudy를 사용하시나요?”, with Skip and later change
available. This follows the longitudinal strategy's rule that inputs must connect
to immediate value and must not be forced or presented as guaranteed insight.

### Recommended presets

Presets are initial defaults. Explicit user visibility choices always override a
preset, including after the user changes role.

| Role | Initial emphasis |
|---|---|
| 학생 | D-Day, 공부시간, 급식 when configured, 자료 |
| N수생 | D-Day, 공부시간, 모의고사/자료; no role-forced meal hiding |
| 학부모 | 자료, 입시정보, optional D-Day |
| 교사 | 자료, 입시정보, optional D-Day |
| 학원 강사 | 자료, 모의고사, 입시정보 |

These are presentation suggestions only. No current role or preset is implemented.

### Visibility and ordering

MVP should support module ON/OFF in a separate Settings entry such as
`홈 화면 설정`. Role selection/preset explanation should be separate from the
module toggle list so the user understands the difference between “추천 초기값”
and “내가 지금 보이는 항목”.

Drag reorder is deferred. Store a future-compatible ordered module-key list if
needed, but initially use deterministic product order and persist only explicit
visibility overrides. The five bottom tabs and core Materials search remain
fixed for navigation/accessibility.

Conditional modules must be data-aware rather than role-forced:

- Meals: school configured → show data; not configured → setup prompt or hidden
  according to user choice; no role automatically removes it.
- Study: show summary/empty state according to available study data and choice.
- Recent materials: account-scoped for signed-in users; honest empty/limited state
  for Guests.
- Scores, Insights, Achievement and Notifications: future modules, not current
  implementation or preset promises.

Home composition should check enabled modules before watching their providers.
This is especially important for meal/network providers and future Analytics;
hidden modules must not continue background queries merely because their widgets
are invisible.

## Privacy, analytics and future integrations

Event titles are free text and may contain personal or sensitive information.
Raw titles and personal event content must not be default Analytics/Cohort
dimensions or operator browsing surfaces. Prefer aggregate `role`, `event_type`,
date distance, feature usage and visibility/use patterns only after a
separate privacy and consent review. Preserve deletion and export semantics.

Future Notifications may reference an event and schedule D-7/D-1/today reminders,
but Notification Center remains planned. Achievement must not be triggered merely
because a user created a D-Day. Admissions integration may link an event to a
reviewed application/essay/interview/result record later; D-Day MVP must remain
useful without that engine.

## MVP boundary and implementation order

### Multi D-Day MVP — IMPLEMENTED / Production applied (2026-09-26)

Implemented exactly as scoped below; migration `20260926000100_day_targets.sql`
applied to Production (RLS, single-primary index, legacy backfill). Owner device
acceptance PASS (final Wave1 handoff). Calendar/notifications/admissions linking remain deferred.

1. Event collection with account (RLS) / Guest-session persistence boundary. ✓
2. Create/edit/delete + a single user-chosen representative (radio). ✓
3. Home single-target card replaced by the representative card + compact list
   (collapsed 2, "일정 N개 더보기"/접기), date `YYYY.MM.DD.(요일)`. ✓
4. Existing KST date calculation and explicit past-event policy preserved. ✓
5. Existing single profile target backfilled as a primary event; profile columns
   kept. ✓

### Home customization MVP

1. Add optional primary role/preset preference, separate from permissions.
2. Add Home module visibility preferences and Settings entry.
3. Compose Home conditionally before provider watches.
4. Keep fixed navigation/search and accessible empty/setup states.
5. Defer reorder, Calendar, notifications, imported/admissions events and
   analytics collection.

## Audit gaps / implementation risks

- A DB migration and RLS design are required for durable multi-event sync, but are
  intentionally not specified as executable SQL here.
- Guest-local persistence needs a deliberate storage choice and explicit login
  migration UX; current D-Day is session-memory only.
- Current profile schema has no role or module preferences; do not overload
  `grade_level` or add permission semantics to profiles.
- Future Home provider composition must avoid hidden network work.
- Admissions event linking, notifications and analytics require separate privacy,
  provenance and deletion review.


## Personalization package after Wave1 — Owner direction 2026-09-27

Next major product track after Wave1: first-login information onboarding with
Skip, user type, school/grade/profile, Home presets and module ON/OFF. Planning
only; implement no onboarding/profile/schema changes during Materials Wave1.
This refines the existing role/visibility plan and
[progressive profiling strategy](longitudinal-learning-admissions-data-strategy.md#progressive-profiling-and-onboarding).

One canonical data model serves Onboarding (initial acquisition), LAB (contextual
value/acquisition) and MY (view/edit/manage). Ask when the user has a reason to
enter data, can provide accurate values and receives immediate value; no screen
owns a competing profile DB. Interested universities/departments, actual
applications/university/department/admission track, and results have distinct
semantics.

School is also a potential explanatory feature for future Admissions analysis,
not merely meals/convenience data. Owner reports prior Selty service used school
as an analysis input. Preserve remaining Selty data as a future legacy
research/import asset for audit. Distinguish official university assessment
criteria from empirically/statistically estimated school effects; never present
an unvalidated school effect as an official university weighting. Existing
Admissions evidence/privacy/model gates still apply.
