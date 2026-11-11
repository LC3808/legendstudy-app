-- Emergency stop; preserve run evidence and content. Owner executes.
begin;
update ingestion_ops.config set enabled=false where singleton;
alter role legendstudy_material_sync nologin;
commit;
-- Disable GitHub workflow too. Wait for/stop current job before data rollback.
