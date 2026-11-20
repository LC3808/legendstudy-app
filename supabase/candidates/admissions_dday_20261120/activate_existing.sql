-- Separate Owner-approved activation step AFTER install + seed + checks.
-- Creates derived D-Days only. Never changes application headers/events/manual targets.
begin;
select pg_advisory_xact_lock(6192743107261120);
do $$declare u uuid;begin
 for u in select distinct user_id from public.student_applications where admission_type='수시' order by user_id loop
  perform admissions_private.sync_owner(u);
 end loop;
end$$;
commit;
