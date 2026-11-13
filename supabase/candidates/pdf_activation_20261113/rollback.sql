-- Close only this activation; preserve every permission revision and user record.
begin;
set local lock_timeout='3s';
set local statement_timeout='30s';
lock table material_download_private.permissions in share row exclusive mode;
insert into material_download_private.permissions(resource_id,source_resource_key,state,owner_decision)
select p.resource_id,p.source_resource_key,'VIEW_ONLY','rollback_owner_download_activation_20261113'
from material_download_private.permissions p
where p.owner_decision='owner_download_activation_20261113' and p.state='ALLOWED'
and p.revision=(select max(x.revision) from material_download_private.permissions x where x.resource_id=p.resource_id);
commit;
