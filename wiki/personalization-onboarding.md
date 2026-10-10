# Personalization Foundation & First-Login Onboarding

Status: **COMPLETE — Production migration APPLIED, Owner validation PASS.**
Date: 2026-09-27. Scope: Phase 1 only. Canonical design/implementation doc.

## Production migration (applied)

`supabase/migrations/20260927000100_profile_personalization.sql` — **applied to
Production by Owner (2026-09-27).**

`PERSONALIZATION_DB_MIGRATION: PASS`. Owner validation:

- `should_be_zero = 0` — no already-personalized user left unmarked by the
  guarded backfill.
- `invalid_status_zero = 0` — no row holds an out-of-domain `academic_status`.

The migration file below is the exact SQL applied; the file and Production schema
match (the validation queries reference both new columns and returned 0/0).

## Goal

Give every signed-in user one **canonical user profile** and a short, skippable
first-login flow to seed it, so Home / MY / LAB / Admissions all reuse the same
data instead of each inventing its own. No admissions engine, no
interested/application universities, no school-weighting or prediction model, no
rule engine, no fake persistence.

## Canonical model

`public.profiles` remains the single source of truth. Phase 1 adds two nullable
columns:

- `academic_status text check in ('student','retaker','other')` — the admissions
  lifecycle bucket. `student` uses `grade_level` 1/2/3; `retaker` (N수·검정고시
  등) and `other` carry no grade.
- `onboarding_completed_at timestamptz` — set **once**, on finish OR skip, so the
  first-login flow never re-prompts. Skip counts as complete.

School identity stays NEIS (`neis_office_code`, `neis_school_code`) — reused
as-is, the future admissions join key. No new school table, no weighting.

## First-login routing

- Route `/onboarding` (`OnboardingPage`).
- A GoRouter top-level `redirect` uses the pure `onboardingRedirect(...)` gate:
  authenticated + (no profile row OR `onboarding_completed_at == null`) →
  `/onboarding`. Guests are never redirected; `/auth/*` and `/onboarding` are
  never intercepted; while the profile is loading or errored the gate waits.
- The router refreshes **only** on `currentProfileProvider` (which itself watches
  auth). Listening to auth directly caused a race where the redirect read the
  previous user's stale profile and wrongly sent an onboarded returning user to
  onboarding; refreshing on the profile alone keeps the gate's read consistent
  with the current user. See `lib/app/router.dart` (`_RouterRefresh`).
- New users have **no** `profiles` row until first write (no signup trigger
  exists), so a null profile for an authenticated user legitimately means
  "not yet onboarded".

## Onboarding UX

Two short steps, value-first, skippable at any point (`OnboardingPage`):

1. **Status** — student / retaker / other, each with a one-line benefit.
2. **Details** — students get optional grade chips + reused NEIS school search
   (`schoolSearchProvider` / `schoolSelectionProvider`, which persist to the same
   canonical fields); retaker/other get a short confirmation. No university
   input in Phase 1 (that DB is not ready — no fake UI).

Finish persists status (+grade) and stamps completion; skip only stamps
completion. Both then invalidate the profile/selection providers and go `/home`.

## Multi-UI-entry / single canonical source

The same `profiles` fields are written from onboarding **and** MY. MY's
`학교·학년 설정` page now hosts `AcademicStatusField`, a second entry point that
reads/writes `academic_status` through the same `ProfileRepository`. Grade and
school editing there are unchanged.

## Files

- `supabase/migrations/20260927000100_profile_personalization.sql` — 2 columns,
  grants, guarded idempotent backfill. **Applied to Production; validation PASS.**
- `lib/features/personal/domain/personal_models.dart` — `academicStatus`,
  `onboardingCompletedAt`, `hasCompletedOnboarding`, decode.
- `lib/features/personal/domain/personal_repositories.dart` — extended
  `upsertCurrentProfile` (+ `academicStatus`/`clearAcademicStatus`),
  `markOnboardingComplete()`.
- `lib/features/personal/data/supabase_personal_repositories.dart` — projection +
  upsert + `markOnboardingComplete`, `academic_status` validation.
- `lib/features/onboarding/onboarding_gate.dart` — pure redirect decision +
  `onboardingRoute`.
- `lib/features/onboarding/presentation/onboarding_page.dart` — the flow.
- `lib/features/profile/presentation/academic_status_field.dart` — MY editor.
- `lib/app/router.dart` — `/onboarding` route, redirect, profile-only refresh.

## Backfill (guarded, idempotent)

```
update public.profiles set onboarding_completed_at = now()
  where onboarding_completed_at is null
    and (grade_level is not null or neis_school_code is not null);
```

Existing users who already carry a grade or school are treated as onboarded so
they are never re-prompted. Users with no such signal keep a null marker and see
the flow on next launch.

## Validation

- `flutter analyze lib test`: PASS (no issues).
- New `test/personalization_onboarding_test.dart`: gate branches, model decode,
  repository transport (academic_status upsert/clear, invalid rejected,
  `markOnboardingComplete`, finish-path preserve + fetch decode).
- Full Flutter suite: 835 pass, 1 skipped, **3 pre-existing failures unrelated to
  this task** (verified on a clean tree): `day5_shell_test` content-badge label
  and `materials_delivery_journey_test` ×2 guest-state — all Materials/ContentCard
  rendering, no profile/gate/auth involvement.
- Affected existing tests were updated to represent onboarded returning users via
  the shared `test/support/onboarding_override.dart` helper (auth-scoped, guests
  stay null); fakes implementing `ProfileRepository` gained the new members.

## Cross-verification (2026-09-27 closeout)

- `profiles.academic_status`, `profiles.onboarding_completed_at`: applied,
  validation PASS.
- First-login gate, skip == complete, returning-user not re-prompted (race fixed
  by profile-only router refresh), guests never redirected: covered by
  `test/personalization_onboarding_test.dart` gate branches + full-suite app
  tests.
- student → grade + NEIS school; retaker/other minimal flow; MY academic-status
  edit; onboarding and MY writing the same `profiles` fields via one
  `ProfileRepository`: implemented and analyzer/test clean.
- Account/profile regression: none introduced. Existing app tests that sign in a
  user were adjusted to represent onboarded returning users
  (`test/support/onboarding_override.dart`).

## Phase 1.1 — Onboarding Visual UX (2026-09-27)

Owner device review found the flow functional but visually flat ("설정 화면처럼
보인다"). Phase 1.1 is a **visual-only** pass on `onboarding_page.dart` — no
change to logic, gate, router, DB, providers, or NEIS search.

- **Typography / hierarchy**: main question raised to 26/w800 in a near-black
  navy (`_ink` 0xFF0D1730) for high emphasis; description stays secondary; a
  2-segment progress bar (fresh blue) plus `1 / 2` caption replaces the bare
  step text.
- **Selection cards** (`_StatusTile`): elevated white surface, 1.5px border,
  `radiusLg`, soft shadow, a tinted leading-icon chip per option (blue/orange/
  mint — decorative, not body text), a ring→filled-check selection dot, and ink
  press feedback. Selected = orange accent border + soft tint + stronger shadow.
- **Onboarding palette**: keeps navy/orange identity but adds a fresher, livelier
  feel — a subtle top gradient backdrop, fresh blue for progress, a warm orange
  accent for selection/CTA. Accents mark selection/progress only.
- **Grade chips** (`_SelectChip`): custom pill with a strong selected state
  (accent fill + white bold), clearer than the default ChoiceChip.
- **School search**: labelled field; the selected school rises into an elevated
  accent confirmation card (`_SelectedSchoolCard`) — the seed of the Phase 1.2
  foreground metaphor.
- **CTA**: full-width 52px accent primary button (다음/완료) with skip/이전 as
  quiet secondary actions.
- **Accessibility**: transitions collapse to `Duration.zero` under Reduce Motion;
  the decorative backdrop is `ExcludeSemantics`; touch targets ≥ 44–52px.
- **Phase 1.2 readiness**: the body is a `Stack` whose first child is a reusable
  `_OnboardingBackdrop` slot, so the moving identity field drops in without
  restructuring the foreground.

Verified: `flutter analyze` clean; new `test/onboarding_page_test.dart`
(guest / student→grade→finish / retaker clear-grade / skip / small-phone
no-overflow); full suite 848 pass, 1 skipped, 3 pre-existing failures unrelated
to this task; **0 new regressions**.

## Phase 1.1 hotfix — School search action separation (Owner device QA)

Owner device QA: on the school step the field had no explicit search control, so
users typed a school name and then pressed the strongest CTA, 완료, expecting it
to search — which instead finished onboarding and jumped to Home. Fix (visual /
UX only, no logic/gate/router/DB/NEIS change):

- Added an explicit on-screen **검색** button (`_SchoolSearchButton`) under the
  field: disabled while the query is empty, shows a spinner while a search is in
  flight, and prevents duplicate submission.
- One shared search action (`_runSearch`) is called by BOTH the button and the
  keyboard search key (`onSubmitted`) — no second search path; still reuses
  `schoolSearchProvider` / `schoolSelectionProvider`.
- Renamed the final step CTA 완료 → **설정 완료** to separate it from searching.
  Searching only sets the query; it never finishes onboarding or navigates.
- Selected-school confirmation card, skip semantics, finish persistence, and the
  optional-school policy are unchanged.
- Search/select UI and the onboarding finish action stay decoupled, so a future
  canonical step (관심 대학 등) can replace this step's CTA with 다음 without
  re-coupling. No DB/schema change; no university/major UI.

Covered by `test/onboarding_page_test.dart` (검색 button enable/disable, shared
action for button + keyboard, selection confirmation, and that 검색 never
finishes onboarding), plus the finish/skip/returning-user tests.

## Phase 1.2 — Motion personalization (design only)

The "living personalization" motion concept (ambient background identity field,
selection-rises-to-foreground metaphor, school then interested-university
screens, visual-pool ≠ supported-university universe, ~30–50 representative
visuals, multi-selection layout, reusable motion architecture, performance and
Reduce-Motion rules, logo asset strategy) is specified in
[personalization-motion-ux.md](personalization-motion-ux.md). It is **not
implemented**; Owner opens that gate after Phase 1.1 device review.

## Constraints honored

Materials Wave1 code/DB/ingestion untouched; the 3 locally-modified wiki files
(Codex Materials Wave1) untouched; no `git add .`; Owner modified/untracked files
preserved; no Home redesign; no rule engine; no school weighting; no cohort
reconstruction; no fake persistence. **Production migration prepared but NOT
applied — Owner applies via SQL Editor.**

## Next (not in Phase 1)

Interested/application universities and any admissions computation require their
own DB and are explicitly out of scope. When ready, onboarding step 3 can host
that input against a real table.

## Device-once introduction — Owner superseding decision 2026-10-10

App introduction is install-local and independent of login. Both Skip and Start
persist completion then open the existing login choice. Guest entry goes Home
without anonymous Auth creation. Android info channel uses SharedPreferences;
iOS uses an atomic Application Support marker. Existing study-state footprint or
restored Auth session identifies an earlier install; local read failure never
means new installation. Completion is not cleared on logout/provider switch.
Profile onboarding starts directly at personalization for confirmed missing
profiles. Existing shared profiles are reused; loading/error is not absence.
[Validation and pending device gates](essay-runtime-activation-2026-10-09.md#google-auth--essay-production-user-flow--2026-10-10).
