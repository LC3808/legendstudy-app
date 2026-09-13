begin;
revoke insert (target_date, target_label), update (target_date, target_label)
  on public.profiles from authenticated;
alter table public.profiles
  drop constraint profiles_target_pair,
  drop column target_date,
  drop column target_label;
notify pgrst, 'reload schema';
commit;
