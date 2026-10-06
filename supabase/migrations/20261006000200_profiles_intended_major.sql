-- APP-FIRST-RUN-PERSONALIZATION-1 — desired major / interest field.
alter table public.profiles
  add column if not exists intended_major text;
