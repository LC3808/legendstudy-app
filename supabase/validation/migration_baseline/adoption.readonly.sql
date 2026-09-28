-- Narrow aggregate-only current invariants; no replay or mutation.
begin read only;
set local search_path = pg_catalog, public;
select jsonb_build_object(
 '20260917000200',jsonb_build_object(
  'pending_missing_schedule',(select count(*) from public.feedback_notifications where status='pending' and next_attempt_at is null),
  'invalid_claim_state',(select count(*) from public.feedback_notifications where (status='processing') is distinct from (claimed_at is not null and claim_token is not null) or (status<>'processing' and (claimed_at is not null or claim_token is not null))),
  'terminal_null_schedule',(select count(*) from public.feedback_notifications where status in ('sent','failed') and next_attempt_at is null),
  'backfill_replay_matched_rows',(select count(*) from public.feedback_notifications where next_attempt_at is null)),
 '20260926000100',jsonb_build_object(
  'eligible_legacy_without_target',(select count(*) from public.profiles p where p.target_date is not null and p.target_label is not null and not exists(select 1 from public.day_targets d where d.owner_id=p.id)),
  'duplicate_primary_owners',(select count(*) from (select owner_id from public.day_targets where is_primary group by owner_id having count(*)>1) x)),
 '20260927000100',jsonb_build_object(
  'eligible_missing_onboarding_marker',(select count(*) from public.profiles where onboarding_completed_at is null and (grade_level is not null or neis_school_code is not null)))
) as invariants;
rollback;
