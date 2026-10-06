-- APP-FIRST-RUN-PERSONALIZATION-1
-- Desired major / interest field. Personalization data, not an application record.
alter table public.profiles
  add column if not exists intended_major text;
