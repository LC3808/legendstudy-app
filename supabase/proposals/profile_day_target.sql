-- PROPOSAL ONLY: requires Product Owner approval; NOT applied.
begin;

alter table public.profiles
  add column target_date date,
  add column target_label text,
  add constraint profiles_target_pair check (
    (target_date is null) = (target_label is null)
    and (target_date is null or isfinite(target_date))
    and (
      target_label is null or (
        target_label = btrim(target_label, E' \t\n\r\f\013')
        and char_length(target_label) between 1 and 80
      )
    )
  );

grant insert (target_date, target_label),
      update (target_date, target_label)
  on public.profiles to authenticated;

notify pgrst, 'reload schema';
commit;
