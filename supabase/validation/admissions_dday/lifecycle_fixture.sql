-- The actual Production lifecycle gates, limited to this suite's day_targets.
create policy account_lifecycle_restriction on public.day_targets
 as restrictive for all to authenticated
 using(public.account_service_allowed()) with check(public.account_service_allowed());
create trigger account_lifecycle_statement before insert or update on public.day_targets
 for each statement execute function account_private.caller_write_gate();
create trigger account_lifecycle_write before insert or update on public.day_targets
 for each row execute function account_private.personal_write_gate();
