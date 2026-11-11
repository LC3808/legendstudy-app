-- Restore only after root cause is resolved and Owner authorizes reopening.
begin;
grant execute on function public.my_home_configuration() to authenticated;
grant execute on function public.save_my_home_configuration(jsonb,bigint) to authenticated;
commit;
