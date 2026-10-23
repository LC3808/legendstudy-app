-- OWNER ONLY: removes this new PDF read policy, preserves all records and other policies.
-- Also remove SKKU from Gateway/Worker public lists and revert the one manifest entry for full rollout rollback.
begin;
drop policy if exists skku_2026_language1_problem_read on storage.objects;
commit;
