-- Disable worker in GitHub before executing. Preserve runs/changes/Registry.
begin;
update ingestion_ops.config set enabled=false where singleton;
revoke execute on function public.admin_material_sync_request(),public.admin_material_sync_status() from authenticated;
revoke execute on function ingestion_ops.admin_request(),ingestion_ops.admin_status() from authenticated;
commit;
-- Revert WEB and runtime deployment only after confirming no worker is active.
-- Retain added columns and audit records; do not delete newly published materials.
