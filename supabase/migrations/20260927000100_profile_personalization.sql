-- Personalization Foundation Phase 1.
-- Two canonical profile fields shared by Home / MY / LAB / Admissions:
--   academic_status  — the user's current admissions lifecycle bucket.
--   onboarding_completed_at — set once, on finish OR skip, so first-login
--                             personalization never re-prompts.
-- No admissions engine, no interested/application universities, no school
-- weighting model. Existing rows stay valid; both columns are nullable.
begin;

alter table public.profiles
  add column academic_status text
    constraint profiles_academic_status_check
      check (academic_status in ('student', 'retaker', 'other')),
  add column onboarding_completed_at timestamptz;

-- Only the two new columns are granted; grade/name/school grants are unchanged.
grant insert (academic_status, onboarding_completed_at),
      update (academic_status, onboarding_completed_at)
  on public.profiles to authenticated;

-- Guarded, idempotent backfill: an existing user who already carries a grade or
-- a school has effectively been personalized, so mark them onboarded and never
-- re-prompt them. Users with no such signal keep a null marker and will see the
-- first-login flow. Re-running this statement changes nothing.
update public.profiles
  set onboarding_completed_at = now()
  where onboarding_completed_at is null
    and (grade_level is not null or neis_school_code is not null);

notify pgrst, 'reload schema';
commit;
