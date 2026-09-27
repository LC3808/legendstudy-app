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
